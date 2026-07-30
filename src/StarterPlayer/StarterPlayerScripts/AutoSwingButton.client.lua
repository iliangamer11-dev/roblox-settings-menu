--[[
	AutoSwingButton (LocalScript en StarterPlayer > StarterPlayerScripts)

	Boton arriba en el centro para encender o apagar el Auto Swing.
	Solo aparece si el jugador tiene el gamepass (atributo "autoSwing", que publica
	Passes en el servidor).

	El boton solo avisa al servidor: quien decide si pica es el servidor, asi que no se
	puede usar para picar mas rapido de lo permitido.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))

local cfg = Config.AUTO_SWING_BUTTON
local theme = Config.UI_THEME

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local autoRemote = ReplicatedStorage:WaitForChild(Config.AUTO_REMOTE_NAME)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoSwingGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false -- se enciende si tiene el pase
screenGui.Parent = playerGui

local _, body = UiTheme.framedBox(screenGui, cfg.SIZE, cfg.POSITION, cfg.ANCHOR)

local button = UiTheme.button(body, cfg.ON_TEXT, UDim2.new(1, -10, 1, -10), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
button.Name = "Toggle"

local enabled = true

local function refresh()
	button.Text = enabled and cfg.ON_TEXT or cfg.OFF_TEXT
	button.BackgroundColor3 = enabled and theme.ON_COLOR or theme.OFF_COLOR
end

button.MouseButton1Click:Connect(function()
	enabled = not enabled
	refresh()
	autoRemote:FireServer(enabled)
end)

local function refreshVisibility()
	screenGui.Enabled = player:GetAttribute("autoSwing") == true
end

player:GetAttributeChangedSignal("autoSwing"):Connect(refreshVisibility)

refresh()
refreshVisibility()
