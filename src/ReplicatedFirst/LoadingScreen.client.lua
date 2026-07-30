--[[
	LoadingScreen (LocalScript en ReplicatedFirst)

	Pantalla de carga de Mine Millions: imagen de fondo, titulo, barra de progreso y
	frases que van rotando. Dura entre MIN_TIME y MAX_TIME segundos.

	Va en ReplicatedFirst a proposito: es lo unico que se replica antes que el resto del
	juego, asi que la pantalla aparece de inmediato y tapa la carga. Los LocalScripts de
	StarterPlayerScripts serian demasiado tarde.

	Se dibuja primero un fondo liso y despues se rellena con la configuracion, de forma
	que no hay ni un instante de pantalla negra esperando a ReplicatedStorage.

	Ajustes en MiningConfig.LOADING_SCREEN.
]]

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- Fondo inmediato
--------------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreenGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 1000 -- por encima de todo lo demas
screenGui.Parent = playerGui

local background = Instance.new("ImageLabel")
background.Name = "Background"
background.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
background.BackgroundTransparency = 0
background.BorderSizePixel = 0
background.Size = UDim2.fromScale(1, 1)
background.Image = ""
background.ScaleType = Enum.ScaleType.Crop -- llena la pantalla sin deformarse
background.Parent = screenGui

-- Se quita la pantalla de carga por defecto de Roblox, ya tenemos la nuestra
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

--------------------------------------------------------------------------------
-- Contenido
--------------------------------------------------------------------------------

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local cfg = Config.LOADING_SCREEN
local theme = Config.UI_THEME

if not cfg.ENABLED then
	screenGui:Destroy()
	return
end

background.BackgroundColor3 = cfg.BACKGROUND_COLOR

local function normalizeAssetId(value: any): string
	if typeof(value) ~= "string" or value == "" then
		return ""
	end
	local digits = string.match(value, "^%s*(%d+)%s*$")
	return digits and ("rbxassetid://" .. digits) or value
end

local imageId = normalizeAssetId(cfg.IMAGE_ID)
background.Image = imageId

-- Sin imagen: degradado de azul a casi negro, asi el fondo no queda plano.
-- Con imagen: una capa oscura encima para que se lea el texto.
local shade = Instance.new("Frame")
shade.Name = "Shade"
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = imageId == "" and 1 or (1 - cfg.IMAGE_DARKEN)
shade.BorderSizePixel = 0
shade.Size = UDim2.fromScale(1, 1)
shade.Parent = background

if imageId == "" then
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, cfg.GRADIENT_TOP),
		ColorSequenceKeypoint.new(1, cfg.GRADIENT_BOTTOM),
	})
	gradient.Parent = background
end

local function addTextOutline(label: Instance, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.TEXT_OUTLINE
	stroke.Thickness = thickness
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return stroke
end

-- Titulo
local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.2)
title.Size = UDim2.fromScale(0.8, 0.16)
title.Font = theme.FONT
title.TextScaled = true
title.Text = cfg.TITLE
title.TextColor3 = theme.TEXT_COLOR
title.Parent = background
addTextOutline(title, 4)

-- Subtitulo
local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.31)
subtitle.Size = UDim2.fromScale(0.5, 0.06)
subtitle.Font = theme.FONT
subtitle.TextScaled = true
subtitle.Text = cfg.SUBTITLE
subtitle.TextColor3 = theme.TEXT_COLOR
subtitle.Parent = background
addTextOutline(subtitle, 3)

-- Barra de progreso (mismo estilo que la de nivel: verde, blanco y contorno negro)
local barOuter = Instance.new("Frame")
barOuter.Name = "BarOutline"
barOuter.AnchorPoint = Vector2.new(0.5, 0.5)
barOuter.Position = cfg.BAR_POSITION
barOuter.Size = cfg.BAR_SIZE
barOuter.BackgroundColor3 = cfg.BAR_BACKGROUND_COLOR
barOuter.BorderSizePixel = 0
barOuter.ClipsDescendants = true
barOuter.Parent = background

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, theme.CORNER_RADIUS)
barCorner.Parent = barOuter

local barStroke = Instance.new("UIStroke")
barStroke.Color = theme.OUTER_OUTLINE
barStroke.Thickness = theme.OUTER_THICKNESS
barStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
barStroke.Parent = barOuter

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = cfg.BAR_FILL_COLOR
fill.BorderSizePixel = 0
fill.Parent = barOuter

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, theme.CORNER_RADIUS)
fillCorner.Parent = fill

