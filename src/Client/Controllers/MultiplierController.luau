--!nonstrict
--[[
	MultiplierController
	----------------------------------------------------------------------------
	ESQUELETO. Recibe el resumen de multiplicadores del servidor y lo pasa al
	HUD. Mantener este dato en un unico sitio evita que varias partes de la
	interfaz calculen multiplicadores por su cuenta.

	PREPARADO PARA: multiplicadores.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared.Framework.Loader)
local Net = require(Shared.Network.Net)

local MultiplierController = {}
MultiplierController.Name = "MultiplierController"
MultiplierController.Priority = 400

function MultiplierController:Init()
	self._summary = {}
	self._hud = nil
end

function MultiplierController:Start()
	self._hud = Loader.Get("HudController")

	Net.OnClientEvent("MultipliersChanged", function(summary)
		if type(summary) ~= "table" then
			return
		end
		self._summary = summary
		self._hud:SetMultipliers(summary)
	end)
end

function MultiplierController:Get(kind: string): number
	return self._summary[kind] or 1
end

return MultiplierController
