--!nonstrict
--[[
	ShopController
	----------------------------------------------------------------------------
	ESQUELETO. Lado cliente de las tiendas y de las mejoras de herramientas.

	PREPARADO PARA: tiendas + mejoras de herramientas.
	Las llamadas al servidor ya estan encapsuladas aqui, de modo que la
	interfaz solo tendra que llamar a estos metodos.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)

local log = Logger.new("ShopController")

local ShopController = {}
ShopController.Name = "ShopController"
ShopController.Priority = 300

function ShopController:Init()
	self._busy = false
end

function ShopController:Start()
	log:Debug("Controlador de tiendas listo")
end

--[[
	Evita invocaciones simultaneas del mismo jugador.
--]]
function ShopController:_guard<T>(operation: () -> T): T?
	if self._busy then
		return nil
	end
	self._busy = true

	local ok, result = pcall(operation)

	self._busy = false

	if not ok then
		log:Error("Peticion al servidor fallida: %s", tostring(result))
		return nil
	end
	return result
end

function ShopController:Purchase(shopId: string, itemId: string): boolean
	local result = self:_guard(function()
		return Net.Invoke("RequestPurchase", shopId, itemId)
	end)
	return result == true
end

function ShopController:UpgradeTool(toolId: string, upgradeId: string): boolean
	local result = self:_guard(function()
		return Net.Invoke("RequestUpgradeTool", toolId, upgradeId)
	end)
	return result == true
end

function ShopController:EquipTool(toolId: string): boolean
	local result = self:_guard(function()
		return Net.Invoke("RequestEquipTool", toolId)
	end)
	return result == true
end

--[[
	Catalogo local para pintar la interfaz sin pedir nada al servidor.
--]]
function ShopController:GetToolCatalog()
	local catalog = {}
	for _, definition in pairs(Config.Tools.Tools) do
		table.insert(catalog, definition)
	end
	table.sort(catalog, function(a, b)
		return a.Order < b.Order
	end)
	return catalog
end

return ShopController
