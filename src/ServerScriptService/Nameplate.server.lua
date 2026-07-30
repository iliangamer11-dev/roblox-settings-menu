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

	-- Fila del nombre: [Tag] y nombre en la misma linea, centrados como un bloque.
	-- Se usa UIListLayout con ancho automatico para que el conjunto quede centrado
	-- sea corto o largo el nombre.
	local nameRow = Instance.new("Frame")
	nameRow.Name = "NameRow"
	nameRow.BackgroundTransparency = 1
	nameRow.Size = UDim2.fromScale(1, cfg.NAME_HEIGHT)
	nameRow.Position = UDim2.fromScale(0, 0)
	nameRow.Parent = billboard

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, cfg.TAG_PREFIX_PADDING)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = nameRow

	-- [Tag] con su degradado, delante del nombre
	local prefixLabel = Instance.new("TextLabel")
	prefixLabel.Name = "TagPrefix"
	prefixLabel.LayoutOrder = 1
	prefixLabel.BackgroundTransparency = 1
	prefixLabel.AutomaticSize = Enum.AutomaticSize.X
	prefixLabel.Size = UDim2.fromOffset(0, cfg.NAME_TEXT_SIZE + 6)
	prefixLabel.Font = cfg.FONT
	prefixLabel.TextSize = cfg.NAME_TEXT_SIZE
	prefixLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- el color real lo pone el degradado
	prefixLabel.Text = ""
	prefixLabel.Visible = false
	prefixLabel.Parent = nameRow
	addOutline(prefixLabel)

	local prefixGradient = Instance.new("UIGradient")
	prefixGradient.Rotation = 90
	prefixGradient.Parent = prefixLabel

	-- Nombre: blanco con contorno negro
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.LayoutOrder = 2
	nameLabel.BackgroundTransparency = 1
	nameLabel.AutomaticSize = Enum.AutomaticSize.X
	nameLabel.Size = UDim2.fromOffset(0, cfg.NAME_TEXT_SIZE + 6)
	nameLabel.Font = cfg.FONT
	nameLabel.TextSize = cfg.NAME_TEXT_SIZE
	nameLabel.TextColor3 = cfg.NAME_COLOR
	nameLabel.Text = cfg.USE_DISPLAY_NAME and player.DisplayName or player.Name
	nameLabel.Parent = nameRow
	addOutline(nameLabel)

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

	-- Pinta el tag equipado: el [Tag] al lado del nombre y el suelto de encima,
	-- los dos con el degradado de ese tag
	local function refreshTag()
		local key = player:GetAttribute("tag")
		local tag = key and tagByKey[key]

		if not tag then
			tagLabel.Visible = false
			prefixLabel.Visible = false
			return
		end

		local colors = ColorSequence.new({
			ColorSequenceKeypoint.new(0, tag.TOP),
			ColorSequenceKeypoint.new(1, tag.BOTTOM),
		})

		-- Al lado del nombre
		prefixLabel.Visible = true
		prefixLabel.Text = string.format(cfg.TAG_PREFIX_FORMAT, tag.LABEL)
		prefixGradient.Color = colors

		-- Encima del nombre (opcional)
		tagLabel.Visible = cfg.SHOW_TAG_ABOVE
		tagLabel.Text = tag.LABEL
		tagGradient.Color = colors
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
