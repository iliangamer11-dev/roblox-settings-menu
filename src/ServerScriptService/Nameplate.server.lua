--[[
	Nameplate (Script en ServerScriptService)

	Cartel sobre la cabeza de cada jugador:
	  - arriba, el nombre en blanco con contorno negro
	  - abajo, "Level X" con degradado de azul claro a azul oscuro y contorno negro

	Se crea en el servidor a proposito: asi todos los jugadores ven la placa de todos.
	El nivel se lee del atributo que publica LevelService, y se actualiza solo cuando
	el jugador sube de nivel.

	Ajustes en MiningConfig.NAMEPLATE.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))

local cfg = Config.NAMEPLATE

if not cfg.ENABLED then
	return
end

-- Los tags, para poder pintar el equipado con sus colores
local tagByKey = {}
for _, tag in Config.TAGS do
	tagByKey[tag.KEY] = tag
end

local function addOutline(parent: Instance)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = cfg.OUTLINE_THICKNESS
	stroke.Color = cfg.OUTLINE_COLOR
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

local function buildNameplate(player: Player, character: Model)
	local head = character:WaitForChild("Head", 10)
	if not head then
		return
	end

	-- Si se respawnea rapido puede quedar el anterior
	local previous = head:FindFirstChild("Nameplate")
	if previous then
		previous:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Nameplate"
	billboard.Size = cfg.SIZE
	billboard.StudsOffsetWorldSpace = cfg.OFFSET
	billboard.MaxDistance = cfg.MAX_DISTANCE
	billboard.AlwaysOnTop = cfg.ALWAYS_ON_TOP
	billboard.LightInfluence = 0
	billboard.Parent = head

	-- Nombre: blanco con contorno negro
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.fromScale(1, cfg.NAME_HEIGHT)
	nameLabel.Position = UDim2.fromScale(0, 0)
	nameLabel.Font = cfg.FONT
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = cfg.NAME_COLOR
	nameLabel.Text = cfg.USE_DISPLAY_NAME and player.DisplayName or player.Name
	nameLabel.Parent = billboard
	addOutline(nameLabel)

	-- Con VIP equipado el nombre sale como "[VIP] Nombre"
	local baseName = nameLabel.Text

	-- Nivel: degradado azul claro -> azul oscuro, con contorno negro
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "PlayerLevel"
	levelLabel.BackgroundTransparency = 1
	levelLabel.Size = UDim2.fromScale(1, 1 - cfg.NAME_HEIGHT)
	levelLabel.Position = UDim2.fromScale(0, cfg.NAME_HEIGHT)
	levelLabel.Font = cfg.FONT
	levelLabel.TextScaled = true
	levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- el color real lo pone el degradado
	levelLabel.Text = string.format(cfg.LEVEL_FORMAT, player:GetAttribute("level") or 1)
	levelLabel.Parent = billboard
	addOutline(levelLabel)

	-- Rotation 90 = de arriba a abajo
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, cfg.LEVEL_GRADIENT_TOP),
		ColorSequenceKeypoint.new(1, cfg.LEVEL_GRADIENT_BOTTOM),
	})
	gradient.Parent = levelLabel

	-- Tag encima del nombre (Noob, Principiante, Pro, VIP...) con su degradado
	local tagLabel = Instance.new("TextLabel")
	tagLabel.Name = "Tag"
	tagLabel.BackgroundTransparency = 1
	tagLabel.Size = UDim2.fromScale(1, cfg.NAME_HEIGHT * 0.62)
	tagLabel.Position = UDim2.fromScale(0, -cfg.NAME_HEIGHT * 0.62)
	tagLabel.Font = cfg.FONT
	tagLabel.TextScaled = true
	tagLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- el color real lo pone el degradado
	tagLabel.Parent = billboard
	addOutline(tagLabel)

	-- El degradado se reutiliza y solo se le cambian los colores al cambiar de tag
	local tagGradient = Instance.new("UIGradient")
	tagGradient.Rotation = 90
	tagGradient.Parent = tagLabel

	-- El nombre por defecto de Roblox se quita para que no salga duplicado
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and cfg.HIDE_DEFAULT_NAME then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	-- Pinta el tag equipado: texto, colores del degradado y el prefijo del nombre
	local function refreshTag()
		local key = player:GetAttribute("tag")
		local tag = key and tagByKey[key]

		if not tag then
			tagLabel.Visible = false
			nameLabel.Text = baseName
			return
		end

		tagLabel.Visible = true
		tagLabel.Text = tag.LABEL
		tagGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, tag.TOP),
			ColorSequenceKeypoint.new(1, tag.BOTTOM),
		})

		if tag.KEY == "VIP" then
			nameLabel.Text = Config.PASS_EFFECTS.VIP_NAME_PREFIX .. baseName
		else
			nameLabel.Text = baseName
		end
	end

	refreshTag()
	player:GetAttributeChangedSignal("tag"):Connect(refreshTag)

	return levelLabel
end

local function onPlayerAdded(player: Player)
	local levelLabel: TextLabel? = nil

	local function refresh()
		if levelLabel and levelLabel.Parent then
			levelLabel.Text = string.format(cfg.LEVEL_FORMAT, player:GetAttribute("level") or 1)
		end
	end

	player:GetAttributeChangedSignal("level"):Connect(refresh)

	local function onCharacterAdded(character: Model)
		levelLabel = buildNameplate(player, character)
	end

	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
