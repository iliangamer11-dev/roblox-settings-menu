--!nonstrict
--[[
	SettingsService
	----------------------------------------------------------------------------
	Guarda los ajustes del jugador (musica, efectos, vibracion de camara...).
	Vive en el servidor porque forman parte del perfil persistido.

	Solo acepta claves que existan en la plantilla, asi que un cliente
	malicioso no puede inflar el perfil con datos arbitrarios.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local ProfileTemplate = require(Shared.Data.ProfileTemplate)

local log = Logger.new("SettingsService")

local SettingsService = {}
SettingsService.Name = "SettingsService"
SettingsService.Priority = 200

function SettingsService:Init()
	self._data = nil
	self._allowed = {}

	for key, value in pairs(ProfileTemplate.Raw.Settings) do
		self._allowed[key] = type(value)
	end
end

function SettingsService:Start()
	self._data = Loader.Get("DataService")

	Net.OnEvent("UpdateSetting", function(player, key, value)
		self:Set(player, key, value)
	end)

	log:Debug("Ajustes del jugador listos")
end

function SettingsService:Set(player: Player, key: any, value: any): boolean
	local expectedType = type(key) == "string" and self._allowed[key]
	if not expectedType then
		return false
	end
	if type(value) ~= expectedType then
		return false
	end

	local profile = self._data:GetProfile(player)
	if not profile then
		return false
	end

	profile.Settings[key] = value
	self._data:MarkDirty(player)

	return true
end

return SettingsService
