--!nonstrict
--[[
	MultiplierService
	----------------------------------------------------------------------------
	ESQUELETO. Calcula los multiplicadores activos de cada jugador
	(monedas, experiencia, potencia, suerte) combinando todas las fuentes:
	gamepasses, mascotas equipadas, pociones temporales y eventos.

	PREPARADO PARA: multiplicadores.

	API prevista
		MultiplierService:Get(player, "Coins")                  -> number
		MultiplierService:Apply(player, "Coins", 100)           -> number
		MultiplierService:AddSource(player, id, kind, value, duration?)
		MultiplierService:RemoveSource(player, id)
		MultiplierService.MultipliersChanged                    Signal(player)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("MultiplierService")

local MultiplierService = {}
MultiplierService.Name = "MultiplierService"
MultiplierService.Priority = 600

function MultiplierService:Init()
	self._data = nil
	self.MultipliersChanged = Signal.new()
end

function MultiplierService:Start()
	self._data = Loader.Get("DataService")

	-- TODO: bucle que retire las fuentes temporales caducadas y avise al cliente
	log:Debug("Sistema de multiplicadores preparado (modo base x%d)", Config.Multipliers.BaseValue)
end

function MultiplierService:_sources(player: Player)
	local profile = self._data:GetProfile(player)
	return profile and profile.Multipliers or nil
end

--[[
	Multiplicador total de un tipo. Sin fuentes activas devuelve BaseValue.
--]]
function MultiplierService:Get(player: Player, kind: string): number
	local sources = self:_sources(player)
	local base = Config.Multipliers.BaseValue
	if not sources then
		return base
	end

	local now = os.time()
	local total = base
	local additive = Config.Multipliers.StackMode == "Additive"

	for _, source in pairs(sources) do
		if source.Kind ~= kind then
			continue
		end
		if source.ExpiresAt and source.ExpiresAt <= now then
			continue
		end

		if additive then
			total += (source.Value - 1)
		else
			total *= source.Value
		end
	end

	local max = Config.Multipliers.MaxValuePerKind[kind]
	if max then
		total = math.min(total, max)
	end

	return total
end

--[[
	Aplica el multiplicador a una cantidad (redondeado hacia abajo).
--]]
function MultiplierService:Apply(player: Player, kind: string, amount: number): number
	return math.floor(amount * self:Get(player, kind))
end

--[[
	TODO: registrar una fuente nueva (gamepass, mascota, pocion...).
	`duration` en segundos; nil = permanente.
--]]
function MultiplierService:AddSource(player: Player, id: string, kind: string, value: number, duration: number?): boolean
	local sources = self:_sources(player)
	if not sources then
		return false
	end

	sources[id] = {
		Id = id,
		Kind = kind,
		Value = value,
		ExpiresAt = if duration then os.time() + duration else nil,
	}

	self._data:MarkDirty(player)
	self:_notify(player)
	return true
end

function MultiplierService:RemoveSource(player: Player, id: string): boolean
	local sources = self:_sources(player)
	if not sources or not sources[id] then
		return false
	end

	sources[id] = nil
	self._data:MarkDirty(player)
	self:_notify(player)
	return true
end

function MultiplierService:_notify(player: Player)
	local summary = {}
	for kind in pairs(Config.Multipliers.MaxValuePerKind) do
		summary[kind] = self:Get(player, kind)
	end

	Net.FireClient("MultipliersChanged", player, summary)
	self.MultipliersChanged:Fire(player, summary)
end

return MultiplierService
