--!nonstrict
--[[
	LevelService
	----------------------------------------------------------------------------
	ESQUELETO. Experiencia y niveles del jugador.

	PREPARADO PARA: niveles.
	La estructura de datos (Profile.Progression), la curva (LevelConfig) y el
	remote LevelChanged ya existen. Falta decidir de donde sale la experiencia
	(pinchar globos, misiones) y las recompensas por nivel.

	API prevista
		LevelService:GetLevel(player)          -> number
		LevelService:AddExperience(player, n)  -> level, experience
		LevelService.LevelChanged              Signal(player, newLevel, oldLevel)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("LevelService")

local LevelService = {}
LevelService.Name = "LevelService"
LevelService.Priority = 600

function LevelService:Init()
	self._data = nil
	self._replication = nil
	self._players = nil
	self.LevelChanged = Signal.new()
end

function LevelService:Start()
	self._data = Loader.Get("DataService")
	self._replication = Loader.Get("ReplicationService")
	self._players = Loader.Get("PlayerService")
end

function LevelService:_progression(player: Player)
	local profile = self._data:GetProfile(player)
	return profile and profile.Progression or nil
end

function LevelService:GetLevel(player: Player): number
	local progression = self:_progression(player)
	return if progression then progression.Level else Config.Levels.StartingLevel
end

function LevelService:GetExperience(player: Player): number
	local progression = self:_progression(player)
	return if progression then progression.Experience else 0
end

--[[
	Experiencia necesaria para el siguiente nivel.
--]]
function LevelService:GetRequiredExperience(player: Player): number
	return Config.Levels.ExperienceForLevel(self:GetLevel(player))
end

--[[
	Anade experiencia y sube de nivel las veces que haga falta.

	TODO: aplicar el multiplicador de experiencia (MultiplierService) y
	entregar LevelConfig.LevelRewards al subir.
--]]
function LevelService:AddExperience(player: Player, amount: number): (number, number)
	local progression = self:_progression(player)
	if not progression or amount <= 0 then
		return self:GetLevel(player), self:GetExperience(player)
	end

	local previousLevel = progression.Level
	progression.Experience += amount

	while progression.Level < Config.Levels.MaxLevel do
		local required = Config.Levels.ExperienceForLevel(progression.Level)
		if progression.Experience < required then
			break
		end
		progression.Experience -= required
		progression.Level += 1
	end

	self._data:MarkDirty(player)
	self._replication:PushPath(player, "Progression", progression)

	if progression.Level ~= previousLevel then
		self._players:UpdateLeaderstat(player, "Nivel", progression.Level)
		Net.FireClient("LevelChanged", player, progression.Level, previousLevel)
		self.LevelChanged:Fire(player, progression.Level, previousLevel)
		log:Debug("%s subio al nivel %d", player.Name, progression.Level)
	end

	return progression.Level, progression.Experience
end

return LevelService
