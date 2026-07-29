--[[
	PICKAXE + MONEY  (VERSION TODO EN UNO)

	Alternativa a la version modular de src/ para quien no usa Rojo.
	NO uses las dos a la vez: harian el trabajo doble.

	INSTALACION:
	1. ServerScriptService > Insert Object > Script
	2. Pega TODO este codigo
	3. Play

	Naturaleza = 1 | Desierto = 5 | Mina = 10 | Luna = 25 | Dulces = 50
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local StarterPack = game:GetService("StarterPack")

--------------------------------------------------------------------------------
-- CONFIGURACION
--------------------------------------------------------------------------------

local TOOL_NAME = "Pickaxe"
local MONEY_NAME = "money"
local STARTING_MONEY = 0

local REWARDS = {
	Naturaleza = 1,
	Desierto = 5,
	Mina = 10,
	Luna = 25,
	Dulces = 50,
}

local ZONE_COLORS = {
	Naturaleza = Color3.fromRGB(88, 200, 96),
	Desierto = Color3.fromRGB(235, 200, 120),
	Mina = Color3.fromRGB(170, 170, 175),
	Luna = Color3.fromRGB(150, 170, 230),
	Dulces = Color3.fromRGB(245, 120, 190),
}

local SWING_COOLDOWN = 0.55
local GROUND_CHECK_DISTANCE = 12
local DEBUG = true

-- El pico: mango a lo largo del eje Z, punta hacia -Z
local PICKAXE = {
	HANDLE_SIZE = Vector3.new(0.32, 0.32, 3),
	HANDLE_COLOR = Color3.fromRGB(110, 75, 45),
	-- Dos barras sobre el eje Y (punta arriba y punta abajo), en el plano del picazo
	HEAD_SIZE = Vector3.new(0.4, 1.15, 0.5),
	HEAD_COLOR = Color3.fromRGB(160, 160, 165),
	HEAD_ANGLE = 24, -- cuanto se echan las puntas hacia atras
	GRIP_OFFSET = Vector3.new(0, 0, 1.3),
	GRIP_ROTATION = Vector3.new(0, 0, 0),
	REST_ANGLE = -20, -- inclinacion en reposo (negativo = punta levantada)
}

-- El picazo: gira sobre el punto de agarre y baja hasta tocar el suelo
local SWING = {
	START_ANGLE = -50,
	MAX_ANGLE = 88,
	HEAD_REACH = 3.2, -- studs del agarre a la punta del pico
	RAISE_TIME = 0.14,
	STRIKE_TIME = 0.08,
	HOLD_TIME = 0.06,
	RETURN_TIME = 0.18,
	AXIS_SIGN = 1, -- pon -1 si el pico gira al lado contrario
}

-- Cartel flotante al ganar dinero
-- Agujero que queda donde se pica
local HOLE = {
	ENABLED = true,
	SIZE = 1.6, -- diametro en studs
	DEPTH = 0.15, -- grosor del disco
	COLOR = Color3.fromRGB(38, 32, 28),
	MATERIAL = Enum.Material.Slate,
	LIFETIME = 2, -- segundos hasta que desaparece
	USE_ZONE_COLOR = false, -- true = usa el color de la zona oscurecido
	DARKEN = 0.55,
}

local POPUP = {
	ENABLED = true,
	IMAGE_ID = "", -- tu icono: "rbxassetid://1234567890" (o solo el numero). Vacio = circulo
	IMAGE_COLOR = Color3.fromRGB(255, 210, 60),
	IMAGE_TRANSPARENCY = 0,
	ALWAYS_SHOW_CIRCLE = false, -- true = dibuja el circulo detras de tu imagen (para depurar)
	TEXT_FORMAT = "+%d",
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	TEXT_STROKE_COLOR = Color3.fromRGB(0, 0, 0),
	TEXT_STROKE_TRANSPARENCY = 0,
	FONT = Enum.Font.GothamBold,
	WIDTH = 2.4,
	HEIGHT = 2.4,
	IMAGE_RATIO = 0.68,
	ALWAYS_ON_TOP = false,
	MAX_DISTANCE = 150,
	MIN_RADIUS = 2,
	MAX_RADIUS = 5,
	MIN_HEIGHT = 0.5,
	MAX_HEIGHT = 4,
	RISE_HEIGHT = 3,
	DURATION = 1.2,
}

local function log(...)
	if DEBUG then
		print("[Pickaxe]", ...)
	end
end

--------------------------------------------------------------------------------
-- LA HERRAMIENTA (mango sobre el eje Z)
--------------------------------------------------------------------------------

local function weld(partA, partB)
	local joint = Instance.new("Weld")
	joint.Name = "PickaxeWeld"
	joint.Part0 = partA
	joint.Part1 = partB
	joint.C0 = partA.CFrame:Inverse() * partB.CFrame
	joint.C1 = CFrame.new()
	joint.Parent = partA
end

local function buildPickaxe()
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = "Pica el suelo para ganar " .. MONEY_NAME
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = PICKAXE.HANDLE_SIZE
	handle.Color = PICKAXE.HANDLE_COLOR
	handle.Material = Enum.Material.Wood
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	local headZ = -(PICKAXE.HANDLE_SIZE.Z / 2 - PICKAXE.HEAD_SIZE.X / 2)
	local headAngle = math.rad(PICKAXE.HEAD_ANGLE)
	local headLength = PICKAXE.HEAD_SIZE.Y

	local function makeHead(name, side)
		local head = Instance.new("Part")
		head.Name = name
		head.Size = PICKAXE.HEAD_SIZE
		head.Color = PICKAXE.HEAD_COLOR
		head.Material = Enum.Material.Metal
		head.TopSurface = Enum.SurfaceType.Smooth
		head.BottomSurface = Enum.SurfaceType.Smooth
		head.CanCollide = false
		head.Massless = true
		head.CFrame = handle.CFrame
			* CFrame.new(0, 0, headZ)
			* CFrame.fromEulerAnglesXYZ(headAngle * side, 0, 0)
			* CFrame.new(0, side * headLength / 2, 0)
		head.Parent = tool
		weld(handle, head)
	end

	makeHead("HeadUp", 1)
	makeHead("HeadDown", -1)

	local rotation = PICKAXE.GRIP_ROTATION
	tool.Grip = CFrame.new(PICKAXE.GRIP_OFFSET)
		* CFrame.fromEulerAnglesXYZ(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		* CFrame.fromEulerAnglesXYZ(math.rad(PICKAXE.REST_ANGLE * SWING.AXIS_SIGN), 0, 0)

	return tool
end

local pickaxeTemplate = buildPickaxe()

if not StarterPack:FindFirstChild(TOOL_NAME) then
	local starterCopy = pickaxeTemplate:Clone()
	starterCopy.Parent = StarterPack
	log("Pico agregado a StarterPack")
end

--------------------------------------------------------------------------------
-- VARIABLE money
--------------------------------------------------------------------------------

local money = {}

local function setupMoney(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local moneyValue = leaderstats:FindFirstChild(MONEY_NAME)
	if not moneyValue then
		moneyValue = Instance.new("IntValue")
		moneyValue.Name = MONEY_NAME
		moneyValue.Value = STARTING_MONEY
		moneyValue.Parent = leaderstats
	end

	money[player] = moneyValue

	player:SetAttribute(MONEY_NAME, moneyValue.Value)
	moneyValue:GetPropertyChangedSignal("Value"):Connect(function()
		player:SetAttribute(MONEY_NAME, moneyValue.Value)
	end)

	log("money creado para", player.Name)
end

--------------------------------------------------------------------------------
-- POPUP: ImageLabel arriba + TextLabel abajo, en un punto random
--------------------------------------------------------------------------------

local random = Random.new()
local warnedAboutId = false

-- Acepta "rbxassetid://123", "123" o "" (vacio = sin imagen)
local function normalizeImageId(value)
	if type(value) ~= "string" or value == "" then
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
		warn(string.format('[Pickaxe] IMAGE_ID = "%s" no parece un id valido. Usa "rbxassetid://123456789".', value))
	end

	return value
end

local function showPopup(character, amount)
	if not POPUP.ENABLED then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local angle = random:NextNumber(0, math.pi * 2)
	local radius = random:NextNumber(POPUP.MIN_RADIUS, POPUP.MAX_RADIUS)
	local height = random:NextNumber(POPUP.MIN_HEIGHT, POPUP.MAX_HEIGHT)

	local attachment = Instance.new("Attachment")
	attachment.Name = "MoneyPopup"
	attachment.Position = Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
	attachment.Parent = root

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MoneyPopupGui"
	billboard.Size = UDim2.fromScale(POPUP.WIDTH, POPUP.HEIGHT)
	billboard.AlwaysOnTop = POPUP.ALWAYS_ON_TOP
	billboard.MaxDistance = POPUP.MAX_DISTANCE
	billboard.LightInfluence = 0
	billboard.Parent = attachment

	local image = Instance.new("ImageLabel")
	image.Name = "Icono"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, POPUP.IMAGE_RATIO)
	image.Position = UDim2.fromScale(0, 0)
	image.ScaleType = Enum.ScaleType.Fit
	image.ImageColor3 = POPUP.IMAGE_COLOR
	image.ImageTransparency = POPUP.IMAGE_TRANSPARENCY

	local imageId = normalizeImageId(POPUP.IMAGE_ID)
	image.Image = imageId
	image.Parent = billboard

	local usingPlaceholder = imageId == "" or POPUP.ALWAYS_SHOW_CIRCLE == true
	if usingPlaceholder then
		image.BackgroundTransparency = POPUP.IMAGE_TRANSPARENCY
		image.BackgroundColor3 = POPUP.IMAGE_COLOR
		image.SizeConstraint = Enum.SizeConstraint.RelativeYY
		image.AnchorPoint = Vector2.new(0.5, 0)
		image.Position = UDim2.fromScale(0.5, 0)

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = image
	end

	local label = Instance.new("TextLabel")
	label.Name = "Cantidad"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1 - POPUP.IMAGE_RATIO)
	label.Position = UDim2.fromScale(0, POPUP.IMAGE_RATIO)
	label.Font = POPUP.FONT
	label.TextScaled = true
	label.Text = string.format(POPUP.TEXT_FORMAT, amount)
	label.TextColor3 = POPUP.TEXT_COLOR
	label.TextStrokeColor3 = POPUP.TEXT_STROKE_COLOR
	label.TextStrokeTransparency = POPUP.TEXT_STROKE_TRANSPARENCY
	label.Parent = billboard

	local riseInfo = TweenInfo.new(POPUP.DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(attachment, riseInfo, {
		Position = attachment.Position + Vector3.new(0, POPUP.RISE_HEIGHT, 0),
	}):Play()

	local fadeTime = POPUP.DURATION * 0.5
	local fadeInfo =
		TweenInfo.new(fadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, POPUP.DURATION - fadeTime)

	local imageGoal = { ImageTransparency = 1 }
	if usingPlaceholder then
		imageGoal.BackgroundTransparency = 1
	end
	TweenService:Create(image, fadeInfo, imageGoal):Play()
	TweenService:Create(label, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()

	Debris:AddItem(attachment, POPUP.DURATION + 0.25)
end

--------------------------------------------------------------------------------
-- ZONAS
--------------------------------------------------------------------------------

local function findZone(instance)
	local current = instance
	while current and current ~= workspace do
		local reward = REWARDS[current.Name]
		if reward then
			return current.Name, reward
		end
		current = current.Parent
	end
	return nil, nil
end

local function findZoneUnderCharacter(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil, nil, nil, nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local result = workspace:Raycast(root.Position, Vector3.new(0, -GROUND_CHECK_DISTANCE, 0), params)
	if result then
		local zoneName, reward = findZone(result.Instance)
		if zoneName then
			return zoneName, reward, result.Instance, result.Position, result.Normal
		end
		log("Piso detectado:", result.Instance:GetFullName(), "- no es una zona valida")
	else
		log("No se detecto piso debajo del jugador")
	end

	return nil, nil, nil, nil, nil
end

-- Agujero que queda marcado donde se pico
local function spawnHole(position, normal, zoneName)
	if not HOLE.ENABLED then
		return
	end

	local color = HOLE.COLOR
	if HOLE.USE_ZONE_COLOR then
		local zoneColor = ZONE_COLORS[zoneName]
		if zoneColor then
			color = zoneColor:Lerp(Color3.new(0, 0, 0), HOLE.DARKEN)
		end
	end

	local hole = Instance.new("Part")
	hole.Name = "PickaxeHole"
	hole.Shape = Enum.PartType.Cylinder
	hole.Size = Vector3.new(HOLE.DEPTH, HOLE.SIZE, HOLE.SIZE)
	hole.Color = color
	hole.Material = HOLE.MATERIAL
	hole.Anchored = true
	hole.CanCollide = false
	hole.CanQuery = false
	hole.CanTouch = false
	hole.CastShadow = false
	-- El cilindro tiene el eje en X: se gira 90 grados para alinearlo con la normal
	hole.CFrame = CFrame.lookAt(position + normal * (HOLE.DEPTH * 0.4), position + normal)
		* CFrame.fromEulerAnglesXYZ(0, math.rad(90), 0)
	hole.Parent = workspace

	Debris:AddItem(hole, HOLE.LIFETIME)
end

--------------------------------------------------------------------------------
-- ANIMACION DEL PICAZO
--------------------------------------------------------------------------------

local swinging = {}

local function lerpGrip(tool, from, to, duration)
	local elapsed = 0
	while elapsed < duration do
		local dt = RunService.Heartbeat:Wait()
		if not tool.Parent then
			return
		end
		elapsed += dt
		tool.Grip = from:Lerp(to, math.clamp(elapsed / duration, 0, 1))
	end
	tool.Grip = to
end

local function pitch(degrees)
	return CFrame.fromEulerAnglesXYZ(math.rad(degrees * SWING.AXIS_SIGN), 0, 0)
end

-- Angulo justo para que la punta del pico llegue al suelo
local function computeStrikeAngle(character)
	local hand = character:FindFirstChild("RightHand") -- R15
		or character:FindFirstChild("Right Arm") -- R6
		or character:FindFirstChild("HumanoidRootPart")
	if not hand then
		return SWING.MAX_ANGLE
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local result = workspace:Raycast(hand.Position, Vector3.new(0, -GROUND_CHECK_DISTANCE, 0), params)
	if not result then
		return SWING.MAX_ANGLE
	end

	local height = hand.Position.Y - result.Position.Y
	local ratio = math.clamp(height / SWING.HEAD_REACH, 0, 1)

	return math.min(math.deg(math.asin(ratio)), SWING.MAX_ANGLE)
end

local function playSwing(tool, character)
	if swinging[tool] then
		return
	end
	swinging[tool] = true

	local baseGrip = tool:GetAttribute("BaseGrip")
	if typeof(baseGrip) ~= "CFrame" then
		baseGrip = tool.Grip
		tool:SetAttribute("BaseGrip", baseGrip)
	end

	-- El Grip en reposo ya viene inclinado REST_ANGLE, se resta para que los angulos
	-- del golpe sigan siendo absolutos
	local rest = PICKAXE.REST_ANGLE
	local raised = baseGrip * pitch(SWING.START_ANGLE - rest)
	local struck = baseGrip * pitch(computeStrikeAngle(character) - rest)

	task.spawn(function()
		lerpGrip(tool, baseGrip, raised, SWING.RAISE_TIME)
		lerpGrip(tool, raised, struck, SWING.STRIKE_TIME)
		task.wait(SWING.HOLD_TIME)
		lerpGrip(tool, struck, baseGrip, SWING.RETURN_TIME)
		tool.Grip = baseGrip
		swinging[tool] = nil
	end)
end

local function playHitEffect(host, position, zoneName)
	local attachment = Instance.new("Attachment")
	attachment.Name = "PickaxeHit"
	attachment.WorldPosition = position
	attachment.Parent = host

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(ZONE_COLORS[zoneName] or Color3.new(1, 1, 1))
	emitter.Lifetime = NumberRange.new(0.25, 0.45)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.25)
	emitter.Parent = attachment
	emitter:Emit(18)

	Debris:AddItem(attachment, 2)
end

--------------------------------------------------------------------------------
-- CLICK IZQUIERDO
--------------------------------------------------------------------------------

local lastSwing = {}

local function onActivated(tool)
	local character = tool.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local now = os.clock()
	if lastSwing[player] and now - lastSwing[player] < SWING_COOLDOWN then
		return
	end
	lastSwing[player] = now

	playSwing(tool, character)

	local zoneName, reward, host, position, normal = findZoneUnderCharacter(character)
	if not zoneName then
		return
	end

	local moneyValue = money[player]
	if moneyValue then
		moneyValue.Value += reward
		log(player.Name, "pico en", zoneName, "+" .. reward, "=> money:", moneyValue.Value)
	end

	showPopup(character, reward)

	if host and position then
		playHitEffect(host, position, zoneName)
		spawnHole(position, normal or Vector3.yAxis, zoneName)
	end
end

local function hookTool(tool)
	if not tool:IsA("Tool") or tool.Name ~= TOOL_NAME then
		return
	end
	if tool:GetAttribute("PickaxeHooked") then
		return
	end
	tool:SetAttribute("PickaxeHooked", true)

	tool.Activated:Connect(function()
		onActivated(tool)
	end)
	log("Pico conectado:", tool:GetFullName())
end

local function watch(container)
	for _, child in container:GetChildren() do
		hookTool(child)
	end
	container.ChildAdded:Connect(hookTool)
end

--------------------------------------------------------------------------------
-- JUGADORES
--------------------------------------------------------------------------------

local function onCharacterAdded(player, character)
	watch(character)

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		backpack = player:WaitForChild("Backpack", 10)
	end
	if not backpack then
		warn("[Pickaxe] No se encontro el Backpack de " .. player.Name)
		return
	end

	watch(backpack)

	task.wait(0.5)
	if not backpack:FindFirstChild(TOOL_NAME) and not character:FindFirstChild(TOOL_NAME) then
		local tool = pickaxeTemplate:Clone()
		tool.Parent = backpack
		log("Pico entregado manualmente a", player.Name)
	end
end

local function onPlayerAdded(player)
	setupMoney(player)

	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacterAdded, player, character)
	end)

	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	money[player] = nil
	lastSwing[player] = nil
end)

log("MiningService listo")
