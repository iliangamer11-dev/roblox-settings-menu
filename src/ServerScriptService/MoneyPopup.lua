--[[
	MoneyPopup
	Cartel flotante que aparece al ganar dinero: un ImageLabel arriba (configurable)
	y un TextLabel debajo con la cantidad, en un punto random alrededor del jugador.

	El color depende del mineral que haya salido, asi se identifica de un vistazo.
	El mineral legendario cicla colores (arcoiris).

	Todo se configura en MiningConfig.POPUP.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local Minerals = require(script.Parent:WaitForChild("Minerals"))

local MoneyPopup = {}

local random = Random.new()
local warnedAboutId = false

-- Acepta "rbxassetid://123", "123" o "" (vacio = sin imagen)
local function normalizeImageId(value: any): string
	if typeof(value) ~= "string" or value == "" then
		return ""
	end

	local digits = string.match(value, "^%s*(%d+)%s*$")
	if digits then
		return "rbxassetid://" .. digits
	end

	local looksValid = string.find(value, "rbxassetid://", 1, true)
		or string.find(value, "rbxasset://", 1, true)
		or string.find(value, "rbxthumb://", 1, true)
		or string.find(value, "http", 1, true)

	if not looksValid and not warnedAboutId then
		warnedAboutId = true
		warn(string.format('[MoneyPopup] IMAGE_ID = "%s" no parece un id valido. Usa "rbxassetid://123456789".', value))
	end

	return value
end

-- Punto random alrededor del personaje (circulo con altura variable)
local function randomOffset(cfg): Vector3
	local angle = random:NextNumber(0, math.pi * 2)
	local radius = random:NextNumber(cfg.MIN_RADIUS, cfg.MAX_RADIUS)
	local height = random:NextNumber(cfg.MIN_HEIGHT, cfg.MAX_HEIGHT)

	return Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
end

-- mineral es una entrada de MiningConfig.MINERALS (puede ser nil)
function MoneyPopup.show(character: Model, amount: number, mineral: any?)
	local cfg = Config.POPUP
	if not cfg.ENABLED then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local color = cfg.IMAGE_COLOR
	if cfg.USE_MINERAL_COLOR and mineral and mineral.COLOR then
		color = mineral.COLOR
	end

	-- El Attachment engancha el cartel al jugador, asi lo sigue mientras se mueve
	local attachment = Instance.new("Attachment")
	attachment.Name = "MoneyPopup"
	attachment.Position = randomOffset(cfg)
	attachment.Parent = root

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MoneyPopupGui"
	billboard.Size = UDim2.fromScale(cfg.WIDTH, cfg.HEIGHT)
	billboard.AlwaysOnTop = cfg.ALWAYS_ON_TOP
	billboard.MaxDistance = cfg.MAX_DISTANCE
	billboard.LightInfluence = 0
	billboard.Parent = attachment

	-- ImageLabel arriba
	local image = Instance.new("ImageLabel")
	image.Name = "Icono"
	image.BackgroundTransparency = 1
	-- Centrada en su hueco y escalada con IMAGE_SCALE
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Size = UDim2.fromScale(cfg.IMAGE_SCALE, cfg.IMAGE_RATIO * cfg.IMAGE_SCALE)
	image.Position = UDim2.fromScale(0.5, cfg.IMAGE_RATIO / 2)
	image.ScaleType = Enum.ScaleType.Fit
	image.ImageColor3 = color
	image.ImageTransparency = cfg.IMAGE_TRANSPARENCY

	local imageId = normalizeImageId(cfg.IMAGE_ID)
	image.Image = imageId
	image.Parent = billboard

	-- Sin imagen (o con ALWAYS_SHOW_CIRCLE) se dibuja un circulo del color del mineral
	local usingPlaceholder = imageId == "" or cfg.ALWAYS_SHOW_CIRCLE == true
	if usingPlaceholder then
		image.BackgroundTransparency = cfg.IMAGE_TRANSPARENCY
		image.BackgroundColor3 = color
		-- RelativeYY: el ancho sigue al alto para que el circulo salga redondo
		image.SizeConstraint = Enum.SizeConstraint.RelativeYY

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = image
	end

	-- TextLabel debajo del ImageLabel
	local label = Instance.new("TextLabel")
	label.Name = "Cantidad"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1 - cfg.IMAGE_RATIO)
	label.Position = UDim2.fromScale(0, cfg.IMAGE_RATIO)
	label.Font = cfg.FONT
	label.TextScaled = true
	label.Text = string.format(cfg.TEXT_FORMAT, Minerals.format(amount))
	label.TextColor3 = cfg.TEXT_COLOR
	label.TextStrokeColor3 = cfg.TEXT_STROKE_COLOR
	label.TextStrokeTransparency = cfg.TEXT_STROKE_TRANSPARENCY
	label.Parent = billboard

	-- Nombre del mineral encima del dinero (opcional)
	local nameLabel = nil
	if cfg.SHOW_MINERAL_NAME and mineral and mineral.NAME then
		nameLabel = label:Clone()
		nameLabel.Name = "Mineral"
		nameLabel.Text = mineral.NAME
		nameLabel.TextColor3 = color
		nameLabel.Size = UDim2.fromScale(1, (1 - cfg.IMAGE_RATIO) * 0.7)
		nameLabel.Position = UDim2.fromScale(0, -(1 - cfg.IMAGE_RATIO) * 0.7)
		nameLabel.Parent = billboard
	end

	-- Mineral legendario: el color va cambiando
	if mineral and mineral.RAINBOW then
		task.spawn(function()
			local startClock = os.clock()
			while attachment.Parent do
				local hue = ((os.clock() - startClock) * cfg.RAINBOW_SPEED) % 1
				local rainbow = Color3.fromHSV(hue, 1, 1)

				image.ImageColor3 = rainbow
				if usingPlaceholder then
					image.BackgroundColor3 = rainbow
				end
				if nameLabel then
					nameLabel.TextColor3 = rainbow
				end

				task.wait(0.05)
			end
		end)
	end

	-- Sube mientras se desvanece
	local riseInfo = TweenInfo.new(cfg.DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(attachment, riseInfo, {
		Position = attachment.Position + Vector3.new(0, cfg.RISE_HEIGHT, 0),
	}):Play()

	local fadeTime = cfg.DURATION * 0.5
	local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, cfg.DURATION - fadeTime)

	local imageGoal = { ImageTransparency = 1 }
	if usingPlaceholder then
		imageGoal.BackgroundTransparency = 1
	end
	TweenService:Create(image, fadeInfo, imageGoal):Play()
	TweenService:Create(label, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	if nameLabel then
		TweenService:Create(nameLabel, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end

	Debris:AddItem(attachment, cfg.DURATION + 0.25)
end

return MoneyPopup
