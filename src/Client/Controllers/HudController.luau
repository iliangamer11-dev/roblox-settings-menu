--!nonstrict
--[[
	HudController
	----------------------------------------------------------------------------
	ESQUELETO. Muestra monedas, nivel y multiplicadores en pantalla.

	Ya esta suscrito a los cambios de ClientState, asi que cuando exista la
	interfaz solo hay que rellenar _render con las etiquetas reales.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared.Util.Format)
local Logger = require(Shared.Util.Logger)
local Loader = require(Shared.Framework.Loader)

local ClientState = require(script.Parent.Parent.State.ClientState)

local log = Logger.new("HudController")

local HudController = {}
HudController.Name = "HudController"
HudController.Priority = 500

function HudController:Init()
	self._ui = nil
	self._multipliers = {}
end

function HudController:Start()
	self._ui = Loader.Get("UIController")

	ClientState.Ready:Connect(function()
		self:_render()
	end)

	ClientState.Changed:Connect(function(path)
		if path == "*" or path == "Currencies" or path == "Progression" then
			self:_render()
		end
	end)

	if ClientState.IsReady then
		self:_render()
	end
end

--[[
	TODO: enlazar con las etiquetas reales de StarterGui.Interface.
	Por ahora deja trazas para verificar que la replicacion funciona.
--]]
function HudController:_render()
	local coins = ClientState:GetCurrency("Coins")
	local level = ClientState:GetLevel()

	log:Debug("HUD -> monedas: %s | nivel: %d", Format.Abbreviate(coins), level)
end

--[[
	Llamado por MultiplierController cuando cambian los multiplicadores.
--]]
function HudController:SetMultipliers(summary: { [string]: number })
	self._multipliers = summary
	local coinMultiplier = summary.Coins or 1
	log:Debug("HUD -> multiplicador de monedas: %s", Format.Multiplier(coinMultiplier))
end

return HudController
