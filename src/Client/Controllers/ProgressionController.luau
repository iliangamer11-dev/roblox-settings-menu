--!nonstrict
--[[
	ProgressionController
	----------------------------------------------------------------------------
	ESQUELETO. Lado cliente de niveles, misiones, mascotas y zonas: recibe las
	actualizaciones del servidor y expone metodos para que la interfaz pida
	acciones.

	PREPARADO PARA: niveles, misiones, mascotas y nuevas zonas.
	Cuando alguno de estos sistemas crezca, se puede extraer a su propio
	controlador sin tocar el resto del proyecto.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local Signal = require(Shared.Util.Signal)

local ClientState = require(script.Parent.Parent.State.ClientState)

local log = Logger.new("ProgressionController")

local ProgressionController = {}
ProgressionController.Name = "ProgressionController"
ProgressionController.Priority = 350

function ProgressionController:Init()
	self.LevelChanged = Signal.new()
	self.QuestsChanged = Signal.new()
	self.PetsChanged = Signal.new()
	self.ZoneChanged = Signal.new()
end

function ProgressionController:Start()
	Net.OnClientEvent("LevelChanged", function(newLevel, oldLevel)
		self.LevelChanged:Fire(newLevel, oldLevel)
	end)

	Net.OnClientEvent("QuestsUpdated", function(quests)
		self.QuestsChanged:Fire(quests)
	end)

	Net.OnClientEvent("PetsUpdated", function(pets)
		self.PetsChanged:Fire(pets)
	end)

	Net.OnClientEvent("ZoneChanged", function(zoneId, unlocked)
		self.ZoneChanged:Fire(zoneId, unlocked)
	end)
end

--------------------------------------------------------------------------------
-- Acciones (interfaz -> servidor)
--------------------------------------------------------------------------------

function ProgressionController:ClaimQuest(questId: string): boolean
	local ok, result = pcall(function()
		return Net.Invoke("RequestClaimQuest", questId)
	end)
	return ok and result == true
end

function ProgressionController:TogglePet(uid: string): boolean
	local ok, result = pcall(function()
		return Net.Invoke("RequestTogglePet", uid)
	end)
	return ok and result == true
end

function ProgressionController:UnlockZone(zoneId: string): boolean
	local ok, result = pcall(function()
		return Net.Invoke("RequestUnlockZone", zoneId)
	end)
	return ok and result == true
end

--------------------------------------------------------------------------------
-- Lectura local
--------------------------------------------------------------------------------

function ProgressionController:GetLevelProgress(): (number, number, number)
	local level = ClientState:GetLevel()
	local profile = ClientState:Get()
	local experience = if profile then profile.Progression.Experience else 0
	local required = Config.Levels.ExperienceForLevel(level)
	return level, experience, required
end

function ProgressionController:IsZoneUnlocked(zoneId: string): boolean
	local profile = ClientState:Get()
	return profile ~= nil and profile.UnlockedZones[zoneId] == true
end

return ProgressionController
