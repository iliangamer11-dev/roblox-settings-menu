--!nonstrict
--[[
	BalloonFactory
	----------------------------------------------------------------------------
	Construye, configura y RECICLA las instancias de globo.

	Optimizacion clave: pooling. Crear y destruir cientos de instancias por
	minuto genera basura y picos de replicacion. En lugar de eso, al reventar
	un globo su instancia se guarda en una reserva (fuera de Workspace) y se
	reutiliza para el siguiente del mismo tipo. `Instance.new` solo ocurre
	durante el precalentamiento y cuando la reserva se agota.

	Fuente del modelo, por orden de prioridad:
		1. ServerStorage.Assets.Balloons[definition.Model]  (clonado)
		2. Generacion por codigo: una Part esferica del color y tamano de la
		   definicion. Asi el sistema funciona en un mapa vacio sin assets.

	Los datos del globo se escriben como ATRIBUTOS de la instancia. Los
	atributos se replican solos al cliente y no anaden instancias hijas, que
	es lo que importa cuando hay 150 globos vivos.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)

local log = Logger.new("BalloonFactory")

local ATTR = Config.Balloons.Attributes

local BalloonFactory = {}
BalloonFactory.__index = BalloonFactory

--------------------------------------------------------------------------------
-- Construccion
--------------------------------------------------------------------------------

--[[
	`assetsFolder` es ServerStorage.Assets.Balloons (puede ser nil).
	`reserve` es el contenedor donde duermen las instancias recicladas.
--]]
function BalloonFactory.new(assetsFolder: Instance?, reserve: Instance)
	return setmetatable({
		_assets = assetsFolder,
		_reserve = reserve,
		-- definitionId -> array de instancias libres
		_pool = {},
		_pooled = 0,
		_created = 0,
	}, BalloonFactory)
end

--[[
	Prepara una parte para que sea lo mas barata posible:
	anclada (sin fisica), sin colisiones, sin sombra y consultable por raycast
	para el futuro sistema de pinchado.
--]]
local function configurePart(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true -- lo necesitara la Tool para detectar contacto
	part.CanQuery = true -- lo necesitara el raycast
	part.CastShadow = false
	part.Massless = true
end

--[[
	Globo generado por codigo cuando no hay modelo en ServerStorage.
--]]
local function buildProcedural(definition): BasePart
	local part = Instance.new("Part")
	part.Name = "Balloon"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(definition.Size, definition.Size, definition.Size)
	part.Color = definition.Color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	configurePart(part)
	return part
end

--[[
	Deja un modelo clonado en condiciones: ancla todo, quita colisiones y
	garantiza que tenga PrimaryPart para poder moverlo con PivotTo.
--]]
local function prepareModel(model: Model): Model?
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			configurePart(descendant)
		end
	end

	if not model.PrimaryPart then
		local firstPart = model:FindFirstChildWhichIsA("BasePart", true)
		if not firstPart then
			log:Warn("El modelo '%s' no tiene ninguna BasePart", model.Name)
			return nil
		end
		model.PrimaryPart = firstPart
	end

	return model
end

function BalloonFactory:_template(definition): Instance?
	if not definition.Model or not self._assets then
		return nil
	end
	return self._assets:FindFirstChild(definition.Model)
end

function BalloonFactory:_create(definition): Instance?
	local template = self:_template(definition)

	if template then
		local clone = template:Clone()
		if clone:IsA("Model") then
			local prepared = prepareModel(clone)
			if not prepared then
				clone:Destroy()
				return nil
			end
			self._created += 1
			return prepared
		elseif clone:IsA("BasePart") then
			configurePart(clone)
			self._created += 1
			return clone
		end

		log:Warn("El asset '%s' no es Model ni BasePart, se ignora", definition.Model)
		clone:Destroy()
	end

	self._created += 1
	return buildProcedural(definition)
end

--------------------------------------------------------------------------------
-- Reserva (pool)
--------------------------------------------------------------------------------

--[[
	Crea instancias por adelantado para evitar picos durante la partida.
--]]
function BalloonFactory:Prewarm(definition, count: number)
	local pool = self._pool[definition.Id]
	if not pool then
		pool = {}
		self._pool[definition.Id] = pool
	end

	for _ = 1, count do
		local instance = self:_create(definition)
		if not instance then
			return
		end
		instance.Parent = self._reserve
		table.insert(pool, instance)
		self._pooled += 1
	end
end

--[[
	Devuelve una instancia lista para colocar, reciclando si hay disponible.
--]]
function BalloonFactory:Acquire(definition): Instance?
	local pool = self._pool[definition.Id]

	if pool and #pool > 0 then
		local instance = table.remove(pool)
		self._pooled -= 1
		return instance
	end

	return self:_create(definition)
end

--[[
	Devuelve la instancia a la reserva. Se limpian los atributos para que no
	arrastre datos del globo anterior.
--]]
function BalloonFactory:Release(instance: Instance, definitionId: string)
	if not instance or not instance.Parent then
		return
	end

	for _, attributeName in pairs(ATTR) do
		instance:SetAttribute(attributeName, nil)
	end

	instance.Parent = self._reserve

	local pool = self._pool[definitionId]
	if not pool then
		pool = {}
		self._pool[definitionId] = pool
	end

	table.insert(pool, instance)
	self._pooled += 1
end

--------------------------------------------------------------------------------
-- Colocacion y datos
--------------------------------------------------------------------------------

--[[
	Mueve la instancia, sea Model o BasePart.
--]]
function BalloonFactory.SetPosition(instance: Instance, position: Vector3)
	if instance:IsA("Model") then
		instance:PivotTo(CFrame.new(position))
	elseif instance:IsA("BasePart") then
		instance.CFrame = CFrame.new(position)
	end
end

--[[
	Escribe los datos del globo como atributos.
	Nombre, rareza, recompensa y vida quedan accesibles desde el cliente sin
	necesidad de un RemoteEvent por globo.
--]]
function BalloonFactory.ApplyAttributes(instance: Instance, id: string, definition, zoneId: string)
	instance:SetAttribute(ATTR.Id, id)
	instance:SetAttribute(ATTR.Type, definition.Id)
	instance:SetAttribute(ATTR.Name, definition.DisplayName)
	instance:SetAttribute(ATTR.Rarity, definition.Rarity)
	instance:SetAttribute(ATTR.Reward, definition.Reward.Coins)
	instance:SetAttribute(ATTR.Experience, definition.Reward.Experience)
	instance:SetAttribute(ATTR.Health, definition.Health)
	instance:SetAttribute(ATTR.MaxHealth, definition.Health)
	instance:SetAttribute(ATTR.Zone, zoneId)
end

--------------------------------------------------------------------------------

function BalloonFactory:GetStats()
	return {
		Created = self._created,
		Pooled = self._pooled,
	}
end

function BalloonFactory:Destroy()
	for _, pool in pairs(self._pool) do
		for _, instance in ipairs(pool) do
			instance:Destroy()
		end
	end
	table.clear(self._pool)
	self._pooled = 0
end

return BalloonFactory
