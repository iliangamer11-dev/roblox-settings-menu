--[[
	TagsMenu (LocalScript en StarterPlayer > StarterPlayerScripts)

	Boton TAGS y su panel: salen todos los tags, con su degradado, y se equipa el que
	quieras. Los que no tienes salen atenuados con el requisito.

	El servidor (Tags) publica dos atributos que este menu solo lee:
		tagsUnlocked -> los que tiene desbloqueados
		tag          -> el que lleva puesto

	Al pulsar EQUIP solo se pide el cambio: el servidor comprueba que lo tengas.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))

local buttonCfg = Config.TAG_BUTTON
local panelCfg = Config.TAG_PANEL
local theme = Config.UI_THEME

if not buttonCfg.ENABLED then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local tagRemote = ReplicatedStorage:WaitForChild(Config.TAG_REMOTE_NAME)

-- Titulos de las paredes, para escribir el requisito ("Buy Mine Zone")
local wallTitles = {}
for _, wall in Config.WALLS do
	wallTitles[wall.NAME] = wall.TITLE
end

local tagByKey = {}
for _, tag in Config.TAGS do
	tagByKey[tag.KEY] = tag
end

--------------------------------------------------------------------------------
-- Boton
--------------------------------------------------------------------------------

local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "TagsButtonGui"
buttonGui.ResetOnSpawn = false
buttonGui.IgnoreGuiInset = true
buttonGui.Parent = playerGui

local buttonRoot = UiTheme.root(buttonGui)

local icon = UiTheme.hudButton(buttonRoot, buttonCfg.SLOT, buttonCfg.ICON_ID, buttonCfg.LABEL)

--------------------------------------------------------------------------------
-- Panel
--------------------------------------------------------------------------------

local panelGui = Instance.new("ScreenGui")
panelGui.Name = "TagsPanelGui"
panelGui.ResetOnSpawn = false
panelGui.IgnoreGuiInset = true
panelGui.Enabled = false
panelGui.Parent = playerGui

local panelRoot = UiTheme.root(panelGui)

local panelOuter, panel = UiTheme.framedBox(panelRoot, panelCfg.SIZE, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))

-- Abre y cierra con animacion, y cierra los demas paneles
local panelWindow = UiTheme.panel(panelGui, panelOuter)

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, -24, 0, 52)
header.Position = UDim2.new(0, 12, 0, 12)
header.BackgroundColor3 = theme.BUTTON_COLOR
header.BackgroundTransparency = 0.1
header.BorderSizePixel = 0
header.Parent = panel
UiTheme.corner(header, theme.CORNER_RADIUS)
UiTheme.stroke(header, theme.OUTER_OUTLINE, 2)

local headerIcon = Instance.new("ImageLabel")
headerIcon.Name = "Icon"
headerIcon.BackgroundTransparency = 1
headerIcon.AnchorPoint = Vector2.new(0, 0.5)
headerIcon.Position = UDim2.new(0, 10, 0.5, 0)
headerIcon.Size = UDim2.fromOffset(36, 36)
headerIcon.ScaleType = Enum.ScaleType.Fit
headerIcon.Image = UiTheme.assetId(panelCfg.TITLE_ICON_ID)
headerIcon.Parent = header

local titleLabel = UiTheme.text(header, panelCfg.TITLE, UDim2.new(1, -160, 0.66, 0), UDim2.new(0, 56, 0.5, 0))
titleLabel.Name = "Title"
titleLabel.AnchorPoint = Vector2.new(0, 0.5)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = UiTheme.button(header, "X", UDim2.fromOffset(38, 38), UDim2.new(1, -8, 0.5, 0), Vector2.new(1, 0.5))
closeButton.Name = "Close"
closeButton.BackgroundColor3 = theme.OFF_COLOR

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Position = UDim2.new(0, 12, 0, 74)
scroll.Size = UDim2.new(1, -24, 1, -86)
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 8
scroll.ScrollBarImageColor3 = theme.OUTER_OUTLINE
scroll.ScrollBarImageTransparency = 0.3
scroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, panelCfg.ROW_PADDING)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingBottom = UDim.new(0, panelCfg.EXTRA_SCROLL)
padding.Parent = scroll

--------------------------------------------------------------------------------
-- Filas
--------------------------------------------------------------------------------

local rows = {} -- rows[KEY] = { button = TextButton, requirement = TextLabel }

local function requirementText(tag): string
	if tag.WALL then
		return string.format(panelCfg.WALL_REQUIREMENT, wallTitles[tag.WALL] or tag.WALL)
	end
	if tag.PASS then
		return panelCfg.PASS_REQUIREMENT
	end
	return ""
end

