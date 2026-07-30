--[[
	Skins (Script en ServerScriptService)

	Skins del pico. Se desbloquean comprando paredes:
	  Wooden  -> la tiene todo el mundo
	  Nature  -> Pared1
	  Golden  -> Pared2
	  Diamond -> Pared3
	  Cosmic  -> Pared4

	Al desbloquear una NO se equipa sola: solo se anade a la lista y el cliente muestra
	el aviso. Se equipa desde el boton SKINS.

	El servidor pinta el pico y valida los cambios. Atributos que publica:
		skin          -> KEY de la skin equipada
		skinsUnlocked -> KEYs desbloqueadas separadas por comas

	Configuracion en MiningConfig.SKINS.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))

--------------------------------------------------------------------------------
-- Remote
--------------------------------------------------------------------------------

local skinRemote = ReplicatedStorage:FindFirstChild(Config.SKIN_REMOTE_NAME)
if not skinRemote or not skinRemote:IsA("RemoteEvent") then
	skinRemote = Instance.new("RemoteEvent")
	skinRemote.Name = Config.SKIN_REMOTE_NAME
	skinRemote.Parent = ReplicatedStorage
end

--------------------------------------------------------------------------------
-- Datos
--------------------------------------------------------------------------------

local skinByKey = {}
local defaultKey = nil

for _, skin in Config.SKINS do
	skinByKey[skin.KEY] = skin
	if skin.DEFAULT and not defaultKey then
		defaultKey = skin.KEY
	end
end

defaultKey = defaultKey or Config.SKINS[1].KEY

-- WallShop publica "ownsParedX" cuando se compra una pared
local function isUnlocked(player: Player, skin): boolean
	if skin.DEFAULT then
		return true
	end
	if skin.WALL then
		return player:GetAttribute("owns" .. skin.WALL) == true
	end
	return false
end

--------------------------------------------------------------------------------
-- Pintar el pico
--------------------------------------------------------------------------------

-- El pico se construye en PickaxeTool: el mango se llama "Handle" y el resto de piezas
-- (collar y puntas) son la cabeza.
local function paintTool(tool: Tool, skin)
	for _, part in tool:GetDescendants() do
		if part:IsA("BasePart") then
			if part.Name == "Handle" then
				part.Color = skin.HANDLE_COLOR
				part.Material = skin.HANDLE_MATERIAL
			else
				part.Color = skin.HEAD_COLOR
				part.Material = skin.HEAD_MATERIAL
			end
		end
	end
end

local function findTool(player: Player): Tool?
	local character = player.Character
	local tool = character and character:FindFirstChild(Config.TOOL_NAME)

	if not tool then
		local backpack = player:FindFirstChildOfClass("Backpack")
		tool = backpack and backpack:FindFirstChild(Config.TOOL_NAME)
	end

	return (tool and tool:IsA("Tool")) and tool or nil
end

local function applySkin(player: Player)
	local skin = skinByKey[player:GetAttribute("skin")] or skinByKey[defaultKey]
	local tool = findTool(player)

	if skin and tool then
		paintTool(tool, skin)
	end
end

--------------------------------------------------------------------------------
-- Estado
--------------------------------------------------------------------------------

local function publish(player: Player)
	local keys = {}
	for _, skin in Config.SKINS do
		if isUnlocked(player, skin) then
			table.insert(keys, skin.KEY)
		end
	end

	player:SetAttribute("skinsUnlocked", table.concat(keys, ","))

	-- Si lleva una que ya no tiene (o ninguna), se le pone la de siempre
	local current = player:GetAttribute("skin")
	local skin = current and skinByKey[current]

	if not skin or not isUnlocked(player, skin) then
		player:SetAttribute("skin", defaultKey)
	end
end

local function onPlayerAdded(player: Player)
	player:SetAttribute("skin", player:GetAttribute("skin") or defaultKey)
	publish(player)

	-- Cada skin escucha su pared
	for _, skin in Config.SKINS do
		if skin.WALL then
			player:GetAttributeChangedSignal("owns" .. skin.WALL):Connect(function()
				-- Solo se anade a la lista: la equipa el jugador desde el menu
				publish(player)

				if Config.DEBUG then
					print(string.format("[Skins] %s desbloqueo %s (sin equipar)", player.Name, skin.LABEL))
				end
			end)
		end
	end

	player:GetAttributeChangedSignal("skin"):Connect(function()
		applySkin(player)
	end)

	-- Al reaparecer, el pico es nuevo y hay que volver a pintarlo
	player.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(function(child)
			if child.Name == Config.TOOL_NAME then
				task.defer(applySkin, player)
			end
		end)

		task.delay(1, applySkin, player)
	end)

	task.delay(1.2, applySkin, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

--------------------------------------------------------------------------------
-- Cambio desde el menu
--------------------------------------------------------------------------------

skinRemote.OnServerEvent:Connect(function(player: Player, key: any)
	if typeof(key) ~= "string" then
		return
	end

	local skin = skinByKey[key]
	if not skin then
		return
	end

	-- Solo se puede equipar lo desbloqueado: lo comprueba el servidor
	if not isUnlocked(player, skin) then
		return
	end

	player:SetAttribute("skin", key)
end)
