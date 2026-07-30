--[[
	ShopMenu (LocalScript en StarterPlayer > StarterPlayerScripts)

	Boton de la tienda (al lado del de ajustes) y el panel que abre:
	  - cabecera con icono, titulo y boton rojo de cerrar
	  - cartel grande arriba
	  - separador "Gamepasses"
	  - cuadricula de gamepasses; al pulsar uno se abre la compra de Roblox

	Mismo estilo que el resto (MiningConfig.UI_THEME) y todo montado con UiTheme.

	Los gamepasses se configuran en MiningConfig.SHOP_PANEL.GAMEPASSES.
	Con ID = 0 el boton sale desactivado, para poder ver el diseno sin tenerlos creados.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))

local theme = Config.UI_THEME
local settingsCfg = Config.SETTINGS_BUTTON
local buttonCfg = Config.SHOP_BUTTON
local panelCfg = Config.SHOP_PANEL

if not buttonCfg.ENABLED then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- Boton: pegado al lado del de ajustes
--------------------------------------------------------------------------------

local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "ShopButtonGui"
buttonGui.ResetOnSpawn = false
buttonGui.IgnoreGuiInset = true
buttonGui.Parent = playerGui

-- Se calcula desde el boton de ajustes: si mueves ese, este lo sigue.
-- Con ANCHOR X 0 (izquierda) va a su derecha; con ANCHOR X 1 (derecha) va a su izquierda.
local side = settingsCfg.ANCHOR.X >= 0.5 and -1 or 1
local buttonX = settingsCfg.POSITION.X.Offset + side * (settingsCfg.SIZE.X.Offset + buttonCfg.GAP_X)

local buttonPosition =
	UDim2.new(settingsCfg.POSITION.X.Scale, buttonX, settingsCfg.POSITION.Y.Scale, settingsCfg.POSITION.Y.Offset)

local _, buttonBody = UiTheme.framedBox(buttonGui, settingsCfg.SIZE, buttonPosition, settingsCfg.ANCHOR)

local icon = Instance.new("ImageButton")
icon.Name = "Icon"
icon.BackgroundTransparency = 1
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.fromScale(0.5, 0.5)
icon.Size = UDim2.fromScale(0.82, 0.82)
icon.ScaleType = Enum.ScaleType.Fit
icon.Image = UiTheme.assetId(buttonCfg.ICON_ID)
icon.Parent = buttonBody

-- Texto debajo del cuadro, igual que en ajustes
local labelY = settingsCfg.POSITION.Y.Offset + settingsCfg.SIZE.Y.Offset * (1 - settingsCfg.ANCHOR.Y) + 2

local buttonLabel = UiTheme.text(
	buttonGui,
	buttonCfg.LABEL,
	UDim2.new(0, settingsCfg.SIZE.X.Offset + 40, 0, settingsCfg.LABEL_HEIGHT),
	UDim2.new(settingsCfg.POSITION.X.Scale, buttonX + (settingsCfg.SIZE.X.Offset / 2), settingsCfg.POSITION.Y.Scale, labelY)
)
buttonLabel.Name = "Label"
buttonLabel.AnchorPoint = Vector2.new(0.5, 0)

--------------------------------------------------------------------------------
-- Panel
--------------------------------------------------------------------------------

local panelGui = Instance.new("ScreenGui")
panelGui.Name = "ShopPanelGui"
panelGui.ResetOnSpawn = false
panelGui.IgnoreGuiInset = true
panelGui.Enabled = false
panelGui.Parent = playerGui

local _, panel = UiTheme.framedBox(panelGui, panelCfg.SIZE, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))

-- Cabecera
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

-- Boton rojo de cerrar
local closeButton = UiTheme.button(header, "X", UDim2.fromOffset(38, 38), UDim2.new(1, -8, 0.5, 0), Vector2.new(1, 0.5))
closeButton.Name = "Close"
closeButton.BackgroundColor3 = theme.OFF_COLOR

-- Cartel grande
local banner = Instance.new("ImageLabel")
banner.Name = "Banner"
banner.Size = UDim2.new(1, -24, 0, panelCfg.BANNER.HEIGHT)
banner.Position = UDim2.new(0, 12, 0, 74)
banner.BackgroundColor3 = panelCfg.BANNER.COLOR
banner.BackgroundTransparency = 0.05
banner.BorderSizePixel = 0
banner.ScaleType = Enum.ScaleType.Crop
banner.Image = UiTheme.assetId(panelCfg.BANNER.IMAGE_ID)
banner.Parent = panel
UiTheme.corner(banner, theme.CORNER_RADIUS)
UiTheme.stroke(banner, theme.OUTER_OUTLINE, 2)

