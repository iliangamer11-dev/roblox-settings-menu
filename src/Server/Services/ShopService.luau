--!nonstrict
--[[
	ShopService
	----------------------------------------------------------------------------
	ESQUELETO. Compras de articulos de tienda (herramientas, mascotas,
	multiplicadores, llaves de zona).

	PREPARADO PARA: tiendas.
	El remote, la validacion de estructura y el flujo de cobro estan montados.
	Falta rellenar ShopConfig.Shops y enrutar cada `Kind` al servicio que
	entrega el articulo.

	API
		ShopService:Purchase(player, shopId, itemId) -> boolean, string?
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)

local log = Logger.new("ShopService")

local ShopService = {}
ShopService.Name = "ShopService"
ShopService.Priority = 300

function ShopService:Init()
	self._currency = nil
	self._tools = nil
	self._levels = nil
	self._replication = nil
end

function ShopService:Start()
	self._currency = Loader.Get("CurrencyService")
	self._tools = Loader.Get("ToolService")
	self._levels = Loader.Get("LevelService")
	self._replication = Loader.Get("ReplicationService")

	Net.OnInvoke("RequestPurchase", function(player, shopId, itemId)
		if type(shopId) ~= "string" or type(itemId) ~= "string" then
			return false, "bad-request"
		end
		return self:Purchase(player, shopId, itemId)
	end)

	log:Debug("Sistema de tiendas preparado")
end

function ShopService:_findItem(shopId: string, itemId: string)
	local shop = Config.Shops.Shops[shopId]
	if not shop then
		return nil
	end
	for _, item in ipairs(shop.Items) do
		if item.Id == itemId then
			return item
		end
	end
	return nil
end

--[[
	Compra un articulo.
	Motivos de fallo: "no-item" | "level" | "owned" | "no-funds" | "not-implemented"
--]]
function ShopService:Purchase(player: Player, shopId: string, itemId: string): (boolean, string?)
	local item = self:_findItem(shopId, itemId)
	if not item then
		return false, "no-item"
	end

	if item.RequiredLevel and self._levels:GetLevel(player) < item.RequiredLevel then
		return false, "level"
	end

	-- Comprobacion de duplicados antes de cobrar
	if item.Kind == "Tool" and self._tools:Owns(player, item.TargetId) then
		return false, "owned"
	end

	if not self._currency:CanAfford(player, item.Currency, item.Price) then
		return false, "no-funds"
	end

	local delivered = self:_deliver(player, item)
	if not delivered then
		return false, "not-implemented"
	end

	self._currency:TrySpend(player, item.Currency, item.Price)
	Net.FireClient("PurchaseResult", player, shopId, itemId, true)

	return true
end

--[[
	Entrega el articulo comprado.
	TODO: anadir los casos "Pet", "Multiplier" y "ZoneKey" cuando existan
	esos sistemas.
--]]
function ShopService:_deliver(player: Player, item: any): boolean
	if item.Kind == "Tool" then
		return self._tools:Grant(player, item.TargetId)
	end

	log:Warn("Tipo de articulo '%s' todavia no implementado", tostring(item.Kind))
	return false
end

return ShopService
