--[[
	MiningService (Script normal en ServerScriptService)

	- Crea la variable "money" para cada jugador (player.leaderstats.money)
	- Le da la herramienta "Pickaxe" al spawnear
	- Valida cada picazo y suma money segun la zona pisada / apuntada:
		Naturaleza = 1, Desierto = 5, Mina = 10, Luna = 25, Dulces = 50
	- Reproduce la animacion del picazo en el servidor para que TODOS la vean
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local PickaxeTool = require(script.Parent:WaitForChild("PickaxeTool"))
local MoneyPopup = require(script.Parent:WaitForChild("MoneyPopup"))

--------------------------------------------------------------------------------
-- Remote
--------------------------------------------------------------------------------

local swingRemote = ReplicatedStorage:FindFirstChild(Config.REMOTE_NAME)
if not swingRemote or not swingRemote:IsA("RemoteEvent") then
	swingRemote = Instance.new("RemoteEvent")
	swingRemote.Name = Config.REMOTE_NAME
	swingRemote.Parent = ReplicatedStorage
end

--------------------------------------------------------------------------------
-- Herramienta base
--------------------------------------------------------------------------------

local pickaxeTemplate = PickaxeTool.build()

--------------------------------------------------------------------------------
-- Variable money
--------------------------------------------------------------------------------

-- money[player] = IntValue  (la "variable money" de cada jugador)
local money = {}

local function setupMoney(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local moneyValue = leaderstats:FindFirstChild(Config.MONEY_NAME)
	if not moneyValue then
		moneyValue = Instance.new("IntValue")
		moneyValue.Name = Config.MONEY_NAME
		moneyValue.Value = Config.STARTING_MONEY
		moneyValue.Parent = leaderstats
	end

	money[player] = moneyValue

	-- Copia en un atributo, comodo para leer desde otros scripts: player:GetAttribute("money")
	player:SetAttribute(Config.MONEY_NAME, moneyValue.Value)
	moneyValue:GetPropertyChangedSignal("Value"):Connect(function()
		player:SetAttribute(Config.MONEY_NAME, moneyValue.Value)
	end)
end

local function addMoney(player: Player, amount: number)
	local moneyValue = money[player]
	if moneyValue then
		moneyValue.Value += amount
	end
end

--------------------------------------------------------------------------------
-- Zonas
--------------------------------------------------------------------------------

-- Busca hacia arriba en la jerarquia por una Part/Model con nombre de zona,
-- asi funciona igual si la zona es una Part sola o un Model con partes dentro.
local function findZone(instance: Instance?): (string?, number?)
	local current = instance
	while current and current ~= workspace do
		local reward = Config.REWARDS[current.Name]
		if reward then
			return current.Name, reward
		end
		current = current.Parent
	end
	return nil, nil
end

-- Zona sobre la que esta parado el jugador (raycast hacia abajo)
local function findZoneUnderCharacter(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil, nil, nil, nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local result = workspace:Raycast(root.Position, Vector3.new(0, -Config.GROUND_CHECK_DISTANCE, 0), params)
	if result then
		local zoneName, reward = findZone(result.Instance)
		if zoneName then
			return zoneName, reward, result.Instance, result.Position, result.Normal
		end
	end
	return nil, nil, nil, nil, nil
end

-- Normal de la superficie en el punto golpeado, para apoyar bien el agujero.
-- Se tira un rayo hacia abajo contra la propia zona; si falla, se asume suelo plano.
local function surfaceNormalAt(host: BasePart, position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { host }
	params.IgnoreWater = true

	local result = workspace:Raycast(position + Vector3.new(0, 3, 0), Vector3.new(0, -6, 0), params)
	if result then
		return result.Normal
	end
	return Vector3.yAxis
end

--------------------------------------------------------------------------------
-- Animacion del picazo
--------------------------------------------------------------------------------

local swinging = {} -- swinging[tool] = true mientras la animacion corre

local function lerpGrip(tool: Tool, from: CFrame, to: CFrame, duration: number)
	if duration <= 0 then
		tool.Grip = to
		return
	end

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

local function playCustomAnimation(character: Model)
	if Config.ANIMATION_ID == "" then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = Config.ANIMATION_ID

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track:Play()
		Debris:AddItem(animation, 5)
	end
end

-- Rotacion sobre el eje X del agarre: es lo que baja la punta del pico hacia el suelo
local function pitch(degrees: number): CFrame
	return CFrame.fromEulerAnglesXYZ(math.rad(degrees * Config.SWING.AXIS_SIGN), 0, 0)
end

-- Cuanto hay que girar el pico para que la punta llegue justo al suelo.
-- Se mide la altura de la mano sobre el piso: si el piso esta muy abajo se usa el
-- angulo maximo, y si esta muy cerca el golpe es mas corto.
local function computeStrikeAngle(character: Model): number
	local swing = Config.SWING

	local hand = character:FindFirstChild("RightHand") -- R15
		or character:FindFirstChild("Right Arm") -- R6
		or character:FindFirstChild("HumanoidRootPart")
	if not hand or not hand:IsA("BasePart") then
		return swing.MAX_ANGLE
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local result = workspace:Raycast(hand.Position, Vector3.new(0, -Config.GROUND_CHECK_DISTANCE, 0), params)
	if not result then
		return swing.MAX_ANGLE
	end

	local height = hand.Position.Y - result.Position.Y
	local ratio = math.clamp(height / swing.HEAD_REACH, 0, 1)

	-- La punta baja HEAD_REACH * sin(angulo), asi que este es el angulo justo para tocar
	local angle = math.deg(math.asin(ratio))

	return math.min(angle, swing.MAX_ANGLE)
end

-- Animacion procedural: el pico gira sobre el punto donde lo agarra la mano,
-- se levanta y baja hasta tocar la part. Corre en el servidor para que la vean todos.
local function playSwing(tool: Tool, character: Model)
	if swinging[tool] then
		return
	end
	swinging[tool] = true

	playCustomAnimation(character)

	local swing = Config.SWING

	local baseGrip = tool:GetAttribute("BaseGrip")
	if typeof(baseGrip) ~= "CFrame" then
		baseGrip = tool.Grip
		tool:SetAttribute("BaseGrip", baseGrip)
	end

	-- El Grip en reposo ya viene inclinado REST_ANGLE, asi que los angulos del golpe
	-- se aplican restando esa inclinacion (asi siguen siendo angulos absolutos).
	local rest = Config.PICKAXE.REST_ANGLE
	local raised = baseGrip * pitch(swing.START_ANGLE - rest)
	local struck = baseGrip * pitch(computeStrikeAngle(character) - rest)

	task.spawn(function()
		lerpGrip(tool, baseGrip, raised, swing.RAISE_TIME)
		lerpGrip(tool, raised, struck, swing.STRIKE_TIME)
		task.wait(swing.HOLD_TIME)
		lerpGrip(tool, struck, baseGrip, swing.RETURN_TIME)
		tool.Grip = baseGrip
		swinging[tool] = nil
	end)
end

--------------------------------------------------------------------------------
-- Efecto del golpe
--------------------------------------------------------------------------------

-- Agujero que queda marcado donde se pico y desaparece a los HOLE.LIFETIME segundos
local function spawnHole(position: Vector3, normal: Vector3, zoneName: string)
	local cfg = Config.HOLE
	if not cfg.ENABLED then
		return
	end

	local color = cfg.COLOR
	if cfg.USE_ZONE_COLOR then
		local zoneColor = Config.ZONE_COLORS[zoneName]
		if zoneColor then
			color = zoneColor:Lerp(Color3.new(0, 0, 0), cfg.DARKEN)
		end
	end

	local hole = Instance.new("Part")
	hole.Name = "PickaxeHole"
	hole.Shape = Enum.PartType.Cylinder
	hole.Size = Vector3.new(cfg.DEPTH, cfg.SIZE, cfg.SIZE)
	hole.Color = color
	hole.Material = cfg.MATERIAL
	hole.Anchored = true
	hole.CanCollide = false
	hole.CanQuery = false -- para que no estorbe a los raycast de las zonas
	hole.CanTouch = false
	hole.CastShadow = false

	-- El cilindro tiene el eje en X, se gira 90 grados para alinearlo con la normal.
	-- Se apoya justo sobre la superficie para que se vea como un hueco oscuro.
	hole.CFrame = CFrame.lookAt(position + normal * (cfg.DEPTH * 0.4), position + normal)
		* CFrame.fromEulerAnglesXYZ(0, math.rad(90), 0)
	hole.Parent = workspace

	Debris:AddItem(hole, cfg.LIFETIME)
end

-- Chispas en el punto golpeado, con el color de la zona.
-- Se usa un Attachment dentro de la propia zona (no hace falta crear partes extra).
local function playHitEffect(host: BasePart, position: Vector3, zoneName: string)
	local attachment = Instance.new("Attachment")
	attachment.Name = "PickaxeHit"
	attachment.WorldPosition = position
	attachment.Parent = host

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Config.ZONE_COLORS[zoneName] or Color3.new(1, 1, 1))
	emitter.Lifetime = NumberRange.new(0.25, 0.45)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.25)
	emitter.Parent = attachment
	emitter:Emit(18)

	if Config.HIT_SOUND_ID ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = Config.HIT_SOUND_ID
		sound.RollOffMaxDistance = 80
		sound.Parent = attachment
		sound:Play()
	end

	Debris:AddItem(attachment, 2)
end

--------------------------------------------------------------------------------
-- Picazo (peticion del cliente)
--------------------------------------------------------------------------------

local lastSwing = {} -- lastSwing[player] = os.clock()

local function isWithinReach(character: Model, target: BasePart, hitPosition: Vector3): boolean
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end

	-- Cerca del punto golpeado y cerca de la propia zona (las zonas suelen ser enormes)
	if (root.Position - hitPosition).Magnitude > Config.MAX_REACH then
		return false
	end

	local toPart = (root.Position - target.Position).Magnitude - target.Size.Magnitude * 0.5
	return toPart <= Config.MAX_REACH
end

swingRemote.OnServerEvent:Connect(function(player: Player, target: any, hitPosition: any)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- La herramienta debe estar equipada (dentro del personaje)
	local tool = character:FindFirstChild(Config.TOOL_NAME)
	if not tool or not tool:IsA("Tool") then
		return
	end

	-- Cooldown del lado servidor (el cliente no manda)
	local now = os.clock()
	if lastSwing[player] and now - lastSwing[player] < Config.SWING_COOLDOWN then
		return
	end
	lastSwing[player] = now

	-- Siempre se ve el picazo, aunque no haya zona valida
	playSwing(tool, character)

	-- 1) Zona apuntada con el mouse (validando alcance)
	local zoneName, reward, effectHost, effectPosition, effectNormal

	if typeof(target) == "Instance" and target:IsA("BasePart") and typeof(hitPosition) == "Vector3" then
		if isWithinReach(character, target, hitPosition) then
			zoneName, reward = findZone(target)
			if zoneName then
				effectHost, effectPosition = target, hitPosition
				effectNormal = surfaceNormalAt(target, hitPosition)
			end
		end
	end

	-- 2) Si no apunto a una zona, se usa la zona donde esta parado
	if not zoneName then
		zoneName, reward, effectHost, effectPosition, effectNormal = findZoneUnderCharacter(character)
	end

	if not zoneName or not reward then
		return
	end

	addMoney(player, reward)

	-- Cartel flotante (+1, +5, ...) en un punto random alrededor del jugador
	MoneyPopup.show(character, reward)

	if effectHost and effectPosition then
		playHitEffect(effectHost, effectPosition, zoneName)
		spawnHole(effectPosition, effectNormal or Vector3.yAxis, zoneName)
	end
end)

--------------------------------------------------------------------------------
-- Jugadores
--------------------------------------------------------------------------------

local function givePickaxe(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		backpack = player:WaitForChild("Backpack", 10)
	end
	if not backpack then
		return
	end

	local character = player.Character
	if backpack:FindFirstChild(Config.TOOL_NAME) then
		return
	end
	if character and character:FindFirstChild(Config.TOOL_NAME) then
		return
	end

	local tool = pickaxeTemplate:Clone()
	tool.Parent = backpack
end

local function onPlayerAdded(player: Player)
	setupMoney(player)

	player.CharacterAdded:Connect(function()
		task.defer(givePickaxe, player)
	end)

	if player.Character then
		task.defer(givePickaxe, player)
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
