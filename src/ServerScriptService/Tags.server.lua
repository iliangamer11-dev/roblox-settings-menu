--[[
	Tags (Script en ServerScriptService)

	Etiqueta que sale sobre el personaje. Se desbloquean segun el progreso:
	  Noob         -> lo tiene todo el mundo
	  Principiante -> al comprar Pared2
	  Pro          -> al comprar Pared4
	  VIP          -> con el gamepass VIP

	El servidor decide que tags tiene cada uno y cual lleva puesto. El cliente solo pide
	el cambio, y se comprueba que lo tenga desbloqueado antes de aplicarlo.

	Atributos que publica en el jugador:
		tag           -> KEY del tag equipado (lo lee la placa del personaje)
		tagsUnlocked  -> lista de KEYs separadas por comas, para el menu de tags

	Configuracion en MiningConfig.TAGS.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local Passes = require(script.Parent:WaitForChild("Passes"))

--------------------------------------------------------------------------------
-- Remote
--------------------------------------------------------------------------------

local tagRemote = ReplicatedStorage:FindFirstChild(Config.TAG_REMOTE_NAME)
if not tagRemote or not tagRemote:IsA("RemoteEvent") then
	tagRemote = Instance.new("RemoteEvent")
	tagRemote.Name = Config.TAG_REMOTE_NAME
	tagRemote.Parent = ReplicatedStorage
end

--------------------------------------------------------------------------------
-- Datos
--------------------------------------------------------------------------------

local tagByKey = {}
local defaultKey = nil

for _, tag in Config.TAGS do
	tagByKey[tag.KEY] = tag
	if tag.DEFAULT and not defaultKey then
		defaultKey = tag.KEY
	end
end

defaultKey = defaultKey or Config.TAGS[1].KEY

-- WallShop publica "ownsParedX" en el jugador cuando compra una pared
local function ownsWall(player: Player, wallName: string): boolean
	return player:GetAttribute("owns" .. wallName) == true
end

local function isUnlocked(player: Player, tag): boolean
	if tag.DEFAULT then
		return true
	end
	if tag.WALL then
		return ownsWall(player, tag.WALL)
	end
	if tag.PASS then
		return Passes.has(player, tag.PASS)
	end
	return false
end

local function unlockedKeys(player: Player): { string }
	local keys = {}
	for _, tag in Config.TAGS do
		if isUnlocked(player, tag) then
			table.insert(keys, tag.KEY)
		end
	end
	return keys
end

-- Columna [Tag] de la lista de jugadores
local function refreshLeaderstat(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local entry = leaderstats and leaderstats:FindFirstChild(Config.LEADERSTATS_TAG_NAME)
	if not entry or not entry:IsA("StringValue") then
		return
	end

	local tag = tagByKey[player:GetAttribute("tag")]
	entry.Value = tag and ("[" .. tag.LABEL .. "]") or ""
end

local function publish(player: Player)
	local keys = unlockedKeys(player)
	player:SetAttribute("tagsUnlocked", table.concat(keys, ","))

	-- Si lleva puesto uno que ya no tiene (o ninguno), se le pone el que toque
	local current = player:GetAttribute("tag")
	local tag = current and tagByKey[current]

	if not tag or not isUnlocked(player, tag) then
		player:SetAttribute("tag", defaultKey)
	end

	refreshLeaderstat(player)
end

-- Al desbloquear uno nuevo se equipa solo, que es lo que uno espera
local function onUnlock(player: Player, key: string)
	local tag = tagByKey[key]
	if not tag or not isUnlocked(player, tag) then
		return
	end

	player:SetAttribute("tag", key)
	publish(player)

	if Config.DEBUG then
		print(string.format("[Tags] %s desbloqueo %s", player.Name, tag.LABEL))
	end
end

--------------------------------------------------------------------------------
-- Jugadores
--------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	player:SetAttribute("tag", player:GetAttribute("tag") or defaultKey)
	publish(player)

	-- Cada tag escucha su propia condicion
	for _, tag in Config.TAGS do
		if tag.WALL then
			player:GetAttributeChangedSignal("owns" .. tag.WALL):Connect(function()
				if ownsWall(player, tag.WALL) then
					onUnlock(player, tag.KEY)
				end
			end)
		end
	end

	-- La leaderstats puede tardar un instante en existir
	task.delay(1, refreshLeaderstat, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- Gamepasses (VIP): al entrar y al comprarlo
Passes.Changed.Event:Connect(function(player: Player)
	for _, tag in Config.TAGS do
		if tag.PASS and Passes.has(player, tag.PASS) then
			local unlocked = player:GetAttribute("tagsUnlocked") or ""
			-- Solo se autoequipa la primera vez
			if not string.find(unlocked, tag.KEY, 1, true) then
				onUnlock(player, tag.KEY)
			end
		end
	end

	publish(player)
end)

--------------------------------------------------------------------------------
-- Cambio de tag desde el menu
--------------------------------------------------------------------------------

tagRemote.OnServerEvent:Connect(function(player: Player, key: any)
	if typeof(key) ~= "string" then
		return
	end

	local tag = tagByKey[key]
	if not tag then
		return
	end

	-- Solo se puede equipar lo que se tiene: la comprobacion es del servidor
	if not isUnlocked(player, tag) then
		return
	end

	player:SetAttribute("tag", key)
	refreshLeaderstat(player)
end)
