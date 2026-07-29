--!nonstrict
--[[
	SpawnPointRegistry
	----------------------------------------------------------------------------
	Descubre y gestiona los puntos donde pueden aparecer globos.

	Un punto de aparicion es cualquier BasePart que cumpla una de estas dos:
		* Estar dentro de Workspace.World.Spawners
		* Tener el tag "BalloonSpawn" de CollectionService

	Cada punto define un AREA, no un punto exacto: la posicion final es
	aleatoria dentro del volumen de la Part (respetando su rotacion). Asi una
	sola Part grande y plana cubre toda una zona, en lugar de necesitar
	docenas de marcadores.

	Atributos opcionales en la Part:
		ZoneId    (string) zona a la que pertenece. Por defecto la zona inicial.
		Weight    (number) peso relativo de aparicion. Por defecto 1.
		MaxActive (number) tope propio de globos vivos. Por defecto el de config.
		BalloonId (string) fuerza un tipo concreto de globo en este punto.

	El registro se actualiza en caliente: anadir o quitar una Part en Studio
	con Rojo conectado se refleja al instante sin reiniciar.
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)
local Signal = require(Shared.Util.Signal)
local WeightedRandom = require(Shared.Util.WeightedRandom)

local log = Logger.new("SpawnPointRegistry")

local TAG = Config.Game.Tags.BalloonSpawn
local DEFAULT_ZONE = Config.Zones.DefaultZoneId

local SpawnPointRegistry = {}
SpawnPointRegistry.__index = SpawnPointRegistry

--------------------------------------------------------------------------------

function SpawnPointRegistry.new(spawnersFolder: Instance?)
	local self = setmetatable({
		_folder = spawnersFolder,
		-- part -> descriptor
		_points = {},
		_count = 0,
		-- Cache de selector por peso; se invalida al cambiar el conjunto
		_picker = nil,
		_connections = {},

		Changed = Signal.new(),
	}, SpawnPointRegistry)

	return self
end

--------------------------------------------------------------------------------
-- Descubrimiento
--------------------------------------------------------------------------------

function SpawnPointRegistry:Scan()
	if self._folder then
		for _, descendant in ipairs(self._folder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				self:Add(descendant)
			end
		end

		table.insert(
			self._connections,
			self._folder.DescendantAdded:Connect(function(descendant)
				if descendant:IsA("BasePart") then
					self:Add(descendant)
				end
			end)
		)

		table.insert(
			self._connections,
			self._folder.DescendantRemoving:Connect(function(descendant)
				self:Remove(descendant)
			end)
		)
	end

	for _, tagged in ipairs(CollectionService:GetTagged(TAG)) do
		if tagged:IsA("BasePart") then
			self:Add(tagged)
		end
	end

	table.insert(
		self._connections,
		CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance)
			if instance:IsA("BasePart") then
				self:Add(instance)
			end
		end)
	)

	table.insert(
		self._connections,
		CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
			self:Remove(instance)
		end)
	)

	log:Info("%d puntos de aparicion detectados", self._count)
end

--[[
	Crea un area de aparicion por defecto si el mapa no tiene ninguna.
	Evita que el sistema parezca roto en un Baseplate vacio.
--]]
function SpawnPointRegistry:EnsureDefault(parent: Instance, position: Vector3, size: Vector3): BasePart?
	if self._count > 0 then
		return nil
	end

	local part = Instance.new("Part")
	part.Name = "DefaultSpawnArea"
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	part:SetAttribute("ZoneId", DEFAULT_ZONE)
	part:SetAttribute("Weight", 1)
	part.Parent = parent

	self:Add(part)
	log:Warn("Sin puntos de aparicion en el mapa: se ha creado '%s'", part.Name)

	return part
end

--------------------------------------------------------------------------------
-- Alta y baja
--------------------------------------------------------------------------------

function SpawnPointRegistry:Add(part: BasePart)
	if self._points[part] then
		return
	end

	local zoneId = part:GetAttribute("ZoneId")
	if type(zoneId) ~= "string" or not Config.Zones.Zones[zoneId] then
		if type(zoneId) == "string" then
			log:Warn("'%s' apunta a la zona desconocida '%s', se usa '%s'", part.Name, zoneId, DEFAULT_ZONE)
		end
		zoneId = DEFAULT_ZONE
	end

	local weight = tonumber(part:GetAttribute("Weight")) or 1
	local maxActive = tonumber(part:GetAttribute("MaxActive")) or Config.Balloons.Spawning.MaxActivePerSpawnPoint
	local forcedBalloon = part:GetAttribute("BalloonId")

	self._points[part] = {
		Part = part,
		ZoneId = zoneId,
		Weight = math.max(weight, 0),
		MaxActive = math.max(maxActive, 1),
		ForcedBalloonId = if type(forcedBalloon) == "string" then forcedBalloon else nil,
		Active = 0,
		-- Posiciones ocupadas, para respetar la separacion minima
		Occupied = {},
	}

	self._count += 1
	self._picker = nil
	self.Changed:Fire()
