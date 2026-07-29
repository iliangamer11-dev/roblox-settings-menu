--!nonstrict
--[[
	UpgradeService
	----------------------------------------------------------------------------
	Mejoras de herramientas: niveles, coste del siguiente nivel y compra.

	PREPARADO PARA: mejoras de herramientas.
	La estructura completa esta lista (validacion, cobro via CurrencyService,
	replicacion). Solo falta definir el balanceo real en ToolConfig y la
	interfaz que lo muestre.

	API
		UpgradeService:GetLevel(player, toolId, upgradeId)  -> number
		UpgradeService:GetValue(player, toolId, upgradeId)  -> number?
		UpgradeService:GetCost(player, toolId, upgradeId)   -> number?
		UpgradeService:Purchase(player, toolId, upgradeId)  -> boolean, string?
		UpgradeService.UpgradePurchased                     Signal(player, toolId, upgradeId, level)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("UpgradeService")

local UpgradeService = {}
UpgradeService.Name = "UpgradeService"
-- Debe estar listo antes que ToolService, que lo consulta para las stats.
UpgradeService.Priority = 550

function UpgradeService:Init()
	self._data = nil
	self._currency = nil
	self._replication = nil
	self.UpgradePurchased = Signal.new()
end

function UpgradeService:Start()
	self._data = Loader.Get("DataService")
	self._currency = Loader.Get("CurrencyService")
	self._replication = Loader.Get("ReplicationService")

	Net.OnInvoke("RequestUpgradeTool", function(player, toolId, upgradeId)
		if type(toolId) ~= "string" or type(upgradeId) ~= "string" then
			return false, "bad-request"
		end
		return self:Purchase(player, toolId, upgradeId)
	end)

	log:Debug("Sistema de mejoras listo")
end

function UpgradeService:_definition(toolId: string, upgradeId: string)
	local tool = Config.Tools.Tools[toolId]
	return tool and tool.Upgrades[upgradeId] or nil
end

function UpgradeService:_ownedTool(player: Player, toolId: string)
	local profile = self._data:GetProfile(player)
	return profile and profile.Tools.Owned[toolId] or nil
end

function UpgradeService:GetLevel(player: Player, toolId: string, upgradeId: string): number
	local owned = self:_ownedTool(player, toolId)
	return if owned then (tonumber(owned.Upgrades[upgradeId]) or 0) else 0
end

--[[
	Valor efectivo de la mejora en el nivel actual del jugador.
	Devuelve nil si la mejora no existe.
--]]
function UpgradeService:GetValue(player: Player, toolId: string, upgradeId: string): number?
	local definition = self:_definition(toolId, upgradeId)
	if not definition then
		return nil
	end
	return definition.Value(self:GetLevel(player, toolId, upgradeId))
end

--[[
	Coste del siguiente nivel. nil si ya esta al maximo.
--]]
function UpgradeService:GetCost(player: Player, toolId: string, upgradeId: string): number?
	local definition = self:_definition(toolId, upgradeId)
	if not definition then
		return nil
	end

	local level = self:GetLevel(player, toolId, upgradeId)
	if level >= definition.MaxLevel then
		return nil
	end

	return definition.Cost(level)
end

--[[
	Compra un nivel de mejora.
	Devuelve (ok, motivo). Motivos: "no-tool" | "no-upgrade" | "max-level" | "no-funds"
--]]
function UpgradeService:Purchase(player: Player, toolId: string, upgradeId: string): (boolean, string?)
	local owned = self:_ownedTool(player, toolId)
	if not owned then
		return false, "no-tool"
	end

	local definition = self:_definition(toolId, upgradeId)
	if not definition then
		return false, "no-upgrade"
	end

	local level = self:GetLevel(player, toolId, upgradeId)
	if level >= definition.MaxLevel then
		return false, "max-level"
	end

	local cost = definition.Cost(level)
	if not self._currency:TrySpend(player, definition.Currency, cost) then
		return false, "no-funds"
	end

	local newLevel = level + 1
	owned.Upgrades[upgradeId] = newLevel

	self._data:MarkDirty(player)
	self._replication:PushPath(player, "Tools", { Owned = { [toolId] = owned } })
	Net.FireClient("ToolUpdated", player, toolId, owned)
	self.UpgradePurchased:Fire(player, toolId, upgradeId, newLevel)

	log:Debug("%s mejoro %s/%s al nivel %d", player.Name, toolId, upgradeId, newLevel)

	return true
end

return UpgradeService
