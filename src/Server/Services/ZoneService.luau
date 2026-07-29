--!nonstrict
--[[
	ZoneService
	----------------------------------------------------------------------------
	ESQUELETO. Zonas del mapa: desbloqueo, teletransporte y seguimiento de en
	que zona esta cada jugador.

	PREPARADO PARA: nuevas zonas.
	Anadir una zona sera solo: modelo en Workspace.World.Zones + entrada en
	ZoneConfig.Zones. Este servicio no necesitara cambios.

	API
		ZoneService:IsUnlocked(player, zoneId) -> boolean
		ZoneService:Unlock(player, zoneId)     -> boolean, string?
		ZoneService:GetCurrent(player)         -> zoneId
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("ZoneService")

local ZoneService = {}
ZoneService.Name = "ZoneService"
ZoneService.Priority = 300

function ZoneService:Init()
	self._data = nil
	self._currency = nil
	self._levels = nil
	self._stats = nil

	-- Player -> zoneId
	self._current = {} :: { [Player]: string }

	self.ZoneUnlocked = Signal.new() -- (player, zoneId)
	self.ZoneEntered = Signal.new() -- (player, zoneId)
end

function ZoneService:Start()
	self._data = Loader.Get("DataService")
	self._currency = Loader.Get("CurrencyService")
	self._levels = Loader.Get("LevelService")
	self._stats = Loader.Get("StatsService")

	self._container = self:_ensureContainer()

	Net.OnInvoke("RequestUnlockZone", function(player, zoneId)
		if type(zoneId) ~= "string" then
			return false, "bad-request"
		end
		return self:Unlock(player, zoneId)
	end)

	local players = Loader.Get("PlayerService")
	players.PlayerReady:Connect(function(player)
		self._current[player] = Config.Zones.DefaultZoneId
	end)
	players.PlayerLeaving:Connect(function(player)
		self._current[player] = nil
	end)

	log:Debug("Sistema de zonas preparado (%d definidas)", self:_zoneCount())
end

function ZoneService:_zoneCount(): number
	local count = 0
	for _ in pairs(Config.Zones.Zones) do
		count += 1
	end
	return count
end

function ZoneService:_ensureContainer(): Folder
	local world = Workspace:FindFirstChild(Config.Game.Containers.World)
	if not world then
		world = Instance.new("Folder")
		world.Name = Config.Game.Containers.World
		world.Parent = Workspace
	end

	local zones = world:FindFirstChild(Config.Game.Containers.Zones)
	if not zones then
		zones = Instance.new("Folder")
		zones.Name = Config.Game.Containers.Zones
		zones.Parent = world
	end

	return zones
end

function ZoneService:GetCurrent(player: Player): string
	return self._current[player] or Config.Zones.DefaultZoneId
end

function ZoneService:IsUnlocked(player: Player, zoneId: string): boolean
	local profile = self._data:GetProfile(player)
	return profile ~= nil and profile.UnlockedZones[zoneId] == true
end

--[[
	Desbloquea una zona cobrando su precio.
	Motivos de fallo: "no-zone" | "already" | "level" | "no-funds"
--]]
function ZoneService:Unlock(player: Player, zoneId: string): (boolean, string?)
	local definition = Config.Zones.Zones[zoneId]
	if not definition then
		return false, "no-zone"
	end
	if self:IsUnlocked(player, zoneId) then
		return false, "already"
	end
	if self._levels:GetLevel(player) < definition.RequiredLevel then
		return false, "level"
	end
	if not self._currency:TrySpend(player, definition.UnlockCurrency, definition.UnlockPrice) then
		return false, "no-funds"
	end

	local profile = self._data:GetProfile(player)
	profile.UnlockedZones[zoneId] = true

	self._data:MarkDirty(player)
	self._stats:Increment(player, "ZonesUnlocked", 1)
	Net.FireClient("ZoneChanged", player, zoneId, true)
	self.ZoneUnlocked:Fire(player, zoneId)

	return true
end

--[[
	TODO: deteccion de entrada en zona (Region3/Zone parts) y teletransporte.
--]]
function ZoneService:SetCurrent(player: Player, zoneId: string)
	if not Config.Zones.Zones[zoneId] then
		return
	end
	self._current[player] = zoneId
	Net.FireClient("ZoneChanged", player, zoneId, false)
	self.ZoneEntered:Fire(player, zoneId)
end

return ZoneService