end

function SpawnPointRegistry:Remove(part: Instance)
	if not self._points[part] then
		return
	end

	self._points[part] = nil
	self._count -= 1
	self._picker = nil
	self.Changed:Fire()
end

--------------------------------------------------------------------------------
-- Seleccion
--------------------------------------------------------------------------------

function SpawnPointRegistry:_buildPicker()
	local entries = {}
	for _, descriptor in pairs(self._points) do
		if descriptor.Part.Parent then
			table.insert(entries, { Value = descriptor, Weight = descriptor.Weight })
		end
	end

	self._picker = WeightedRandom.new(entries)
	return self._picker
end

--[[
	Elige un punto al azar (por peso) que tenga hueco.
	`isZoneAllowed(zoneId)` permite al manager descartar zonas que ya han
	alcanzado su tope, sin que el registro sepa nada de esa contabilidad.
--]]
function SpawnPointRegistry:PickAvailable(isZoneAllowed: ((string) -> boolean)?, attempts: number?): any
	local picker = self._picker or self:_buildPicker()
	if picker:IsEmpty() then
		return nil
	end

	for _ = 1, attempts or 6 do
		local descriptor = picker:Pick()
		if not descriptor then
			return nil
		end
		if descriptor.Active < descriptor.MaxActive and descriptor.Part.Parent then
			if not isZoneAllowed or isZoneAllowed(descriptor.ZoneId) then
				return descriptor
			end
		end
	end

	return nil
end

--------------------------------------------------------------------------------
-- Posicion aleatoria
--------------------------------------------------------------------------------

--[[
	Punto aleatorio dentro del volumen de la Part, en su espacio local, mas la
	altura de flotacion. Devuelve nil si no encuentra hueco que respete la
	separacion minima.
--]]
function SpawnPointRegistry:PickPosition(descriptor, random: Random): Vector3?
	local spawning = Config.Balloons.Spawning
	local part = descriptor.Part
	local size = part.Size
	local separationSq = spawning.MinSeparation * spawning.MinSeparation

	for _ = 1, spawning.PlacementAttempts do
		local offset = Vector3.new(
			(random:NextNumber() - 0.5) * size.X,
			0,
			(random:NextNumber() - 0.5) * size.Z
		)

		local height = random:NextNumber(spawning.FloatHeightMin, spawning.FloatHeightMax)
		local candidate = part.CFrame:PointToWorldSpace(offset) + Vector3.new(0, size.Y * 0.5 + height, 0)

		-- Comparacion con distancias al cuadrado: evita la raiz cuadrada de
		-- Magnitude en un bucle que corre muchas veces por segundo.
		local blocked = false
		for _, occupied in pairs(descriptor.Occupied) do
			local delta = occupied - candidate
			if delta:Dot(delta) < separationSq then
				blocked = true
				break
			end
		end

		if not blocked then
			return candidate
		end
	end

	return nil
end

--------------------------------------------------------------------------------
-- Contabilidad
--------------------------------------------------------------------------------

function SpawnPointRegistry:Occupy(descriptor, balloonId: string, position: Vector3)
	descriptor.Active += 1
	descriptor.Occupied[balloonId] = position
end

function SpawnPointRegistry:Free(descriptor, balloonId: string)
	if not descriptor then
		return
	end
	descriptor.Active = math.max(descriptor.Active - 1, 0)
	descriptor.Occupied[balloonId] = nil
end

function SpawnPointRegistry:GetCount(): number
	return self._count
end

function SpawnPointRegistry:GetZones(): { [string]: number }
	local zones = {}
	for _, descriptor in pairs(self._points) do
		zones[descriptor.ZoneId] = (zones[descriptor.ZoneId] or 0) + 1
	end
	return zones
end

function SpawnPointRegistry:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._points)
	self._count = 0
	self._picker = nil
end

return SpawnPointRegistry
