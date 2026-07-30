--[[
	MoneyHud (LocalScript en StarterPlayer > StarterPlayerScripts)

	Cartel con el dinero que tiene el jugador, con el mismo estilo que el boton de
	ajustes (gris con opacidad, contorno blanco fino, contorno negro y esquinas
	redondeadas) y colocado justo ENCIMA de ese boton.

	La cantidad se lee del atributo "money" que publica MiningService, asi que se
	actualiza sola en cada picazo y en cada compra.

	Ajustes en MiningConfig.MONEY_PANEL.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local Format = require(ReplicatedStorage:WaitForChild("Format"))
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))

local cfg = Config.MONEY_PANEL
local buttonCfg = Config.SETTINGS_BUTTON

if not cfg.ENABLED then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- Posicion: pegado encima del boton de ajustes
--------------------------------------------------------------------------------

-- El boton de ajustes esta centrado con ANCHOR (0.5, 0.5), asi que su borde de arriba
-- queda a media altura menos la mitad de su alto. El cartel se ancla por abajo (Y = 1)
-- justo ahi, menos la separacion.
local function moneyPosition(): UDim2
	local settingsHalfHeight = buttonCfg.SIZE.Y.Offset * buttonCfg.ANCHOR.Y
	local offsetY = buttonCfg.POSITION.Y.Offset - settingsHalfHeight - cfg.GAP

	return UDim2.new(buttonCfg.POSITION.X.Scale, buttonCfg.POSITION.X.Offset, buttonCfg.POSITION.Y.Scale, offsetY)
end

--------------------------------------------------------------------------------
-- Cartel
--------------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoneyHudGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local anchor = Vector2.new(buttonCfg.ANCHOR.X, 1) -- misma columna, pegado por abajo
local _, body = UiTheme.framedBox(screenGui, cfg.SIZE, moneyPosition(), anchor)

-- Icono a la IZQUIERDA, cuadrado, con el alto del cartel
local iconSide = math.floor(cfg.SIZE.Y.Offset * cfg.ICON_SIZE)

local icon = Instance.new("ImageLabel")
icon.Name = "Icon"
icon.BackgroundTransparency = 1
icon.AnchorPoint = Vector2.new(0, 0.5)
icon.Position = UDim2.new(0, cfg.PADDING, 0.5, 0)
icon.Size = UDim2.fromOffset(iconSide, iconSide)
icon.ScaleType = Enum.ScaleType.Fit
icon.Image = UiTheme.assetId(cfg.ICON_ID)
icon.Parent = body

-- La cantidad ocupa el resto, a la DERECHA del icono
local amountLabel = UiTheme.text(
	body,
	"0",
	UDim2.new(1, -(iconSide + cfg.PADDING * 3), 0.62, 0),
	UDim2.new(1, -cfg.PADDING, 0.5, 0)
)
amountLabel.Name = "Amount"
amountLabel.AnchorPoint = Vector2.new(1, 0.5)
amountLabel.TextXAlignment = Enum.TextXAlignment.Right

--------------------------------------------------------------------------------
-- Actualizacion
--------------------------------------------------------------------------------

local function update()
	local money = player:GetAttribute(Config.MONEY_NAME) or 0
	amountLabel.Text = cfg.PREFIX .. Format.number(money)
end

player:GetAttributeChangedSignal(Config.MONEY_NAME):Connect(update)

update()
