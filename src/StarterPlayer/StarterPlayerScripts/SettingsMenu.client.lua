--[[
	SettingsMenu (LocalScript en StarterPlayer > StarterPlayerScripts)

	Boton de ajustes (icono + "Settings" debajo) y el panel que abre al pulsarlo:
	  - Musica: subir, bajar y silenciar
	  - Ver o no la barra de nivel
	  - Ver o no los carteles de dinero
	  - Ver o no los agujeros del pico
	  - Ver o no los nombres/niveles sobre los personajes

	Mismo estilo en todo: gris con opacidad, contorno blanco muy fino por dentro,
	contorno negro por fuera y esquinas redondeadas (MiningConfig.UI_THEME).

	Son ajustes locales: cada jugador los cambia para si mismo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local Settings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))

local theme = Config.UI_THEME
local buttonCfg = Config.SETTINGS_BUTTON
local panelCfg = Config.SETTINGS_PANEL

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- El estilo (doble contorno, textos, botones) esta en UiTheme, compartido con el
-- cartel de dinero para que los dos se vean exactamente igual.
local normalizeAssetId = UiTheme.assetId
local makeFramedBox = UiTheme.framedBox
local makeText = UiTheme.text
local makeButton = UiTheme.button

--------------------------------------------------------------------------------
-- Boton de ajustes
--------------------------------------------------------------------------------

local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "SettingsButtonGui"
buttonGui.ResetOnSpawn = false
buttonGui.IgnoreGuiInset = true
buttonGui.Parent = playerGui

local _, buttonBody = makeFramedBox(buttonGui, buttonCfg.SIZE, buttonCfg.POSITION, buttonCfg.ANCHOR)

-- ImageButton para que se pueda pulsar el propio icono. Ocupa todo el cuadro,
-- porque el texto ahora va por fuera, debajo.
local icon = Instance.new("ImageButton")
icon.Name = "Icon"
icon.BackgroundTransparency = 1
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.fromScale(0.5, 0.5)
icon.Size = UDim2.fromScale(0.82, 0.82)
icon.ScaleType = Enum.ScaleType.Fit
icon.Image = normalizeAssetId(buttonCfg.ICON_ID)
icon.Parent = buttonBody

-- "SETTINGS" debajo del cuadro, fuera de la caja
local labelY = buttonCfg.POSITION.Y.Offset + buttonCfg.SIZE.Y.Offset * (1 - buttonCfg.ANCHOR.Y) + 2

local buttonLabel = makeText(
	buttonGui,
	buttonCfg.LABEL,
	UDim2.new(0, buttonCfg.SIZE.X.Offset + 40, 0, buttonCfg.LABEL_HEIGHT),
	UDim2.new(buttonCfg.POSITION.X.Scale, buttonCfg.POSITION.X.Offset + 20, buttonCfg.POSITION.Y.Scale, labelY)
)
buttonLabel.Name = "Label"
buttonLabel.AnchorPoint = Vector2.new(buttonCfg.ANCHOR.X, 0)

--------------------------------------------------------------------------------
-- Panel
--------------------------------------------------------------------------------

local panelGui = Instance.new("ScreenGui")
panelGui.Name = "SettingsPanelGui"
panelGui.ResetOnSpawn = false
panelGui.IgnoreGuiInset = true
panelGui.Enabled = false
panelGui.Parent = playerGui

local _, panel = makeFramedBox(panelGui, panelCfg.SIZE, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))

local title = makeText(panel, panelCfg.TITLE, UDim2.new(1, -80, 0, 44), UDim2.new(0, 20, 0, 12))
title.Name = "Title"
title.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = makeButton(panel, "X", UDim2.fromOffset(40, 40), UDim2.new(1, -14, 0, 14), Vector2.new(1, 0))
closeButton.Name = "Close"

-- Contenedor de las filas
local rows = Instance.new("Frame")
rows.Name = "Rows"
rows.BackgroundTransparency = 1
rows.Position = UDim2.new(0, 20, 0, 68)
rows.Size = UDim2.new(1, -40, 1, -88)
rows.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = rows

local rowOrder = 0

-- labelWidth es la parte del ancho que ocupa el texto de la izquierda. La fila de la
-- musica lleva mas controles, asi que su etiqueta tiene que ser mas estrecha.
local function makeRow(labelText: string, labelWidth: number?): Frame
	rowOrder += 1

	local row = Instance.new("Frame")
	row.Name = labelText
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 46)
	row.LayoutOrder = rowOrder
	row.Parent = rows

	local label = makeText(row, labelText, UDim2.new(labelWidth or 0.5, 0, 0.7, 0), UDim2.new(0, 0, 0.15, 0))
	label.TextXAlignment = Enum.TextXAlignment.Left

	return row
end

--------------------------------------------------------------------------------
-- Musica
--------------------------------------------------------------------------------

local music = Instance.new("Sound")
music.Name = "SettingsMusic"
music.SoundId = normalizeAssetId(panelCfg.MUSIC_ID)
music.Looped = true
music.Volume = Settings.get("musicVolume")
music.Parent = SoundService

