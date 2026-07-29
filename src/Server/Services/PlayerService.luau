--!nonstrict
--[[
	PlayerService
	----------------------------------------------------------------------------
	Ciclo de vida del jugador en el servidor: leaderstats, tiempo jugado,
	limpieza de estado y punto de entrada para lo que necesite reaccionar a
	entrada/salida y a la aparicion del personaje.

	NOTA: aqui no hay logica de juego. Los sistemas concretos (globos, tiendas,
	mascotas...) se suscriben a las senales de este servicio.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("PlayerService")

local PlayerService = {}
PlayerService.Name = "PlayerService"
PlayerService.Priority = 800

-- Estadisticas mostradas en la tabla de clasificacion de Roblox
local LEADERSTATS = {
	{ Key = "Coins", Path = { "Currencies", "Coins" } },
	{ Key = "Nivel", Path = { "Progression", "Level" } },
}

function PlayerService:Init()
	self._data = nil
	self._playtimeAccumulator = {} :: { [Player]: number }

	-- Senales para el resto de servicios
	self.PlayerReady = Signal.new() -- (player, profile) perfil cargado
	self.PlayerLeaving = Signal.new() -- (player)
	self.CharacterAdded = Signal.new() -- (player, character)
end

function PlayerService:Start()
	self._data = Loader.Get("DataService")

	self._data.ProfileLoaded:Connect(function(player, profile)
		self:_setupLeaderstats(player, profile)
		self.PlayerReady:Fire(player, profile)
	end)

	Players.PlayerAdded:Connect(function(player)
		self:_bindCharacter(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_bindCharacter(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		self.PlayerLeaving:Fire(player)
		Net.ClearPlayer(player)
		self._playtimeAccumulator[player] = nil
	end)

	task.spawn(function()
		self:_playTimeLoop()
	end)

	log:Debug("Ciclo de vida del jugador activo")
end

function PlayerService:_bindCharacter(player: Player)
	player.CharacterAdded:Connect(function(character)
		self.CharacterAdded:Fire(player, character)
	end)

	if player.Character then
		self.CharacterAdded:Fire(player, player.Character)
	end
end

function PlayerService:_setupLeaderstats(player: Player, profile: any)
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	for _, entry in ipairs(LEADERSTATS) do
		local value: any = profile
		for _, key in ipairs(entry.Path) do
			value = value and value[key]
		end

		local stat = Instance.new("NumberValue")
		stat.Name = entry.Key
		stat.Value = tonumber(value) or 0
		stat.Parent = folder
	end

	folder.Parent = player
end

--[[
	Actualiza un valor de leaderstats. Lo llaman CurrencyService y LevelService.
--]]
function PlayerService:UpdateLeaderstat(player: Player, key: string, value: number)
	local folder = player:FindFirstChild("leaderstats")
	local stat = folder and folder:FindFirstChild(key)
	if stat and stat:IsA("NumberValue") then
		stat.Value = value
	end
end

--[[
	Acumula el tiempo de juego en las estadisticas del perfil.
--]]
function PlayerService:_playTimeLoop()
	local interval = 5

	while true do
		task.wait(interval)

		for _, player in ipairs(Players:GetPlayers()) do
			local profile = self._data:GetProfile(player)
			if profile then
				profile.Stats.PlayTime += interval
				self._data:MarkDirty(player)
			end
		end
	end
end

return PlayerService
