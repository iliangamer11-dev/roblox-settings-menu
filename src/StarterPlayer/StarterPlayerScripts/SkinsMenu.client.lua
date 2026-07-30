--[[
	SkinsMenu (LocalScript en StarterPlayer > StarterPlayerScripts)

	Boton SKINS (imagen arriba y texto debajo, como los demas) y su panel: salen todas
	las skins del pico con una vista previa de sus colores. Las que no tienes salen
	atenuadas con el requisito ("Buy Mine Zone").

	Al desbloquear una NO se equipa sola: sale el aviso "New skin unlocked" y la equipas
	tu desde aqui.

	El servidor (Skins) publica los atributos "skin" y "skinsUnlocked"; este menu solo los
	lee y pide el cambio.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))

local buttonCfg = Config.SKIN_BUTTON
local panelCfg = Config.SKIN_PANEL
local theme = Config.UI_THEME

if not buttonCfg.ENABLED then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local skinRemote = ReplicatedStorage:WaitForChild(Config.SKIN_REMOTE_NAME)

local wallTitles = {}
for _, wall in Config.WALLS do
	wallTitles[wall.NAME] = wall.TITLE
end

local skinByKey = {}
for _, skin in Config.SKINS do
	skinByKey[skin.KEY] = skin
end

--------------------------------------------------------------------------------
-- Boton
--------------------------------------------------------------------------------

local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "SkinsButtonGui"
buttonGui.ResetOnSpawn = false
buttonGui.IgnoreGuiInset = true
buttonGui.Parent = playerGui

local buttonRoot = UiTheme.root(buttonGui)

local icon = UiTheme.hudButton(buttonRoot, buttonCfg.SLOT, buttonCfg.ICON_ID, buttonCfg.LABEL)

--------------------------------------------------------------------------------
-- Panel
--------------------------------------------------------------------------------

local panelGui = Instance.new("ScreenGui")
panelGui.Name = "SkinsPanelGui"
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

-- Cuadradito de color, para ver la skin sin equiparla
local function makeSwatch(parent: Instance, color: Color3, offsetX: number)
	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.AnchorPoint = Vector2.new(0, 0.5)
	swatch.Position = UDim2.new(0, offsetX, 0.5, 0)
	swatch.Size = UDim2.fromOffset(30, 30)
	swatch.BackgroundColor3 = color
	swatch.BorderSizePixel = 0
	swatch.Parent = parent
	UiTheme.corner(swatch, 6)
	UiTheme.stroke(swatch, theme.OUTER_OUTLINE, 2)
	return swatch
end

for index, skin in Config.SKINS do
	local row = Instance.new("Frame")
	row.Name = skin.KEY
	row.LayoutOrder = index
	row.Size = UDim2.new(1, 0, 0, panelCfg.ROW_HEIGHT)
	row.BackgroundColor3 = theme.BUTTON_COLOR
	row.BackgroundTransparency = 0.15
	row.BorderSizePixel = 0
	row.Parent = scroll
	UiTheme.corner(row, theme.CORNER_RADIUS)
	UiTheme.stroke(row, theme.OUTER_OUTLINE, 2)

	-- Vista previa: color del mango y color de la cabeza
	makeSwatch(row, skin.HANDLE_COLOR, 14)
	makeSwatch(row, skin.HEAD_COLOR, 50)

	local nameLabel = UiTheme.text(row, skin.LABEL, UDim2.new(0.4, 0, 0.42, 0), UDim2.new(0, 92, 0.14, 0))
	nameLabel.Name = "SkinName"
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Cuanto dinero extra da esta skin
	local multiplierLabel = UiTheme.text(
		row,
		string.format(panelCfg.MULTIPLIER_FORMAT, tostring(skin.MULTIPLIER or 1)),
		UDim2.new(0.4, 0, 0.3, 0),
		UDim2.new(0, 92, 0.58, 0)
	)
	multiplierLabel.Name = "Multiplier"
	multiplierLabel.TextXAlignment = Enum.TextXAlignment.Left
	multiplierLabel.TextColor3 = theme.ON_COLOR

	local requirement = UiTheme.text(
		row,
		skin.WALL and string.format(panelCfg.WALL_REQUIREMENT, wallTitles[skin.WALL] or skin.WALL) or "",
		UDim2.new(0.32, 0, 0.28, 0),
		UDim2.new(1, -178, 0.6, 0)
	)
	requirement.Name = "Requirement"
	requirement.AnchorPoint = Vector2.new(1, 0)
	requirement.TextXAlignment = Enum.TextXAlignment.Right
	requirement.TextScaled = false
	requirement.TextSize = 14

	local equipButton = UiTheme.button(
		row,
		panelCfg.EQUIP_TEXT,
		UDim2.fromOffset(150, 42),
		UDim2.new(1, -14, 0.5, 0),
		Vector2.new(1, 0.5)
	)
	equipButton.Name = "Equip"

	equipButton.Activated:Connect(function()
		skinRemote:FireServer(skin.KEY)
	end)

	rows[skin.KEY] = { button = equipButton, requirement = requirement }
end

--------------------------------------------------------------------------------
-- Aviso de skin nueva
--------------------------------------------------------------------------------

local noticeGui = Instance.new("ScreenGui")
noticeGui.Name = "SkinUnlockGui"
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

local function showUnlockNotice(skin)
	noticeTitle.Text = string.format(panelCfg.UNLOCK_MESSAGE, skin.LABEL)
	noticeTitle.TextColor3 = skin.HEAD_COLOR
	noticeWindow.open()

	noticeToken += 1
	local token = noticeToken

	task.delay(panelCfg.UNLOCK_DURATION, function()
		if token == noticeToken then
			noticeWindow.close()
		end
	end)
end

--------------------------------------------------------------------------------
-- Estado
--------------------------------------------------------------------------------

local function refresh()
	local unlockedList = player:GetAttribute("skinsUnlocked") or ""
	local equipped = player:GetAttribute("skin")

	local unlocked = {}
	for key in string.gmatch(unlockedList, "[^,]+") do
		unlocked[key] = true
	end

	for _, skin in Config.SKINS do
		local row = rows[skin.KEY]
		if row then
			local has = unlocked[skin.KEY] == true

			if not has then
				row.button.Text = panelCfg.LOCKED_TEXT
				row.button.BackgroundColor3 = theme.OFF_COLOR
				row.button.AutoButtonColor = false
				row.requirement.Visible = true
			elseif skin.KEY == equipped then
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

-- Se compara la lista anterior con la nueva para avisar solo de las nuevas
local knownKeys = {}
local firstRead = true

local function checkNewSkins()
	local unlockedList = player:GetAttribute("skinsUnlocked") or ""

	for key in string.gmatch(unlockedList, "[^,]+") do
		if not knownKeys[key] then
			knownKeys[key] = true

			if not firstRead then
				local skin = skinByKey[key]
				if skin then
					showUnlockNotice(skin)
				end
			end
		end
	end

	firstRead = false
end

player:GetAttributeChangedSignal("skin"):Connect(refresh)
player:GetAttributeChangedSignal("skinsUnlocked"):Connect(function()
	refresh()
	checkNewSkins()
end)

icon.Activated:Connect(panelWindow.toggle)
closeButton.Activated:Connect(panelWindow.close)

refresh()
checkNewSkins()