local ok = pcall(function()
	music:Play()
end)
if not ok then
	warn("[SettingsMenu] No se pudo reproducir la musica " .. tostring(panelCfg.MUSIC_ID))
end

local musicRow = makeRow(panelCfg.MUSIC_LABEL, 0.26)

-- Todos los controles anclados a la derecha, para que no se pisen entre ellos
-- ni con la etiqueta de la izquierda: [-] [50%] [+] [Mute]
local downButton = makeButton(musicRow, "-", UDim2.fromOffset(42, 42), UDim2.new(1, -230, 0.5, 0), Vector2.new(1, 0.5))

local volumeLabel = makeText(musicRow, "50%", UDim2.fromOffset(62, 32), UDim2.new(1, -160, 0.5, 0))
volumeLabel.Name = "VolumeValue"
volumeLabel.AnchorPoint = Vector2.new(1, 0.5)

local upButton = makeButton(musicRow, "+", UDim2.fromOffset(42, 42), UDim2.new(1, -110, 0.5, 0), Vector2.new(1, 0.5))
local muteButton = makeButton(musicRow, panelCfg.MUTE_LABEL, UDim2.fromOffset(100, 42), UDim2.new(1, 0, 0.5, 0), Vector2.new(1, 0.5))

local function refreshMusic()
	local volume = Settings.get("musicVolume")
	local muted = Settings.get("musicMuted")

	music.Volume = muted and 0 or volume
	volumeLabel.Text = string.format("%d%%", math.floor(volume * 100 + 0.5))

	muteButton.Text = muted and panelCfg.UNMUTE_LABEL or panelCfg.MUTE_LABEL
	muteButton.BackgroundColor3 = muted and theme.OFF_COLOR or theme.BUTTON_COLOR
end

local function changeVolume(delta: number)
	local volume = math.clamp(Settings.get("musicVolume") + delta, 0, 1)
	Settings.set("musicVolume", volume)

	-- Subir el volumen quita el silencio, es lo que espera cualquiera
	if delta > 0 and Settings.get("musicMuted") then
		Settings.set("musicMuted", false)
	end
end

downButton.MouseButton1Click:Connect(function()
	changeVolume(-panelCfg.VOLUME_STEP)
end)
upButton.MouseButton1Click:Connect(function()
	changeVolume(panelCfg.VOLUME_STEP)
end)
muteButton.MouseButton1Click:Connect(function()
	Settings.toggle("musicMuted")
end)

--------------------------------------------------------------------------------
-- Interruptores ON/OFF
--------------------------------------------------------------------------------

local toggleButtons = {}

for _, rowCfg in panelCfg.ROWS do
	local row = makeRow(rowCfg.LABEL)
	local button = makeButton(row, "", UDim2.fromOffset(110, 42), UDim2.new(1, 0, 0.5, 0), Vector2.new(1, 0.5))

	toggleButtons[rowCfg.KEY] = button

	button.MouseButton1Click:Connect(function()
		Settings.toggle(rowCfg.KEY)
	end)
end

local function refreshToggle(key: string)
	local button = toggleButtons[key]
	if not button then
		return
	end

	local value = Settings.get(key)
	button.Text = value and panelCfg.ON_TEXT or panelCfg.OFF_TEXT
	button.BackgroundColor3 = value and theme.ON_COLOR or theme.OFF_COLOR
end

--------------------------------------------------------------------------------
-- Aplicar ajustes que afectan a cosas que crea el servidor
--------------------------------------------------------------------------------

-- Los carteles de dinero y las placas de nombre los crea el servidor, asi que aqui
-- solo se apagan/encienden en este cliente (Enabled es un cambio local).
local function applyBillboards(guiName: string, enabled: boolean)
	for _, descendant in workspace:GetDescendants() do
		if descendant.Name == guiName and descendant:IsA("BillboardGui") then
			descendant.Enabled = enabled
		end
	end
end

workspace.DescendantAdded:Connect(function(descendant)
	if not descendant:IsA("BillboardGui") then
		return
	end

	if descendant.Name == "Nameplate" and not Settings.get("showNameplates") then
		descendant.Enabled = false
	elseif descendant.Name == "MoneyPopupGui" and not Settings.get("showMoneyPopups") then
		descendant.Enabled = false
	end
end)

Settings.Changed.Event:Connect(function(key: string, value: any)
	if key == "musicVolume" or key == "musicMuted" then
		refreshMusic()
	elseif key == "showNameplates" then
		applyBillboards("Nameplate", value)
		refreshToggle(key)
	elseif key == "showMoneyPopups" then
		applyBillboards("MoneyPopupGui", value)
		refreshToggle(key)
	else
		refreshToggle(key)
	end
end)

--------------------------------------------------------------------------------
-- Abrir y cerrar
--------------------------------------------------------------------------------

icon.MouseButton1Click:Connect(function()
	panelGui.Enabled = not panelGui.Enabled
end)

closeButton.MouseButton1Click:Connect(function()
	panelGui.Enabled = false
end)

-- Estado inicial
refreshMusic()
for key in toggleButtons do
	refreshToggle(key)
end
