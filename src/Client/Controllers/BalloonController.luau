--!nonstrict
--[[
	BalloonController
	----------------------------------------------------------------------------
	Lado cliente de los globos. Se encarga SOLO de lo visual: la aparicion, la
	vida y las recompensas son responsabilidad del servidor.

	Los globos se detectan por el tag "Balloon" de CollectionService, no
	escuchando ChildAdded del contenedor. Con 150 globos apareciendo y
	desapareciendo continuamente, los tags permiten reaccionar sin recorrer el
	arbol.

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

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)

local log = Logger.new("BalloonController")

local TAG = Config.Game.Tags.Balloon
local ATTR = Config.Balloons.Attributes
local VISUALS = Config.Balloons.Visuals

local BalloonController = {}
BalloonController.Name = "BalloonController"
BalloonController.Priority = 400

--------------------------------------------------------------------------------
-- Ciclo de vida
--------------------------------------------------------------------------------

function BalloonController:Init()
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
	for _, instance in ipairs(CollectionService:GetTagged(TAG)) do
		self:_track(instance)
	end

	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance)
		self:_track(instance)
	end)

	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
		self:_untrack(instance)
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
