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

-- El boton (cuadro + icono + texto debajo) lo monta UiTheme, que tambien calcula el
-- hueco segun el SLOT, asi que ajustes, tienda y tags nunca se pisan
local buttonRoot = UiTheme.root(buttonGui)

local icon = UiTheme.hudButton(buttonRoot, buttonCfg.SLOT, buttonCfg.ICON_ID, buttonCfg.LABEL)

--------------------------------------------------------------------------------
-- Panel
--------------------------------------------------------------------------------

local panelGui = Instance.new("ScreenGui")
panelGui.Name = "ShopPanelGui"
panelGui.ResetOnSpawn = false
panelGui.IgnoreGuiInset = true
panelGui.Enabled = false
panelGui.Parent = playerGui

local panelRoot = UiTheme.root(panelGui)

local panelOuter, panel = UiTheme.framedBox(panelRoot, panelCfg.SIZE, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))

-- Abre y cierra con animacion, y cierra los demas paneles
local panelWindow = UiTheme.panel(panelGui, panelOuter)

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

--------------------------------------------------------------------------------
-- Contenido con scroll (cartel + separador + gamepasses)
--------------------------------------------------------------------------------

-- Solo la cabecera se queda fija. Todo lo demas va dentro del ScrollingFrame, asi que
-- se puede ver entero aunque se anadan muchos gamepasses o la pantalla sea pequena.
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Position = UDim2.new(0, 12, 0, 74)
scroll.Size = UDim2.new(1, -24, 1, -86)
scroll.CanvasSize = UDim2.new() -- lo calcula AutomaticCanvasSize
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 8
scroll.ScrollBarImageColor3 = theme.OUTER_OUTLINE
scroll.ScrollBarImageTransparency = 0.3
-- El contenido se estrecha para dejar sitio a la barra, en vez de quedar debajo
scroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
scroll.Parent = panel

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.Padding = UDim.new(0, 10)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = scroll

-- Hueco de sobra al final, para poder seguir bajando un poco tras el ultimo gamepass
local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingBottom = UDim.new(0, panelCfg.EXTRA_SCROLL)
contentPadding.Parent = scroll

-- Cartel grande (hueco para tu imagen). Los textos solo se crean si los rellenas.
if panelCfg.BANNER.ENABLED then
	local banner = Instance.new("ImageLabel")
	banner.Name = "Banner"
	banner.LayoutOrder = 1
	banner.Size = UDim2.new(1, 0, 0, panelCfg.BANNER.HEIGHT)
	banner.BackgroundColor3 = panelCfg.BANNER.COLOR
	banner.BackgroundTransparency = 0.05
	banner.BorderSizePixel = 0
	banner.ScaleType = Enum.ScaleType.Crop
	banner.Image = UiTheme.assetId(panelCfg.BANNER.IMAGE_ID)
	banner.Parent = scroll
	UiTheme.corner(banner, theme.CORNER_RADIUS)
	UiTheme.stroke(banner, theme.OUTER_OUTLINE, 2)

	if panelCfg.BANNER.TITLE ~= "" then
		local bannerTitle =
			UiTheme.text(banner, panelCfg.BANNER.TITLE, UDim2.new(1, -20, 0.34, 0), UDim2.new(0, 10, 0, 12))
		bannerTitle.Name = "BannerTitle"
		bannerTitle.TextXAlignment = Enum.TextXAlignment.Left
	end

	if panelCfg.BANNER.SUBTITLE ~= "" then
		local bannerSubtitle =
			UiTheme.text(banner, panelCfg.BANNER.SUBTITLE, UDim2.new(1, -20, 0.24, 0), UDim2.new(0, 10, 0.56, 0))
		bannerSubtitle.Name = "BannerSubtitle"
		bannerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	end
end

-- Separador "Gamepasses"
local sectionLabel = UiTheme.text(scroll, panelCfg.SECTION_LABEL, UDim2.new(1, 0, 0, 30), UDim2.new())
sectionLabel.Name = "Section"
sectionLabel.LayoutOrder = 2

-- Cuadricula de gamepasses: crece sola hacia abajo segun cuantos haya
local tiles = Instance.new("Frame")
tiles.Name = "Gamepasses"
tiles.LayoutOrder = 3
tiles.BackgroundTransparency = 1
tiles.Size = UDim2.new(1, 0, 0, 0)
tiles.AutomaticSize = Enum.AutomaticSize.Y
tiles.Parent = scroll

