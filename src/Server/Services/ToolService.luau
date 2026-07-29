--!nonstrict
--[[
	ToolService
	----------------------------------------------------------------------------
	Propiedad y equipamiento de herramientas (Cuchillo y futuras).

	PREPARADO PARA: Tool "Cuchillo".
	La estructura de datos, la validacion de propiedad y los remotes ya estan.
	Lo que falta (y llega en el siguiente paso) es clonar el modelo real desde
	ServerStorage.Assets.Tools y darle comportamiento de pinchado.

	API
		ToolService:Owns(player, "Cuchillo")        -> boolean
		ToolService:Grant(player, "Cuchillo")      -> boolean
		ToolService:Equip(player, "Cuchillo")      -> boolean
		ToolService:GetEquipped(player)            -> ToolId?
		ToolService:GetStats(player, toolId)       -> { Power, Range, Cooldown }
		ToolService.ToolGranted / ToolEquipped     Signals
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("ToolService")

local ToolService = {}
ToolService.Name = "ToolService"
ToolService.Priority = 500

function ToolService:Init()
	self._data = nil
	self._replication = nil
	self._upgrades = nil

	self.ToolGranted = Signal.new() -- (player, toolId)
	self.ToolEquipped = Signal.new() -- (player, toolId)
end

function ToolService:Start()
	self._data = Loader.Get("DataService")
	self._replication = Loader.Get("ReplicationService")
	self._upgrades = Loader.Get("UpgradeService")

	local players = Loader.Get("PlayerService")

	-- Al cargar el perfil se garantiza que tiene las herramientas por defecto
	players.PlayerReady:Connect(function(player, profile)
		self:_ensureDefaults(player, profile)
	end)

	-- Al aparecer el personaje se entrega la herramienta equipada
	players.CharacterAdded:Connect(function(player, character)
		self:_giveEquippedTool(player, character)
	end)

	Net.OnInvoke("RequestEquipTool", function(player, toolId)
		if type(toolId) ~= "string" then
			return false
		end
		return self:Equip(player, toolId)
	end)

	log:Debug("Sistema de herramientas listo (%d definidas)", self:_definitionCount())
end

function ToolService:_definitionCount(): number
	local count = 0
	for _ in pairs(Config.Tools.Tools) do
		count += 1
	end
	return count
end

function ToolService:_inventory(player: Player)
	local profile = self._data:GetProfile(player)
	return profile and profile.Tools or nil
end

--[[
	Otorga las herramientas marcadas como `Default` en ToolConfig.
--]]
function ToolService:_ensureDefaults(player: Player, profile: any)
	for id, definition in pairs(Config.Tools.Tools) do
		if definition.Default and not profile.Tools.Owned[id] then
			self:Grant(player, id)
		end
	end

	if not profile.Tools.Equipped then
		self:Equip(player, Config.Tools.DefaultToolId)
	end
end

function ToolService:Owns(player: Player, toolId: string): boolean
	local inventory = self:_inventory(player)
	return inventory ~= nil and inventory.Owned[toolId] ~= nil
end

function ToolService:Grant(player: Player, toolId: string): boolean
	local definition = Config.Tools.Tools[toolId]
	if not definition then
		log:Warn("Herramienta desconocida '%s'", toolId)
		return false
	end

	local inventory = self:_inventory(player)
	if not inventory or inventory.Owned[toolId] then
		return false
	end

	inventory.Owned[toolId] = {
		Id = toolId,
		Upgrades = {},
		AcquiredAt = os.time(),
	}

	self._data:MarkDirty(player)
	self._replication:PushPath(player, "Tools", inventory)
	self.ToolGranted:Fire(player, toolId)

	return true
end

function ToolService:GetEquipped(player: Player): string?
	local inventory = self:_inventory(player)
	return inventory and inventory.Equipped or nil
end

function ToolService:Equip(player: Player, toolId: string): boolean
	if not self:Owns(player, toolId) then
		return false
	end

	local inventory = self:_inventory(player)
	inventory.Equipped = toolId

	self._data:MarkDirty(player)
	self._replication:PushPath(player, "Tools", { Equipped = toolId })
	Net.FireClient("ToolUpdated", player, toolId, inventory.Owned[toolId])
	self.ToolEquipped:Fire(player, toolId)

	self:_giveEquippedTool(player, player.Character)

	return true
end

--[[
	Estadisticas efectivas de una herramienta = base + mejoras compradas.
	Es la funcion que consultara el sistema de pinchado para saber el dano.
--]]
function ToolService:GetStats(player: Player, toolId: string?)
	local id = toolId or self:GetEquipped(player)
	local definition = id and Config.Tools.Tools[id]
	if not definition then
		return nil
	end

	local stats = {
		Power = definition.Base.Power,
		Range = definition.Base.Range,
		Cooldown = definition.Base.Cooldown,
	}

	-- Las mejoras sobrescriben la estadistica correspondiente
	local power = self._upgrades:GetValue(player, id, "Power")
	if power then
		stats.Power = power
	end

	local speed = self._upgrades:GetValue(player, id, "Speed")
	if speed then
		stats.Cooldown = speed
	end

	return stats
end

--[[
	Clona el modelo de la herramienta en la mochila del jugador.

	TODO (siguiente paso): construir el modelo real del Cuchillo en
	ServerStorage.Assets.Tools y anadirle la logica de pinchado.
--]]
function ToolService:_giveEquippedTool(player: Player, character: Model?)
	if not character then
		return
	end

	local toolId = self:GetEquipped(player)
	if not toolId then
		return
	end

	local definition = Config.Tools.Tools[toolId]
	if not definition then
		return
	end

	local assets = ServerStorage:FindFirstChild("Assets")
	local toolsFolder = assets and assets:FindFirstChild("Tools")
	local template = toolsFolder and toolsFolder:FindFirstChild(definition.Model)

	if not template then
		log:Debug("Modelo '%s' no encontrado en ServerStorage.Assets.Tools", definition.Model)
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	-- Retira cualquier otra herramienta del catalogo para evitar duplicados
	for _, existing in ipairs(backpack:GetChildren()) do
		if existing:IsA("Tool") and Config.Tools.Tools[existing.Name] then
			existing:Destroy()
		end
	end
	local held = character:FindFirstChildOfClass("Tool")
	if held then
		held:Destroy()
	end

	local tool = template:Clone()
	tool.Name = toolId
	tool.Parent = backpack
end

return ToolService
