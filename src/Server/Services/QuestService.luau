--!nonstrict
--[[
	QuestService
	----------------------------------------------------------------------------
	ESQUELETO. Misiones basadas en estadisticas del jugador.

	PREPARADO PARA: misiones.
	El diseno es deliberadamente desacoplado: cada mision declara en
	QuestConfig la estadistica que sigue (`TrackedStat`) y este servicio se
	suscribe a StatsService.StatChanged. Asi, cualquier sistema nuevo que
	incremente una estadistica hace avanzar misiones sin tocar este archivo.

	API prevista
		QuestService:GetProgress(player, questId) -> QuestProgress?
		QuestService:Claim(player, questId)       -> boolean, string?
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)

local log = Logger.new("QuestService")

local QuestService = {}
QuestService.Name = "QuestService"
QuestService.Priority = 300

function QuestService:Init()
	self._data = nil
	self._stats = nil
	self._currency = nil
	self._levels = nil

	-- TrackedStat -> { questId }
	self._byStat = {} :: { [string]: { string } }
end

function QuestService:Start()
	self._data = Loader.Get("DataService")
	self._stats = Loader.Get("StatsService")
	self._currency = Loader.Get("CurrencyService")
	self._levels = Loader.Get("LevelService")

	self:_buildIndex()

	-- Avance automatico de misiones al cambiar una estadistica
	self._stats.StatChanged:Connect(function(player, stat, value)
		self:_onStatChanged(player, stat, value)
	end)

	Net.OnInvoke("RequestClaimQuest", function(player, questId)
		if type(questId) ~= "string" then
			return false, "bad-request"
		end
		return self:Claim(player, questId)
	end)

	log:Debug("Sistema de misiones preparado")
end

function QuestService:_buildIndex()
	for id, quest in pairs(Config.Quests.Quests) do
		local list = self._byStat[quest.TrackedStat]
		if not list then
			list = {}
			self._byStat[quest.TrackedStat] = list
		end
		table.insert(list, id)
	end
end

function QuestService:_quests(player: Player)
	local profile = self._data:GetProfile(player)
	return profile and profile.Quests or nil
end

function QuestService:GetProgress(player: Player, questId: string)
	local quests = self:_quests(player)
	return quests and quests[questId] or nil
end

--[[
	TODO: completar cuando existan misiones definidas.
	Actualiza el progreso de todas las misiones que siguen esa estadistica.
--]]
function QuestService:_onStatChanged(player: Player, stat: string, value: number)
	local ids = self._byStat[stat]
	if not ids then
		return
	end

	local quests = self:_quests(player)
	if not quests then
		return
	end

	local changed = false

	for _, questId in ipairs(ids) do
		local definition = Config.Quests.Quests[questId]
		local progress = quests[questId]

		if not progress then
			progress = { Id = questId, Progress = 0, Completed = false }
			quests[questId] = progress
		end

		if progress.Completed then
			continue
		end

		progress.Progress = value
		if progress.Progress >= definition.Goal then
			progress.Completed = true
		end
		changed = true
	end

	if changed then
		self._data:MarkDirty(player)
		Net.FireClient("QuestsUpdated", player, quests)
	end
end

--[[
	Reclama la recompensa de una mision completada.
	Motivos de fallo: "no-quest" | "not-completed" | "already-claimed"
--]]
function QuestService:Claim(player: Player, questId: string): (boolean, string?)
	local definition = Config.Quests.Quests[questId]
	if not definition then
		return false, "no-quest"
	end

	local progress = self:GetProgress(player, questId)
	if not progress or not progress.Completed then
		return false, "not-completed"
	end
	if progress.ClaimedAt then
		return false, "already-claimed"
	end

	local reward = definition.Reward
	if reward.Coins then
		self._currency:Add(player, "Coins", reward.Coins)
	end
	if reward.Gems then
		self._currency:Add(player, "Gems", reward.Gems)
	end
	if reward.Experience then
		self._levels:AddExperience(player, reward.Experience)
	end

	progress.ClaimedAt = os.time()
	self._stats:Increment(player, "QuestsCompleted", 1)
	self._data:MarkDirty(player)

	Net.FireClient("QuestsUpdated", player, self:_quests(player))

	return true
end

return QuestService