for index, tag in Config.TAGS do
	local row = Instance.new("Frame")
	row.Name = tag.KEY
	row.LayoutOrder = index
	row.Size = UDim2.new(1, 0, 0, panelCfg.ROW_HEIGHT)
	row.BackgroundColor3 = theme.BUTTON_COLOR
	row.BackgroundTransparency = 0.15
	row.BorderSizePixel = 0
	row.Parent = scroll
	UiTheme.corner(row, theme.CORNER_RADIUS)
	UiTheme.stroke(row, theme.OUTER_OUTLINE, 2)

	-- El nombre del tag, con su degradado
	local nameLabel = UiTheme.text(row, tag.LABEL, UDim2.new(0.45, 0, 0.44, 0), UDim2.new(0, 14, 0.1, 0))
	nameLabel.Name = "TagName"
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	UiTheme.gradient(nameLabel, tag.TOP, tag.BOTTOM)

	-- Cuanto dinero extra da este tag
	local multiplierLabel = UiTheme.text(
		row,
		string.format(panelCfg.MULTIPLIER_FORMAT, tostring(tag.MULTIPLIER or 1)),
		UDim2.new(0.4, 0, 0.3, 0),
		UDim2.new(0, 14, 0.56, 0)
	)
	multiplierLabel.Name = "Multiplier"
	multiplierLabel.TextXAlignment = Enum.TextXAlignment.Left
	multiplierLabel.TextColor3 = theme.ON_COLOR

	local requirement =
		UiTheme.text(row, requirementText(tag), UDim2.new(0.32, 0, 0.28, 0), UDim2.new(1, -178, 0.6, 0))
	requirement.Name = "Requirement"
	requirement.AnchorPoint = Vector2.new(1, 0)
	requirement.TextXAlignment = Enum.TextXAlignment.Right
	requirement.TextScaled = false
	requirement.TextSize = 14

	local equipButton =
		UiTheme.button(row, panelCfg.EQUIP_TEXT, UDim2.fromOffset(150, 42), UDim2.new(1, -14, 0.5, 0), Vector2.new(1, 0.5))
	equipButton.Name = "Equip"

	equipButton.Activated:Connect(function()
		tagRemote:FireServer(tag.KEY)
	end)

	rows[tag.KEY] = { button = equipButton, requirement = requirement }
end

--------------------------------------------------------------------------------
-- Estado
--------------------------------------------------------------------------------

local function refresh()
	local unlockedList = player:GetAttribute("tagsUnlocked") or ""
	local equipped = player:GetAttribute("tag")

	local unlocked = {}
	for key in string.gmatch(unlockedList, "[^,]+") do
		unlocked[key] = true
	end

	for _, tag in Config.TAGS do
		local row = rows[tag.KEY]
		if row then
			local has = unlocked[tag.KEY] == true

			if not has then
				row.button.Text = panelCfg.LOCKED_TEXT
				row.button.BackgroundColor3 = theme.OFF_COLOR
				row.button.AutoButtonColor = false
				row.requirement.Visible = true
			elseif tag.KEY == equipped then
				row.button.Text = panelCfg.EQUIPPED_TEXT
				row.button.BackgroundColor3 = theme.ON_COLOR
				row.button.AutoButtonColor = false
				row.requirement.Visible = false
			else
				row.button.Text = panelCfg.EQUIP_TEXT
				row.button.BackgroundColor3 = theme.BUTTON_COLOR
				row.button.AutoButtonColor = true
				row.requirement.Visible = false
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Aviso de tag nuevo (no se equipa solo)
--------------------------------------------------------------------------------

local noticeGui = Instance.new("ScreenGui")
noticeGui.Name = "TagUnlockGui"
noticeGui.ResetOnSpawn = false
noticeGui.IgnoreGuiInset = true
noticeGui.Enabled = false
noticeGui.Parent = playerGui

local noticeRoot = UiTheme.root(noticeGui)

local noticeOuter, noticeBody =
	UiTheme.framedBox(noticeRoot, panelCfg.UNLOCK_SIZE, panelCfg.UNLOCK_POSITION, Vector2.new(0.5, 0))

-- exclusive = false: el aviso no cierra los paneles ni se cierra cuando abres uno
local noticeWindow = UiTheme.panel(noticeGui, noticeOuter, { exclusive = false })

local noticeTitle = UiTheme.text(noticeBody, "", UDim2.new(1, -16, 0.5, 0), UDim2.new(0, 8, 0, 6))
noticeTitle.Name = "Message"

local noticeHint = UiTheme.text(noticeBody, panelCfg.UNLOCK_HINT, UDim2.new(1, -16, 0.3, 0), UDim2.new(0, 8, 0.6, 0))
noticeHint.Name = "Hint"
noticeHint.TextScaled = false
noticeHint.TextSize = 16

local noticeToken = 0

local function showUnlockNotice(tag)
	noticeTitle.Text = string.format(panelCfg.UNLOCK_MESSAGE, tag.LABEL)
	UiTheme.gradient(noticeTitle, tag.TOP, tag.BOTTOM)
	noticeWindow.open()

	noticeToken += 1
	local token = noticeToken

	task.delay(panelCfg.UNLOCK_DURATION, function()
		-- Si mientras tanto ha salido otro aviso, este ya no lo apaga
		if token == noticeToken then
			noticeWindow.close()
		end
	end)
end

--------------------------------------------------------------------------------
-- Cambios
--------------------------------------------------------------------------------

-- Se compara la lista anterior con la nueva para saber que se acaba de desbloquear
local knownKeys = {}
local firstRead = true

local function checkNewTags()
	local unlockedList = player:GetAttribute("tagsUnlocked") or ""

	for key in string.gmatch(unlockedList, "[^,]+") do
		if not knownKeys[key] then
			knownKeys[key] = true

			-- Al entrar al juego no se avisa de los que ya tenia
			if not firstRead then
				local tag = tagByKey[key]
				if tag then
					showUnlockNotice(tag)
				end
			end
		end
	end

	firstRead = false
end

player:GetAttributeChangedSignal("tag"):Connect(refresh)
player:GetAttributeChangedSignal("tagsUnlocked"):Connect(function()
	refresh()
	checkNewTags()
end)

icon.Activated:Connect(panelWindow.toggle)
closeButton.Activated:Connect(panelWindow.close)

refresh()
checkNewTags()
