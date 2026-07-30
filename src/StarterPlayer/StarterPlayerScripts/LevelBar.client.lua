--[[
	LevelBar (LocalScript en StarterPlayer > StarterPlayerScripts)

	Barra de nivel: el progreso en verde, lo que falta en blanco, "Level X" dentro a la
	izquierda y los puntos dentro a la derecha. Texto y cuadro con contorno negro.

	Se dibuja por codigo, no hace falta montar nada a mano. Se ajusta todo en
	MiningConfig.LEVEL_BAR y lee los atributos que publica LevelService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local Format = require(ReplicatedStorage:WaitForChild("Format"))

local cfg = Config.LEVEL_BAR

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- Construccion de la barra
--------------------------------------------------------------------------------

local function addOutline(parent: Instance, thickness: number, color: Color3)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = color
	stroke.Parent = parent
	return stroke
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LevelBarGui"
screenGui.ResetOnSpawn = false -- no se reinicia al morir
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Fondo blanco = lo que falta
local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.Size = cfg.SIZE
bar.Position = cfg.POSITION
bar.AnchorPoint = cfg.ANCHOR
bar.BackgroundColor3 = cfg.BACKGROUND_COLOR
bar.BorderSizePixel = 0
bar.ClipsDescendants = true -- para que el verde respete las esquinas redondeadas
bar.Parent = screenGui

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, cfg.CORNER_RADIUS)
barCorner.Parent = bar

-- Contorno negro de todo el cuadro
local barStroke = addOutline(bar, cfg.OUTLINE_THICKNESS, cfg.OUTLINE_COLOR)
barStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Relleno verde = progreso
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = cfg.FILL_COLOR
fill.BorderSizePixel = 0
fill.ZIndex = 1
fill.Parent = bar

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, cfg.CORNER_RADIUS)
fillCorner.Parent = fill

-- Linea negra en el borde derecho del verde, como en la referencia
local fillEdge = Instance.new("Frame")
fillEdge.Name = "Edge"
fillEdge.AnchorPoint = Vector2.new(1, 0)
fillEdge.Position = UDim2.fromScale(1, 0)
fillEdge.Size = UDim2.new(0, math.max(1, cfg.OUTLINE_THICKNESS - 1), 1, 0)
fillEdge.BackgroundColor3 = cfg.OUTLINE_COLOR
fillEdge.BorderSizePixel = 0
fillEdge.ZIndex = 2
fillEdge.Parent = fill

local function makeLabel(name: string, alignment: Enum.TextXAlignment): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = cfg.FONT
	label.TextColor3 = cfg.TEXT_COLOR
	label.TextScaled = true
	label.TextXAlignment = alignment
	label.ZIndex = 3 -- por encima del verde
	label.Parent = bar

	local stroke = addOutline(label, cfg.TEXT_OUTLINE_THICKNESS, cfg.TEXT_OUTLINE_COLOR)
	stroke.LineJoinMode = Enum.LineJoinMode.Round

	return label
end

-- "Level X" dentro, a la izquierda
local levelLabel = makeLabel("Level", Enum.TextXAlignment.Left)
levelLabel.AnchorPoint = Vector2.new(0, 0.5)
levelLabel.Position = UDim2.new(0, cfg.PADDING, 0.5, 0)
levelLabel.Size = UDim2.new(0.55, -cfg.PADDING, 0.72, 0)

-- Puntos dentro, a la derecha
local progressLabel = makeLabel("Progress", Enum.TextXAlignment.Right)
progressLabel.AnchorPoint = Vector2.new(1, 0.5)
progressLabel.Position = UDim2.new(1, -cfg.PADDING, 0.5, 0)
progressLabel.Size = UDim2.new(0.45, -cfg.PADDING, 0.62, 0)

--------------------------------------------------------------------------------
-- Actualizacion
--------------------------------------------------------------------------------

local tweenInfo = TweenInfo.new(cfg.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function update()
	local level = player:GetAttribute("level") or 1
	local xp = player:GetAttribute("xp") or 0
	local needed = player:GetAttribute("xpNeeded") or Config.LEVEL.BASE_XP

	levelLabel.Text = string.format(cfg.LEVEL_FORMAT, level)
	progressLabel.Text = string.format(cfg.PROGRESS_FORMAT, Format.number(xp), Format.number(needed))

	local alpha = needed > 0 and math.clamp(xp / needed, 0, 1) or 0
	TweenService:Create(fill, tweenInfo, { Size = UDim2.fromScale(alpha, 1) }):Play()
end

player:GetAttributeChangedSignal("level"):Connect(update)
player:GetAttributeChangedSignal("xp"):Connect(update)
player:GetAttributeChangedSignal("xpNeeded"):Connect(update)

update()
