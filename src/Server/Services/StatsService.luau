--!nonstrict
--[[
	StatsService
	----------------------------------------------------------------------------
	Punto unico de lectura/escritura de las estadisticas del jugador
	(Profile.Stats). Cualquier sistema que quiera contar algo pasa por aqui.

	Ventajas de centralizarlo:
		* Replicacion automatica al cliente.
		* Marca el perfil como "dirty" para el autoguardado.
		* Emite StatChanged, que es lo que consumira el sistema de misiones
		  para avanzar objetivos sin acoplarse a cada sistema.

	API
		StatsService:Get(player, "BalloonsPopped")        -> number
		StatsService:Increment(player, "BalloonsPopped", 1)
		StatsService:Set(player, "HighestCombo", 12)
		StatsService:GetAll(player)                       -> tabla
		StatsService.StatChanged                          Signal(player, stat, new, old)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("StatsService")

local StatsService = {}
StatsService.Name = "StatsService"
StatsService.Priority = 700

function StatsService:Init()
	self._data = nil
	self._replication = nil
	self.StatChanged = Signal.new()
end

function StatsService:Start()
	self._data = Loader.Get("DataService")
	self._replication = Loader.Get("ReplicationService")
end

function StatsService:GetAll(player: Player)
	local profile = self._data:GetProfile(player)
	return profile and profile.Stats or nil
end

function StatsService:Get(player: Player, stat: string): number
	local stats = self:GetAll(player)
	return if stats then (tonumber(stats[stat]) or 0) else 0
end

function StatsService:Set(player: Player, stat: string, value: number): boolean
	local stats = self:GetAll(player)
	if not stats then
		return false
	end
	if stats[stat] == nil then
		log:Warn("Estadistica desconocida '%s' (anadela a ProfileTemplate)", stat)
		return false
	end

	local previous = stats[stat]
	if previous == value then
		return true
	end

	stats[stat] = value
	self._data:MarkDirty(player)
	self._replication:PushPath(player, "Stats", { [stat] = value })
	self.StatChanged:Fire(player, stat, value, previous)

	return true
end

function StatsService:Increment(player: Player, stat: string, amount: number?): number
	local delta = amount or 1
	local current = self:Get(player, stat)
	local newValue = current + delta
	self:Set(player, stat, newValue)
	return newValue
end

--[[
	Actualiza la estadistica solo si el valor nuevo es mayor (records).
--]]
function StatsService:SetIfHigher(player: Player, stat: string, value: number): boolean
	if value > self:Get(player, stat) then
		return self:Set(player, stat, value)
	end
	return false
end

return StatsService
