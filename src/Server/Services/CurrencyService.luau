--!nonstrict
--[[
	CurrencyService
	----------------------------------------------------------------------------
	Monedero del jugador. Punto unico de entrada y salida de dinero: ningun
	sistema debe escribir Profile.Currencies directamente.

	PREPARADO PARA: sistema de dinero. La infraestructura (add/remove/can
	afford, replicacion, leaderstats, estadisticas) esta lista; las reglas de
	cuanto se gana al pinchar un globo llegaran con BalloonService.

	API
		CurrencyService:Get(player, "Coins")            -> number
		CurrencyService:Add(player, "Coins", 100)       -> number (nuevo saldo)
		CurrencyService:CanAfford(player, "Coins", 50)  -> boolean
		CurrencyService:TrySpend(player, "Coins", 50)   -> boolean
		CurrencyService.CurrencyChanged                 Signal(player, id, new, old)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("CurrencyService")

local CurrencyService = {}
CurrencyService.Name = "CurrencyService"
CurrencyService.Priority = 700

-- Estadistica que registra el total ganado de cada moneda
local EARNED_STAT = {
	Coins = "CoinsEarned",
	Gems = "GemsEarned",
}

function CurrencyService:Init()
	self._data = nil
	self._replication = nil
	self._stats = nil
	self._players = nil
	self.CurrencyChanged = Signal.new()
end

function CurrencyService:Start()
	self._data = Loader.Get("DataService")
	self._replication = Loader.Get("ReplicationService")
	self._stats = Loader.Get("StatsService")
	self._players = Loader.Get("PlayerService")
end

function CurrencyService:_wallet(player: Player)
	local profile = self._data:GetProfile(player)
	return profile and profile.Currencies or nil
end

function CurrencyService:Get(player: Player, currencyId: string): number
	local wallet = self:_wallet(player)
	return if wallet then (tonumber(wallet[currencyId]) or 0) else 0
end

function CurrencyService:CanAfford(player: Player, currencyId: string, amount: number): boolean
	return self:Get(player, currencyId) >= amount
end

--[[
	Escribe el saldo respetando el maximo definido en EconomyConfig.
--]]
function CurrencyService:_set(player: Player, currencyId: string, value: number): number
	local wallet = self:_wallet(player)
	if not wallet then
		return 0
	end

	local definition = Config.Economy.Currencies[currencyId]
	if not definition then
		log:Warn("Moneda desconocida '%s'", currencyId)
		return self:Get(player, currencyId)
	end

	local previous = tonumber(wallet[currencyId]) or 0
	local clamped = math.clamp(math.floor(value), 0, definition.Max)

	if clamped == previous then
		return previous
	end

	wallet[currencyId] = clamped
	self._data:MarkDirty(player)
	self._replication:PushPath(player, "Currencies", { [currencyId] = clamped })
	self._players:UpdateLeaderstat(player, currencyId, clamped)
	self.CurrencyChanged:Fire(player, currencyId, clamped, previous)

	return clamped
end

--[[
	Anade dinero. `amount` debe ser positivo.
	TODO: los multiplicadores se aplicaran desde MultiplierService antes de
	llamar a este metodo (o mediante el parametro `applyMultipliers`).
--]]
function CurrencyService:Add(player: Player, currencyId: string, amount: number): number
	if amount <= 0 then
		return self:Get(player, currencyId)
	end

	local newValue = self:_set(player, currencyId, self:Get(player, currencyId) + amount)

	local statName = EARNED_STAT[currencyId]
	if statName then
		self._stats:Increment(player, statName, amount)
	end

	return newValue
end

--[[
	Resta dinero sin comprobar el saldo (uso interno). Preferir TrySpend.
--]]
function CurrencyService:Remove(player: Player, currencyId: string, amount: number): number
	if amount <= 0 then
		return self:Get(player, currencyId)
	end
	return self:_set(player, currencyId, self:Get(player, currencyId) - amount)
end

--[[
	Cobro seguro: solo descuenta si hay saldo suficiente.
	Devuelve true si el pago se realizo.
--]]
function CurrencyService:TrySpend(player: Player, currencyId: string, amount: number): boolean
	if amount < 0 then
		return false
	end
	if not self:CanAfford(player, currencyId, amount) then
		return false
	end

	self:Remove(player, currencyId, amount)

	if currencyId == "Coins" then
		self._stats:Increment(player, "CoinsSpent", amount)
	end

	return true
end

return CurrencyService
