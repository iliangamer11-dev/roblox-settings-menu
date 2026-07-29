--!nonstrict
--[[
	BalloonManager
	----------------------------------------------------------------------------
	Nucleo del sistema de globos. Modular y sin dependencias del resto de
	servicios: recibe sus contenedores por parametro, asi que se puede
	instanciar en un test o en un mapa distinto sin arrastrar el juego entero.

	Responsabilidades:
		* Mantener vivo un numero controlado de globos, repartidos por zona.
		* Elegir tipo de globo por peso de rareza y posicion aleatoria.
		* Llevar el registro de globos activos con acceso O(1) por id y por
		  instancia.
		* Retirar los globos con vida limitada.
		* Exponer la API que consumira el sistema de pinchado.

	DECISIONES DE RENDIMIENTO (importan con muchos jugadores)

	1. Un unico hilo planificador para todo el servidor. No hay un bucle por
	   globo ni por zona ni por jugador, asi que el coste no crece con la
	   cantidad de jugadores conectados: solo con el tope de globos.

	2. Los globos son compartidos, no por jugador. 30 jugadores ven los mismos
	   150 globos, no 4.500 instancias.

	3. Pooling de instancias en BalloonFactory: se reutilizan en lugar de
	   crear y destruir.

	4. Cero replicacion manual en la aparicion. Roblox ya replica la instancia
	   y sus atributos; enviar ademas un RemoteEvent por globo a cada cliente
	   seria trafico duplicado. El remote BalloonSpawned queda reservado para
	   efectos especiales puntuales.

	5. Presupuesto por ciclo (`SpawnsPerTick`): el trabajo se reparte en el
	   tiempo en lugar de crear 150 globos en un frame.

	6. Partes ancladas, sin colision y sin sombra. Ninguna simulacion fisica.
	   El balanceo visual lo hace el cliente.

	API PUBLICA
		manager:Start() / manager:Stop()
		manager:SpawnOne(zoneId?)            -> entry?
		manager:Despawn(balloonId, reason?)  -> boolean
		manager:Get(balloonId)               -> entry?
		manager:GetFromInstance(instance)    -> entry?
		manager:ApplyDamage(balloonId, amount, player?) -> (destruido, entry?)
		manager:GetStats()
		manager.BalloonSpawned / BalloonDespawned / BalloonDamaged / BalloonDestroyed
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)
local Signal = require(Shared.Util.Signal)
local WeightedRandom = require(Shared.Util.WeightedRandom)

local BalloonFactory = require(script.Parent.BalloonFactory)
local SpawnPointRegistry = require(script.Parent.SpawnPointRegistry)

local log = Logger.new("BalloonManager")

local SPAWNING = Config.Balloons.Spawning
local BALLOON_TAG = Config.Game.Tags.Balloon

local BalloonManager = {}
BalloonManager.__index = BalloonManager

--------------------------------------------------------------------------------
-- Construccion
--------------------------------------------------------------------------------

--[[
	options = {
		Container      Folder donde viven los globos activos (Workspace)
		Reserve        Folder donde duermen los reciclados (fuera de Workspace)
		Assets         ServerStorage.Assets.Balloons (opcional)
		SpawnersFolder Workspace.World.Spawners (opcional)
	}
--]]
function BalloonManager.new(options)
	assert(options and options.Container, "BalloonManager necesita un Container")
	assert(options.Reserve, "BalloonManager necesita un Reserve")

	local self = setmetatable({
		_container = options.Container,
		_spawnersFolder = options.SpawnersFolder,
		_factory = BalloonFactory.new(options.Assets, options.Reserve),
		_spawnPoints = SpawnPointRegistry.new(options.SpawnersFolder),

		-- balloonId -> entry
		_active = {},
		-- instancia -> entry (para resolver un hit del cliente en O(1))
		_byInstance = {},
		-- zoneId -> numero de globos vivos
		_countByZone = {},

		_activeCount = 0,
		_nextId = 0,
		_running = false,
		_filling = SPAWNING.InitialBurst,
		_random = Random.new(),

		-- zoneId -> WeightedRandom de definiciones
		_pickerByZone = {},
		-- Reparto justo entre zonas
		_zoneCursor = 0,
		_zoneOrder = {},

		BalloonSpawned = Signal.new(), -- (entry)
		BalloonDespawned = Signal.new(), -- (entry, reason)
		BalloonDamaged = Signal.new(), -- (entry, amount, player?)
		BalloonDestroyed = Signal.new(), -- (entry, player?)
	}, BalloonManager)

	self:_buildZoneOrder()

	return self
end

--------------------------------------------------------------------------------
-- Catalogo por zona
--------------------------------------------------------------------------------

function BalloonManager:_buildZoneOrder()
	local order = {}
	for zoneId, zone in pairs(Config.Zones.Zones) do
		if zone.BalloonIds and #zone.BalloonIds > 0 then
			table.insert(order, zoneId)
		end
	end
	table.sort(order, function(a, b)
		return Config.Zones.Zones[a].Order < Config.Zones.Zones[b].Order
	end)
	self._zoneOrder = order
end

--[[
	Selector de tipo de globo para una zona. Se construye una vez y se cachea:
	la configuracion esta congelada, asi que no puede quedar obsoleto.
--]]
function BalloonManager:_pickerFor(zoneId: string)
	local cached = self._pickerByZone[zoneId]
	if cached then
		return cached
	end

	local zone = Config.Zones.Zones[zoneId]
	local entries = {}

	if zone and zone.BalloonIds then
		for _, balloonId in ipairs(zone.BalloonIds) do
			local definition = Config.Balloons.Balloons[balloonId]
			if definition then
				table.insert(entries, { Value = definition, Weight = definition.Weight })
			else
				log:Warn("La zona '%s' referencia el globo inexistente '%s'", zoneId, balloonId)
			end
		end
	end

	local picker = WeightedRandom.new(entries)
	self._pickerByZone[zoneId] = picker

	return picker
end

--------------------------------------------------------------------------------
-- Arranque
--------------------------------------------------------------------------------

function BalloonManager:Start()
	if self._running then
		return
	end

	self._spawnPoints:Scan()
	self._spawnPoints:EnsureDefault(
		self._spawnersFolder or self._container,
		self:_defaultSpawnCenter(),
		Vector3.new(160, 1, 160)
	)

	if self._spawnPoints:GetCount() == 0 then
		log:Error("No hay puntos de aparicion: el sistema no arrancara")
		return
	end

	if SPAWNING.PrewarmPerType > 0 then
		self:_prewarm()
	end

	self._running = true

	task.spawn(function()
		self:_scheduler()
	end)

	log:Info(
		"Sistema de globos activo | tope %d | %d puntos | %d tipos",
		SPAWNING.MaxActive,
		self._spawnPoints:GetCount(),
		self:_typeCount()
	)

	task.spawn(function()
		self:_selfCheck()
	end)
end

--[[
	Comprobacion automatica: si a los pocos segundos no hay ni un globo, se
	imprime el estado completo del sistema en lugar de fallar en silencio.
	Un sistema de aparicion que no aparece nada y no dice nada es lo peor que
	puede pasarle a quien lo tiene que depurar.
--]]
function BalloonManager:_selfCheck()
	task.wait(3)

	if self._activeCount > 0 then
		local sample
		for _, entry in pairs(self._active) do
			sample = entry
			break
		end

		log:Info(
			"Comprobacion OK: %d globos activos. Ejemplo: '%s' (%s) en %s",
			self._activeCount,
			sample.Id,
			sample.DefinitionId,
			tostring(sample.Position)
		)
		return
	end

	log:Error("NINGUN globo ha aparecido tras 3 s. Estado del sistema:")
	log:Warn("  Spawning.Enabled = %s", tostring(SPAWNING.Enabled))
	log:Warn("  planificador corriendo = %s", tostring(self._running))
	log:Warn("  tipos en el catalogo = %d", self:_typeCount())
	log:Warn("  contenedor = %s", self._container:GetFullName())

	local points = self._spawnPoints:Describe()
	log:Warn("  puntos de aparicion = %d", #points)
	for _, point in ipairs(points) do
		log:Warn(
			"    '%s' zona=%s peso=%.1f activos=%d/%d tamano=%s",
			point.Name,
			point.ZoneId,
			point.Weight,
			point.Active,
			point.MaxActive,
			point.Size
		)
	end

	for _, zoneId in ipairs(self._zoneOrder) do
		local picker = self:_pickerFor(zoneId)
		log:Warn("  zona '%s': %d tipos de globo elegibles", zoneId, picker:Count())
	end

	if #points == 0 then
		log:Warn("  CAUSA PROBABLE: no hay ninguna Part en Workspace.World.Spawners")
	elseif #self._zoneOrder == 0 then
		log:Warn("  CAUSA PROBABLE: ninguna zona de ZoneConfig tiene BalloonIds")
	end
end

function BalloonManager:Stop()
	self._running = false
end

--[[
	Centro del area de aparicion por defecto.

	Se usa el SpawnLocation del mapa en lugar del origen del mundo: si el mapa
	no esta construido en (0,0,0), poner los globos en el origen los deja lejos
	del jugador o enterrados. Con esto aparecen donde el jugador entra, que es
	lo que se espera al probar el sistema sin haber colocado puntos.
--]]
function BalloonManager:_defaultSpawnCenter(): Vector3
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)

	if spawnLocation then
		log:Debug("Area por defecto centrada en el SpawnLocation '%s'", spawnLocation:GetFullName())
		return spawnLocation.Position
	end

	log:Debug("Sin SpawnLocation en el mapa: area por defecto en el origen")
	return Vector3.new(0, 0, 0)
end

function BalloonManager:_typeCount(): number
	local count = 0
	for _ in pairs(Config.Balloons.Balloons) do
		count += 1
	end
	return count
end

function BalloonManager:_prewarm()
	local startedAt = os.clock()
	local total = 0

	for _, definition in pairs(Config.Balloons.Balloons) do
		self._factory:Prewarm(definition, SPAWNING.PrewarmPerType)
		total += SPAWNING.PrewarmPerType
	end

	log:Debug("Reserva precalentada con %d instancias en %.3f s", total, os.clock() - startedAt)
end

--------------------------------------------------------------------------------
-- Planificador
--------------------------------------------------------------------------------

--[[
	Un solo hilo para todo. Mientras se esta llenando el mapa usa un lote mas
	grande (`BurstPerTick`) y luego baja al ritmo normal de mantenimiento.
--]]
function BalloonManager:_scheduler()
	while self._running do
		local ok, err = pcall(function()
			self:_tick()
		end)

		if not ok then
			log:Error("Fallo en el ciclo de aparicion: %s", tostring(err))
		end

		task.wait(SPAWNING.Interval)
	end
end

function BalloonManager:_tick()
	self:_despawnExpired()

	local budget = if self._filling then SPAWNING.BurstPerTick else SPAWNING.SpawnsPerTick

	for _ = 1, budget do
		if self._activeCount >= SPAWNING.MaxActive then
			if self._filling then
				self._filling = false
				log:Debug("Mapa lleno: %d globos activos", self._activeCount)
			end
			return
		end

		if not self:SpawnOne() then
			-- Sin hueco disponible en este ciclo; se reintenta en el siguiente
			return
		end
	end
end

--[[
	Retira los globos cuya vida limitada ha terminado.
	Solo recorre la lista activa cuando hay algun tipo con Lifetime > 0.
--]]
function BalloonManager:_despawnExpired()
	local now = os.clock()
	local expired: { string }? = nil

	for balloonId, entry in pairs(self._active) do
		if entry.ExpiresAt and entry.ExpiresAt <= now then
			expired = expired or {}
			table.insert(expired, balloonId)
		end
	end

	if expired then
		for _, balloonId in ipairs(expired) do
			self:Despawn(balloonId, "expired")
		end
	end
end

--------------------------------------------------------------------------------
-- Aparicion
--------------------------------------------------------------------------------

function BalloonManager:_isZoneAllowed(zoneId: string): boolean
	return (self._countByZone[zoneId] or 0) < SPAWNING.MaxActivePerZone
end

function BalloonManager:_nextBalloonId(): string
	self._nextId += 1
	return string.format("B%d", self._nextId)
end

--[[
	Crea un globo. Si se indica `preferredZone` solo se consideran puntos de
	esa zona. Devuelve la entrada creada o nil si no habia hueco.
--]]
function BalloonManager:SpawnOne(preferredZone: string?)
	if self._activeCount >= SPAWNING.MaxActive then
		return nil
	end

	local descriptor = self._spawnPoints:PickAvailable(function(zoneId)
		if preferredZone and zoneId ~= preferredZone then
			return false
		end
		return self:_isZoneAllowed(zoneId)
	end, SPAWNING.PlacementAttempts)

	if not descriptor then
		return nil
	end

	-- Tipo de globo: el punto puede forzar uno concreto
	local definition
	if descriptor.ForcedBalloonId then
		definition = Config.Balloons.Balloons[descriptor.ForcedBalloonId]
		if not definition then
			log:Warn("'%s' fuerza el globo inexistente '%s'", descriptor.Part.Name, descriptor.ForcedBalloonId)
		end
	end
	if not definition then
		definition = self:_pickerFor(descriptor.ZoneId):Pick()
	end
	if not definition then
		return nil
	end

	local position = self._spawnPoints:PickPosition(descriptor, self._random)
	if not position then
		-- Punto saturado: hay globos demasiado cerca
		return nil
	end

	local instance = self._factory:Acquire(definition)
	if not instance then
		log:Warn("No se pudo crear la instancia del globo '%s'", definition.Id)
		return nil
	end

	local balloonId = self:_nextBalloonId()

	BalloonFactory.ApplyAttributes(instance, balloonId, definition, descriptor.ZoneId)
	BalloonFactory.SetPosition(instance, position)
	instance.Parent = self._container
	CollectionService:AddTag(instance, BALLOON_TAG)

	local entry = {
		Id = balloonId,
		DefinitionId = definition.Id,
		Definition = definition,
		ZoneId = descriptor.ZoneId,
		SpawnPoint = descriptor,
		Instance = instance,
		Position = position,
		Health = definition.Health,
		MaxHealth = definition.Health,
		SpawnedAt = os.clock(),
		ExpiresAt = if definition.Lifetime > 0 then os.clock() + definition.Lifetime else nil,
	}

	self._active[balloonId] = entry
	self._byInstance[instance] = entry
	self._activeCount += 1
	self._countByZone[descriptor.ZoneId] = (self._countByZone[descriptor.ZoneId] or 0) + 1
	self._spawnPoints:Occupy(descriptor, balloonId, position)

	self.BalloonSpawned:Fire(entry)

	return entry
end

--------------------------------------------------------------------------------
-- Retirada
--------------------------------------------------------------------------------

--[[
	Retira un globo y devuelve su instancia a la reserva.
	`reason`: "expired" | "popped" | "cleanup" | ...
--]]
function BalloonManager:Despawn(balloonId: string, reason: string?): boolean
	local entry = self._active[balloonId]
	if not entry then
		return false
	end

	self._active[balloonId] = nil
	self._byInstance[entry.Instance] = nil
	self._activeCount = math.max(self._activeCount - 1, 0)
	self._countByZone[entry.ZoneId] = math.max((self._countByZone[entry.ZoneId] or 1) - 1, 0)
	self._spawnPoints:Free(entry.SpawnPoint, balloonId)

	CollectionService:RemoveTag(entry.Instance, BALLOON_TAG)
	self._factory:Release(entry.Instance, entry.DefinitionId)

	-- Un globo retirado deja hueco: se vuelve a modo llenado si el mapa se
	-- ha vaciado mucho (por ejemplo tras una racha de pinchazos).
	if self._activeCount < SPAWNING.MaxActive * 0.5 then
		self._filling = SPAWNING.InitialBurst
	end

	self.BalloonDespawned:Fire(entry, reason or "unknown")

	return true
end

function BalloonManager:DespawnAll(reason: string?)
	for balloonId in pairs(table.clone(self._active)) do
		self:Despawn(balloonId, reason or "cleanup")
	end
end

--------------------------------------------------------------------------------
-- Consulta
--------------------------------------------------------------------------------

function BalloonManager:Get(balloonId: string)
	return self._active[balloonId]
end

--[[
	Resolucion O(1) de instancia a entrada. La usara el sistema de pinchado
	para validar el objetivo que envia el cliente.
--]]
function BalloonManager:GetFromInstance(instance: Instance?)
	if not instance then
		return nil
	end

	local entry = self._byInstance[instance]
	if entry then
		return entry
	end

	-- Si el cliente envia una parte hija de un modelo, se sube al ancestro
	local model = instance:FindFirstAncestorOfClass("Model")
	return if model then self._byInstance[model] else nil
end

function BalloonManager:GetActiveCount(): number
	return self._activeCount
end

function BalloonManager:GetStats()
	local factoryStats = self._factory:GetStats()

	return {
		Active = self._activeCount,
		MaxActive = SPAWNING.MaxActive,
		ByZone = table.clone(self._countByZone),
		SpawnPoints = self._spawnPoints:GetCount(),
		InstancesCreated = factoryStats.Created,
		InstancesPooled = factoryStats.Pooled,
		Filling = self._filling,
	}
end

--------------------------------------------------------------------------------
-- Dano (preparado para el sistema de pinchado)
--------------------------------------------------------------------------------

--[[
	Aplica dano a un globo y lo retira si su vida llega a 0.
	Devuelve (destruido, entry).

	El manager NO reparte recompensas a proposito: solo avisa con
	BalloonDestroyed. Quien pague sera CurrencyService a traves del servicio de
	pinchado, de modo que el dinero sigue teniendo un unico dueno.
--]]
function BalloonManager:ApplyDamage(balloonId: string, amount: number, player: Player?): (boolean, any)
	local entry = self._active[balloonId]
	if not entry then
		return false, nil
	end

	local damage = math.max(math.floor(amount), 1)
	entry.Health -= damage
	entry.Instance:SetAttribute(Config.Balloons.Attributes.Health, math.max(entry.Health, 0))

	self.BalloonDamaged:Fire(entry, damage, player)

	if entry.Health > 0 then
		return false, entry
	end

	self.BalloonDestroyed:Fire(entry, player)
	self:Despawn(balloonId, "popped")

	return true, entry
end

--------------------------------------------------------------------------------

function BalloonManager:Destroy()
	self:Stop()
	self:DespawnAll("destroy")
	self._spawnPoints:Destroy()
	self._factory:Destroy()
end

return BalloonManager
