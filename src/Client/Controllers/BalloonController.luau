--!nonstrict
--[[
	BalloonController
	----------------------------------------------------------------------------
	Lado cliente de los globos. Se encarga SOLO de lo visual: la aparicion, la
	vida y las recompensas son responsabilidad del servidor.

	Los globos se detectan escuchando Workspace.World.Balloons, el contenedor
	que el servidor replica. No se usan tags de CollectionService porque los
	tags anadidos en runtime NO se replican al cliente.

	OPTIMIZACION DEL BALANCEO

	El movimiento vertical se calcula aqui, en cada cliente:
		* El servidor no gasta CPU en animar 150 globos.
		* No se replica ni un byte por el movimiento.
		* Solo se animan los globos cerca de la camara
		  (`Visuals.BobRenderDistance`), con un tope por frame
		  (`MaxAnimatedPerFrame`).
		* La lista de globos cercanos se recalcula cada
		  `CullRefreshInterval` segundos, no cada frame.

	El desplazamiento se aplica de forma relativa (se resta el offset anterior
	antes de aplicar el nuevo), asi que si el servidor mueve o recicla un globo,
	la animacion se adapta sola sin quedar desincronizada.

	PREPARADO PARA
		* Particulas y sonido al reventar (`_onPopped`).
		* Numeros flotantes de recompensa: los datos ya estan en los atributos.
		* Resaltado del globo apuntado por la Tool (`GetBalloonData`).
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)

local log = Logger.new("BalloonController")

local ATTR = Config.Balloons.Attributes
local VISUALS = Config.Balloons.Visuals

local BalloonController = {}
BalloonController.Name = "BalloonController"
BalloonController.Priority = 400

--------------------------------------------------------------------------------
-- Ciclo de vida
--------------------------------------------------------------------------------

function BalloonController:Init()
	self._container = nil
	-- instancia -> { Instance, Phase, LastOffset }
	self._tracked = {}
	self._trackedCount = 0
	-- Subconjunto animado este intervalo
	self._visible = {}
	self._cullTimer = 0
	self._clock = 0
	self._random = Random.new()
end

function BalloonController:Start()
	--[[
		IMPORTANTE: los tags de CollectionService NO se replican entre servidor
		y cliente. Solo existen en ambos lados si se guardaron en el archivo del
		lugar desde Studio. Un tag anadido en runtime por el servidor es
		invisible aqui, asi que el seguimiento va por el contenedor replicado.
		El tag sigue siendo util en el servidor y para instancias colocadas a
		mano en el mapa.
	--]]
	local world = Workspace:WaitForChild(Config.Game.Containers.World, 30)
	local container = world and world:WaitForChild(Config.Game.Containers.Balloons, 30)

	if not container then
		log:Error("No se encontro Workspace.%s.%s", Config.Game.Containers.World, Config.Game.Containers.Balloons)
		return
	end

	self._container = container

	for _, child in ipairs(container:GetChildren()) do
		self:_track(child)
	end

	container.ChildAdded:Connect(function(child)
		self:_track(child)
	end)

	container.ChildRemoved:Connect(function(child)
		self:_untrack(child)
	end)

	-- Remotes reservados para efectos puntuales. La aparicion normal NO usa
	-- remotes: llega por replicacion de instancias.
	Net.OnClientEvent("BalloonSpawned", function(payload)
		self:_onSpawned(payload)
	end)

	Net.OnClientEvent("BalloonPopped", function(payload)
		self:_onPopped(payload)
	end)

	if VISUALS.BobEnabled then
		RunService.Heartbeat:Connect(function(deltaTime)
			self:_update(deltaTime)
		end)
	end

	log:Debug("Controlador de globos activo (%d ya presentes)", self._trackedCount)
end

--------------------------------------------------------------------------------
-- Seguimiento
--------------------------------------------------------------------------------

function BalloonController:_track(instance: Instance)
	if self._tracked[instance] then
		return
	end

	if not (instance:IsA("BasePart") or instance:IsA("Model")) then
		return
	end

	self._tracked[instance] = {
		Instance = instance,
		-- Fase aleatoria para que no se muevan todos al unisono
		Phase = self._random:NextNumber() * math.pi * 2,
		LastOffset = 0,
	}
	self._trackedCount += 1
end

function BalloonController:_untrack(instance: Instance)
	if not self._tracked[instance] then
		return
	end
	self._tracked[instance] = nil
	self._trackedCount -= 1
	-- El proximo refresco de culling lo saca de la lista visible
end

--------------------------------------------------------------------------------
-- Posicion
--------------------------------------------------------------------------------

local function getPosition(instance: Instance): Vector3?
	if instance:IsA("BasePart") then
		return instance.Position
	elseif instance:IsA("Model") then
		local pivot = instance:GetPivot()
		return pivot.Position
	end
	return nil
end

local function setPosition(instance: Instance, position: Vector3)
	if instance:IsA("BasePart") then
		instance.CFrame = CFrame.new(position)
	elseif instance:IsA("Model") then
		instance:PivotTo(CFrame.new(position))
	end
end

--------------------------------------------------------------------------------
-- Culling y animacion
--------------------------------------------------------------------------------

--[[
	Recalcula que globos estan lo bastante cerca para merecer animacion.
--]]
function BalloonController:_refreshVisible()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local origin = camera.CFrame.Position
	local maxDistanceSq = VISUALS.BobRenderDistance * VISUALS.BobRenderDistance
	local limit = VISUALS.MaxAnimatedPerFrame

	local visible = {}

	for instance, entry in pairs(self._tracked) do
		if not instance.Parent then
			continue
		end

		local position = getPosition(instance)
		if not position then
			continue
		end

		-- Distancia al cuadrado para evitar la raiz cuadrada de Magnitude
		local delta = position - origin
		if delta:Dot(delta) <= maxDistanceSq then
			table.insert(visible, entry)
			if #visible >= limit then
				break
			end
		end
	end

	self._visible = visible
end

function BalloonController:_update(deltaTime: number)
	self._clock += deltaTime
	self._cullTimer -= deltaTime

	if self._cullTimer <= 0 then
		self._cullTimer = VISUALS.CullRefreshInterval
		self:_refreshVisible()
	end

	local amplitude = VISUALS.BobAmplitude
	local speed = VISUALS.BobSpeed
	local clock = self._clock

	for _, entry in ipairs(self._visible) do
		local instance = entry.Instance
		if not instance.Parent then
			continue
		end

		local current = getPosition(instance)
		if not current then
			continue
		end

		-- Se descuenta el desplazamiento anterior para no acumular deriva
		local base = current - Vector3.new(0, entry.LastOffset, 0)
		local offset = math.sin(clock * speed + entry.Phase) * amplitude

		setPosition(instance, base + Vector3.new(0, offset, 0))
		entry.LastOffset = offset
	end
end

--------------------------------------------------------------------------------
-- Datos del globo
--------------------------------------------------------------------------------

--[[
	Lee los atributos de un globo. Lo usara la Tool para saber a que esta
	apuntando y la interfaz para mostrar nombre, rareza y recompensa.
--]]
function BalloonController:GetBalloonData(instance: Instance?)
	if not instance then
		return nil
	end

	local target = instance
	if not target:GetAttribute(ATTR.Id) then
		target = instance:FindFirstAncestorOfClass("Model")
		if not target or not target:GetAttribute(ATTR.Id) then
			return nil
		end
	end

	return {
		Id = target:GetAttribute(ATTR.Id),
		Type = target:GetAttribute(ATTR.Type),
		DisplayName = target:GetAttribute(ATTR.Name),
		Rarity = target:GetAttribute(ATTR.Rarity),
		Reward = target:GetAttribute(ATTR.Reward),
		Experience = target:GetAttribute(ATTR.Experience),
		Health = target:GetAttribute(ATTR.Health),
		MaxHealth = target:GetAttribute(ATTR.MaxHealth),
		Zone = target:GetAttribute(ATTR.Zone),
		Instance = target,
	}
end

function BalloonController:GetTrackedCount(): number
	return self._trackedCount
end

--------------------------------------------------------------------------------
-- Efectos (preparado)
--------------------------------------------------------------------------------

--[[
	TODO: animacion de entrada (escala de 0 al tamano final).
--]]
function BalloonController:_onSpawned(payload: any) end

--[[
	TODO: particulas, sonido y numero flotante con la recompensa.
--]]
function BalloonController:_onPopped(payload: any) end

return BalloonController