local bannerTitle = UiTheme.text(banner, panelCfg.BANNER.TITLE, UDim2.new(1, -20, 0.4, 0), UDim2.new(0, 10, 0, 12))
bannerTitle.Name = "BannerTitle"
bannerTitle.TextXAlignment = Enum.TextXAlignment.Left

local bannerSubtitle =
	UiTheme.text(banner, panelCfg.BANNER.SUBTITLE, UDim2.new(1, -20, 0.26, 0), UDim2.new(0, 10, 0.56, 0))
bannerSubtitle.Name = "BannerSubtitle"
bannerSubtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Separador "Gamepasses"
local sectionLabel =
	UiTheme.text(panel, panelCfg.SECTION_LABEL, UDim2.new(1, -24, 0, 28), UDim2.new(0, 12, 0, 74 + panelCfg.BANNER.HEIGHT + 8))
sectionLabel.Name = "Section"

--------------------------------------------------------------------------------
-- Cuadricula de gamepasses
--------------------------------------------------------------------------------

local gridTop = 74 + panelCfg.BANNER.HEIGHT + 42

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Gamepasses"
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Position = UDim2.new(0, 12, 0, gridTop)
scroll.Size = UDim2.new(1, -24, 1, -(gridTop + 12))
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 6
scroll.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = panelCfg.TILE_SIZE
grid.CellPadding = UDim2.fromOffset(panelCfg.TILE_PADDING, panelCfg.TILE_PADDING)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

local function makeTile(pass, order: number)
	local tile = Instance.new("TextButton")
	tile.Name = pass.NAME
	tile.LayoutOrder = order
	tile.BackgroundColor3 = theme.BUTTON_COLOR
	tile.BackgroundTransparency = 0.1
	tile.BorderSizePixel = 0
	tile.AutoButtonColor = true
	tile.Text = ""
	tile.Parent = scroll
	UiTheme.corner(tile, theme.CORNER_RADIUS)
	UiTheme.stroke(tile, theme.OUTER_OUTLINE, 2)

	local passIcon = Instance.new("ImageLabel")
	passIcon.Name = "Icon"
	passIcon.BackgroundTransparency = 1
	passIcon.AnchorPoint = Vector2.new(0.5, 0)
	passIcon.Position = UDim2.fromScale(0.5, 0.06)
	passIcon.Size = UDim2.fromScale(0.5, 0.44)
	passIcon.ScaleType = Enum.ScaleType.Fit
	passIcon.Image = UiTheme.assetId(pass.ICON_ID)
	passIcon.Parent = tile

	local nameLabel = UiTheme.text(tile, pass.NAME, UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.52))
	nameLabel.Name = "PassName"

	local priceLabel = UiTheme.text(tile, panelCfg.LOADING_TEXT, UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.74))
	priceLabel.Name = "Price"

	-- Sin id configurado: se ve el diseno pero no se puede comprar
	if pass.ID == nil or pass.ID == 0 then
		tile.AutoButtonColor = false
		tile.BackgroundTransparency = 0.5
		priceLabel.Text = "-"
		return tile
	end

	-- Precio y si ya lo tiene: son llamadas web, van en su propio hilo y con pcall
	task.spawn(function()
		local owned = false
		local okOwned, resultOwned = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.ID)
		end)
		if okOwned then
			owned = resultOwned
		end

		if owned then
			priceLabel.Text = panelCfg.OWNED_TEXT
			priceLabel.TextColor3 = theme.ON_COLOR
			return
		end

		local okInfo, info = pcall(function()
			return MarketplaceService:GetProductInfo(pass.ID, Enum.InfoType.GamePass)
		end)

		if okInfo and typeof(info) == "table" and info.PriceInRobux then
			priceLabel.Text = string.format(panelCfg.ROBUX_FORMAT, tostring(info.PriceInRobux))
		else
			priceLabel.Text = "-"
			warn(string.format("[ShopMenu] No se pudo leer el gamepass %d (%s)", pass.ID, pass.NAME))
		end
	end)

	tile.MouseButton1Click:Connect(function()
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, pass.ID)
		end)
	end)

	return tile
end

for index, pass in panelCfg.GAMEPASSES do
	makeTile(pass, index)
end

-- Si compra algo, se refresca el texto del gamepass a OWNED
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, passId, wasPurchased)
	if not wasPurchased then
		return
	end

	for _, pass in panelCfg.GAMEPASSES do
		if pass.ID == passId then
			local tile = scroll:FindFirstChild(pass.NAME)
			local priceLabel = tile and tile:FindFirstChild("Price")
			if priceLabel and priceLabel:IsA("TextLabel") then
				priceLabel.Text = panelCfg.OWNED_TEXT
				priceLabel.TextColor3 = theme.ON_COLOR
			end
		end
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
