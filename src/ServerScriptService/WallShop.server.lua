--[[
	WallShop (Script en ServerScriptService)

	Pone un boton (ProximityPrompt) en las parts Pared1..Pared4. Al comprarla se cobra
	el dinero y se avisa SOLO a ese jugador para que la pared desaparezca para el.
	Los demas siguen viendo su pared.

	Precios en MiningConfig.WALLS. Los textos del boton, en ingles, en WALL_PROMPT.

	El dinero se comprueba y se cobra siempre en el servidor: el cliente solo avisa de
	que ha pulsado el boton.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local Minerals = require(script.Parent:WaitForChild("Minerals"))
local Passes = require(script.Parent:WaitForChild("Passes"))

--------------------------------------------------------------------------------
-- Remote
--------------------------------------------------------------------------------

local wallRemote = ReplicatedStorage:FindFirstChild(Config.WALL_REMOTE_NAME)
if not wallRemote or not wallRemote:IsA("RemoteEvent") then
	wallRemote = Instance.new("RemoteEvent")
	wallRemote.Name = Config.WALL_REMOTE_NAME
	wallRemote.Parent = ReplicatedStorage
end

--------------------------------------------------------------------------------
-- Datos de las paredes
--------------------------------------------------------------------------------

local wallByName = {}
for _, wall in Config.WALLS do
	wallByName[wall.NAME] = wall
end

-- owned[player] = { Pared1 = true, ... }
local owned = {}

local function getMoneyValue(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	return leaderstats:FindFirstChild(Config.MONEY_NAME)
end

--------------------------------------------------------------------------------
-- Compra
--------------------------------------------------------------------------------

-- Gamepass All Zones: se le abren todas sin cobrar nada
local function unlockAll(player: Player)
	local playerWalls = owned[player]
	if not playerWalls then
		return
	end

	for wallName in wallByName do
		playerWalls[wallName] = true
		wallRemote:FireClient(player, "unlocked", wallName)
	end

	if Config.DEBUG then
		print(string.format("[WallShop] %s tiene All Zones: paredes abiertas", player.Name))
	end
end

local function attemptPurchase(player: Player, wallName: string)
	local wall = wallByName[wallName]
	if not wall then
		return
	end

	local playerWalls = owned[player]
	if not playerWalls then
		return
	end

	-- Con el gamepass All Zones no se cobra
	if Passes.has(player, "ALL_ZONES") then
		unlockAll(player)
		return
	end

	-- Ya la tiene: nada que cobrar, se le vuelve a avisar por si respawneo
	if playerWalls[wallName] then
		wallRemote:FireClient(player, "unlocked", wallName)
		return
	end

	local moneyValue = getMoneyValue(player)
	if not moneyValue then
		return
	end

	if moneyValue.Value < wall.PRICE then
		local missing = wall.PRICE - moneyValue.Value
		wallRemote:FireClient(player, "failed", wallName, Minerals.format(missing))
		return
	end

	moneyValue.Value -= wall.PRICE
	playerWalls[wallName] = true

	wallRemote:FireClient(player, "unlocked", wallName)

	if Config.DEBUG then
		print(
			string.format(
				"[WallShop] %s compro %s por %s (le queda %s)",
				player.Name,
				wallName,
				Minerals.format(wall.PRICE),
				Minerals.format(moneyValue.Value)
			)
		)
	end
end

--------------------------------------------------------------------------------
-- Botones
--------------------------------------------------------------------------------

local promptSettings = Config.WALL_PROMPT

-- El prompt tiene que vivir en una BasePart o en un Attachment.
-- Asi funciona igual si Pared1 es una Part sola o un Model con partes dentro.
local function findHost(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") and instance.PrimaryPart then
		return instance.PrimaryPart
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function setupWall(instance: Instance)
	local wall = wallByName[instance.Name]
	if not wall then
		return
	end

	local host = findHost(instance)
	if not host then
		warn(string.format("[WallShop] %s no tiene ninguna Part dentro, no se le puede poner el boton", instance.Name))
		return
	end

	if host:FindFirstChild("BuyPrompt") then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = string.format(promptSettings.ACTION_TEXT, Minerals.format(wall.PRICE))
	prompt.ObjectText = string.format(promptSettings.OBJECT_TEXT, wall.TITLE)
	prompt.HoldDuration = promptSettings.HOLD_DURATION
	prompt.MaxActivationDistance = promptSettings.MAX_DISTANCE
	prompt.RequiresLineOfSight = promptSettings.REQUIRES_LINE_OF_SIGHT
	prompt.KeyboardKeyCode = promptSettings.KEY
	prompt.Parent = host

	prompt.Triggered:Connect(function(player)
		attemptPurchase(player, instance.Name)
	end)
end

for _, descendant in workspace:GetDescendants() do
	setupWall(descendant)
end

workspace.DescendantAdded:Connect(setupWall)

--------------------------------------------------------------------------------
-- Jugadores
--------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	owned[player] = {}

	-- Al respawnear se le recuerdan las paredes que ya compro, porque la pared
	-- solo esta oculta en su cliente y conviene volver a aplicarlo
	player.CharacterAdded:Connect(function()
		task.wait(1)
		local playerWalls = owned[player]
		if not playerWalls then
			return
		end
		for wallName in playerWalls do
			wallRemote:FireClient(player, "unlocked", wallName)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

-- Cuando se sabe (o se compra) que tiene All Zones, se le abren todas
Passes.Changed.Event:Connect(function(player: Player)
	if Passes.has(player, "ALL_ZONES") then
		unlockAll(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	owned[player] = nil
end)