local grid = Instance.new("UIGridLayout")
grid.CellSize = panelCfg.TILE_SIZE
grid.CellPadding = UDim2.fromOffset(panelCfg.TILE_PADDING, panelCfg.TILE_PADDING)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = tiles

-- Cada gamepass: icono, nombre, que hace (en ingles) y boton verde con el precio
local function makeTile(pass, order: number)
	local tile = Instance.new("Frame")
	tile.Name = pass.NAME
	tile.LayoutOrder = order
	tile.BackgroundColor3 = theme.BUTTON_COLOR
	tile.BackgroundTransparency = 0.1
	tile.BorderSizePixel = 0
	tile.Parent = tiles
	UiTheme.corner(tile, theme.CORNER_RADIUS)
	UiTheme.stroke(tile, theme.OUTER_OUTLINE, 2)

	local passIcon = Instance.new("ImageLabel")
	passIcon.Name = "Icon"
	passIcon.BackgroundTransparency = 1
	passIcon.AnchorPoint = Vector2.new(0.5, 0)
	passIcon.Position = UDim2.fromScale(0.5, 0.05)
	passIcon.Size = UDim2.fromScale(0.42, 0.32)
	passIcon.ScaleType = Enum.ScaleType.Fit
	passIcon.Image = UiTheme.assetId(pass.ICON_ID)
	passIcon.Parent = tile

	local nameLabel = UiTheme.text(tile, pass.NAME, UDim2.fromScale(1, 0.15), UDim2.fromScale(0, 0.38))
	nameLabel.Name = "PassName"

	-- Descripcion: varias lineas, sin TextScaled para que no se haga gigante
	local descLabel = UiTheme.text(tile, pass.DESC or "", UDim2.new(1, -18, 0.24, 0), UDim2.new(0, 9, 0.53, 0))
	descLabel.Name = "Description"
	descLabel.TextScaled = false
	descLabel.TextSize = 15
	descLabel.TextWrapped = true
	descLabel.TextYAlignment = Enum.TextYAlignment.Top

	-- Boton verde de comprar, abajo
	local buyButton = UiTheme.button(
		tile,
		string.format(panelCfg.PRICE_FORMAT, tostring(pass.PRICE or "?")),
		UDim2.new(1, -18, 0.19, 0),
		UDim2.new(0.5, 0, 0.97, 0),
		Vector2.new(0.5, 1)
	)
	buyButton.Name = "Buy"
	buyButton.BackgroundColor3 = panelCfg.BUY_COLOR

	local function markOwned()
		buyButton.Text = panelCfg.OWNED_TEXT
		buyButton.BackgroundColor3 = panelCfg.OWNED_COLOR
		buyButton.AutoButtonColor = false
	end

	-- Sin id configurado: se ve el diseno pero no se puede comprar
	if pass.ID == nil or pass.ID == 0 then
		buyButton.Text = "-"
		buyButton.BackgroundColor3 = panelCfg.OWNED_COLOR
		buyButton.AutoButtonColor = false
		return tile
	end

	buyButton.MouseButton1Click:Connect(function()
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, pass.ID)
		end)
	end)

	-- Consultas web: en su propio hilo para no congelar la interfaz, y con pcall para
	-- que un fallo de Roblox no rompa la tienda
	task.spawn(function()
		local okOwned, owned = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.ID)
		end)

		if okOwned and owned then
			markOwned()
			return
		end

		-- El precio real de Roblox manda sobre el escrito en la config
		local okInfo, info = pcall(function()
			return MarketplaceService:GetProductInfo(pass.ID, Enum.InfoType.GamePass)
		end)

		if okInfo and typeof(info) == "table" and info.PriceInRobux then
			buyButton.Text = string.format(panelCfg.PRICE_FORMAT, tostring(info.PriceInRobux))
		else
			warn(string.format("[ShopMenu] No se pudo leer el precio del gamepass %d (%s)", pass.ID, pass.NAME))
		end
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
			local tile = tiles:FindFirstChild(pass.NAME)
			local buyButton = tile and tile:FindFirstChild("Buy")
			if buyButton and buyButton:IsA("TextButton") then
				buyButton.Text = panelCfg.OWNED_TEXT
				buyButton.BackgroundColor3 = panelCfg.OWNED_COLOR
				buyButton.AutoButtonColor = false
			end
		end
	end
end)

--------------------------------------------------------------------------------
-- Abrir y cerrar
--------------------------------------------------------------------------------

icon.MouseButton1Click:Connect(panelWindow.toggle)
closeButton.MouseButton1Click:Connect(panelWindow.close)