local percent = Instance.new("TextLabel")
percent.Name = "Percent"
percent.BackgroundTransparency = 1
percent.AnchorPoint = Vector2.new(0.5, 0.5)
percent.Position = UDim2.fromScale(0.5, 0.5)
percent.Size = UDim2.fromScale(1, 0.7)
percent.Font = theme.FONT
percent.TextScaled = true
percent.Text = string.format(cfg.PROGRESS_FORMAT, 0)
percent.TextColor3 = theme.TEXT_COLOR
percent.ZIndex = 2
percent.Parent = barOuter
addTextOutline(percent, 2.5)

-- Frases rotando debajo de la barra
local tip = Instance.new("TextLabel")
tip.Name = "Tip"
tip.BackgroundTransparency = 1
tip.AnchorPoint = Vector2.new(0.5, 0.5)
tip.Position = UDim2.new(cfg.BAR_POSITION.X.Scale, cfg.BAR_POSITION.X.Offset, cfg.BAR_POSITION.Y.Scale + 0.09, 0)
tip.Size = UDim2.fromScale(0.7, 0.05)
tip.Font = theme.FONT
tip.TextScaled = true
tip.Text = cfg.TIPS[1] or ""
tip.TextColor3 = theme.TEXT_COLOR
tip.Parent = background
addTextOutline(tip, 2.5)

--------------------------------------------------------------------------------
-- Progreso
--------------------------------------------------------------------------------

local startClock = os.clock()

-- Latido del titulo: sin imagen de fondo la pantalla queda muy quieta y da la
-- sensacion de que el juego se ha colgado
if cfg.TITLE_PULSE > 0 then
	local titleScale = Instance.new("UIScale")
	titleScale.Parent = title

	task.spawn(function()
		local pulseInfo = TweenInfo.new(
			cfg.TITLE_PULSE_TIME,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1, -- repite para siempre
			true -- y vuelve
		)
		TweenService:Create(titleScale, pulseInfo, { Scale = 1 + cfg.TITLE_PULSE }):Play()
	end)
end

-- Las frases van cambiando mientras carga
task.spawn(function()
	local index = 1
	while screenGui.Parent and #cfg.TIPS > 1 do
		task.wait(cfg.TIP_INTERVAL)
		index = index % #cfg.TIPS + 1
		tip.Text = cfg.TIPS[index]
	end
end)

-- La barra avanza con el tiempo minimo, pero no llega al 100% hasta que el juego
-- esta cargado de verdad
task.spawn(function()
	while screenGui.Parent do
		local elapsed = os.clock() - startClock
		local byTime = math.clamp(elapsed / cfg.MIN_TIME, 0, 1)
		local target = game:IsLoaded() and byTime or math.min(byTime, 0.9)

		fill.Size = UDim2.fromScale(target, 1)
		percent.Text = string.format(cfg.PROGRESS_FORMAT, math.floor(target * 100))

		task.wait(0.05)
	end
end)

-- Espera: el minimo siempre, y hasta que cargue, con tope en MAX_TIME
if not game:IsLoaded() then
	task.spawn(function()
		game.Loaded:Wait()
	end)
end

while true do
	local elapsed = os.clock() - startClock

	if elapsed >= cfg.MAX_TIME then
		break
	end
	if elapsed >= cfg.MIN_TIME and game:IsLoaded() then
		break
	end

	task.wait(0.1)
end

-- Se completa la barra antes de irse, para que no desaparezca a medias
fill.Size = UDim2.fromScale(1, 1)
percent.Text = string.format(cfg.PROGRESS_FORMAT, 100)
task.wait(0.25)

--------------------------------------------------------------------------------
-- Desaparecer
--------------------------------------------------------------------------------

local fadeInfo = TweenInfo.new(cfg.FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

TweenService:Create(background, fadeInfo, { BackgroundTransparency = 1, ImageTransparency = 1 }):Play()
TweenService:Create(shade, fadeInfo, { BackgroundTransparency = 1 }):Play()
TweenService:Create(barOuter, fadeInfo, { BackgroundTransparency = 1 }):Play()
TweenService:Create(fill, fadeInfo, { BackgroundTransparency = 1 }):Play()

for _, label in { title, subtitle, percent, tip } do
	TweenService:Create(label, fadeInfo, { TextTransparency = 1 }):Play()
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService:Create(stroke, fadeInfo, { Transparency = 1 }):Play()
	end
end

task.wait(cfg.FADE_TIME + 0.1)
screenGui:Destroy()
