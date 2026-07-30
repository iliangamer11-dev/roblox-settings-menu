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
local Minerals = require(script.Parent:WaitForChild("Minerals"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))
local Passes = require(script.Parent:WaitForChild("Passes"))

--------------------------------------------------------------------------------
-- Remote
--------------------------------------------------------------------------------

local function ensureRemote(name: string): RemoteEvent
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote or not remote:IsA("RemoteEvent") then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end
	return remote
end

local swingRemote = ensureRemote(Config.REMOTE_NAME)
local holeRemote = ensureRemote(Config.HOLE_REMOTE_NAME)
local autoRemote = ensureRemote(Config.AUTO_REMOTE_NAME)

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

	-- Columna para el [VIP] en la lista de jugadores.
	-- Roblox no deja cambiar la columna del nombre, asi que el tag va en su propia
	-- columna, justo a la izquierda del dinero.
	local tag = leaderstats:FindFirstChild(Config.LEADERSTATS_TAG_NAME)
	if not tag then
		tag = Instance.new("StringValue")
		tag.Name = Config.LEADERSTATS_TAG_NAME
		tag.Value = ""
		tag.Parent = leaderstats
	end
end

-- Pone o quita el [VIP] de la lista de jugadores
local function refreshTag(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local tag = leaderstats and leaderstats:FindFirstChild(Config.LEADERSTATS_TAG_NAME)
	if not tag or not tag:IsA("StringValue") then
		return
	end

	local prefix = Config.PASS_EFFECTS.VIP_NAME_PREFIX
	tag.Value = Passes.has(player, "VIP") and string.gsub(prefix, "%s+$", "") or ""
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
		local multiplier = Config.ZONE_MULTIPLIERS[current.Name]
		if multiplier then
			return current.Name, multiplier
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



--------------------------------------------------------------------------------
-- Animacion del picazo
--------------------------------------------------------------------------------

local swinging = {} -- swinging[tool] = true mientras la animacion corre

-- Rotacion sobre el eje X del agarre: es lo que baja la punta del pico hacia el suelo.
-- Angulos absolutos: 0 = mango horizontal, negativo = arriba, positivo = abajo.
local function pitch(degrees: number): CFrame
	return CFrame.fromEulerAnglesXYZ(math.rad(degrees * Config.SWING.AXIS_SIGN), 0, 0)
end

-- Se interpola el ANGULO, no el CFrame: CFrame:Lerp siempre coge el camino mas corto,
-- y como el recorrido del picazo pasa de 180 grados, el pico giraria hacia atras.
local function sweepGrip(tool: Tool, base: CFrame, fromAngle: number, toAngle: number, duration: number)
	if duration <= 0 then
		tool.Grip = base * pitch(toAngle)
		return
	end

	local elapsed = 0
	while elapsed < duration do
		local dt = RunService.Heartbeat:Wait()
		if not tool.Parent then
			return
		end
		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		tool.Grip = base * pitch(fromAngle + (toAngle - fromAngle) * alpha)
	end
	tool.Grip = base * pitch(toAngle)
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

-- Cuanto tarda la punta del pico en llegar al suelo desde el click
local function impactDelay(): number
	local swing = Config.SWING
	return swing.RAISE_TIME + swing.STRIKE_TIME
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
	local ratio = height / swing.HEAD_REACH

	-- El suelo queda mas abajo de lo que alcanza la punta: giro completo hasta clavarla
	if ratio >= 1 then
		return swing.MAX_ANGLE
	end

	-- La punta baja HEAD_REACH * sin(angulo), asi que este es el angulo justo para tocar
	local angle = math.deg(math.asin(math.max(ratio, 0)))

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
	local rest = Config.PICKAXE.REST_ANGLE

	-- BaseGrip es el agarre "neutro" (mango horizontal, angulo 0). El Grip que trae la
	-- Tool ya viene con la inclinacion de reposo, asi que se le quita para guardarlo.
	local baseGrip = tool:GetAttribute("BaseGrip")
	if typeof(baseGrip) ~= "CFrame" then
		baseGrip = tool.Grip * pitch(-rest)
		tool:SetAttribute("BaseGrip", baseGrip)
	end

	local strikeAngle = computeStrikeAngle(character)

	task.spawn(function()
		sweepGrip(tool, baseGrip, rest, swing.START_ANGLE, swing.RAISE_TIME)
		sweepGrip(tool, baseGrip, swing.START_ANGLE, strikeAngle, swing.STRIKE_TIME)
		task.wait(swing.HOLD_TIME)
		sweepGrip(tool, baseGrip, strikeAngle, rest, swing.RETURN_TIME)
		tool.Grip = baseGrip * pitch(rest)
		swinging[tool] = nil
	end)
end

--------------------------------------------------------------------------------
-- Efecto del golpe
--------------------------------------------------------------------------------

-- El agujero lo dibuja el propio cliente que ha picado (ver HoleClient), asi cada
-- jugador ve solo sus agujeros y no los de los demas. Aqui solo se le manda el aviso.
local function sendHole(player: Player, position: Vector3, normal: Vector3, mineral: any)
	local cfg = Config.HOLE
	if not cfg.ENABLED then
		return
	end

	local color = cfg.COLOR
	if cfg.USE_MINERAL_COLOR and mineral and mineral.COLOR then
		color = mineral.COLOR:Lerp(Color3.new(0, 0, 0), cfg.DARKEN)
	end

	holeRemote:FireClient(player, position, normal, color, mineral ~= nil and mineral.RAINBOW == true)
end

-- Chispas en el punto golpeado, del color del mineral que ha salido.
-- Se usa un Attachment dentro de la propia zona (no hace falta crear partes extra).
local function playHitEffect(host: BasePart, position: Vector3, mineral: any)
	local attachment = Instance.new("Attachment")
	attachment.Name = "PickaxeHit"
	attachment.WorldPosition = position
	attachment.Parent = host

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(mineral and mineral.COLOR or Color3.new(1, 1, 1))
	emitter.Lifetime = NumberRange.new(0.25, 0.45)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.25)
	emitter.Parent = attachment

	-- El legendario suelta bastante mas, para que se note el hallazgo
	emitter:Emit(mineral and mineral.RAINBOW and 60 or 18)

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
local hitsSinceMineral = {} -- hitsSinceMineral[player] = golpes dados sin sacar mineral

-- Donde golpea el pico: justo delante del personaje, a la distancia que alcanza la punta.
-- No se usa el cursor a proposito: el agujero tiene que salir donde cae el pico.
local function findStrikePoint(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil, nil, nil
	end

	local swing = Config.SWING
	local origin = root.Position + root.CFrame.LookVector * swing.HIT_OFFSET + Vector3.new(0, 1, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, Vector3.new(0, -(Config.GROUND_CHECK_DISTANCE + 1), 0), params)
	if not result then
		return nil, nil, nil
	end

	return result.Instance, result.Position, result.Normal
end

-- Un picazo completo. La usan el click del jugador y el gamepass Auto Swing.
local function performSwing(player: Player)
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

	-- Cooldown del lado servidor (el cliente no manda). Fast Pickaxe lo acorta.
	local now = os.clock()
	if lastSwing[player] and now - lastSwing[player] < Passes.cooldown(player) then
		return
	end
	lastSwing[player] = now

	-- Siempre se ve el picazo, aunque no haya zona valida
	playSwing(tool, character)

	-- 1) Donde cae el pico: delante del personaje
	local zoneName, effectHost, effectPosition, effectNormal

	local strikeHost, strikePosition, strikeNormal = findStrikePoint(character)
	if strikeHost then
		zoneName = findZone(strikeHost)
		if zoneName then
			effectHost, effectPosition, effectNormal = strikeHost, strikePosition, strikeNormal
		end
	end

	-- 2) Si delante no hay zona (borde, rampa, un objeto encima...), se usa la que pisa,
	-- pero el efecto se deja igual en el punto donde cayo el pico
	if not zoneName then
		local standHost, standPosition, standNormal
		zoneName, _, standHost, standPosition, standNormal = findZoneUnderCharacter(character)
		if zoneName then
			effectHost = strikeHost or standHost
			effectPosition = strikePosition or standPosition
			effectNormal = strikeNormal or standNormal
		end
	end

	if not zoneName then
		return
	end

	-- Hacen falta varios picazos por mineral: los golpes intermedios solo hacen
	-- chispas y agujero, sin dinero ni cartel.
	local needed = math.max(1, Config.HITS_PER_MINERAL)
	hitsSinceMineral[player] = (hitsSinceMineral[player] or 0) + 1

	if hitsSinceMineral[player] < needed then
		task.delay(impactDelay(), function()
			if effectHost and effectHost.Parent and effectPosition then
				playHitEffect(effectHost, effectPosition, nil)
				sendHole(player, effectPosition, effectNormal or Vector3.yAxis, nil)
			end
		end)
		return
	end

	hitsSinceMineral[player] = 0

	-- Que mineral ha salido (Lucky Ores sube la suerte) y cuanto vale en esta zona
	local mineral = Minerals.roll(Passes.luck(player))
	local reward = Minerals.getReward(mineral, zoneName)

	-- X2 Money (y VIP, que lo incluye)
	local multiplier = Passes.moneyMultiplier(player)
	if multiplier ~= 1 then
		reward = math.floor(reward * multiplier)
	end

	addMoney(player, reward)

	-- La experiencia se gana al picar (no depende del dinero que tengas), asi gastar
	-- en las paredes no baja el nivel.
	LevelService.addXp(player, Config.LEVEL.XP_FROM_BASE_VALUE and mineral.MONEY or reward)

	if Config.DEBUG then
		print(
			string.format(
				"[Mining] %s pico %s en %s (x%d) => +%s",
				player.Name,
				mineral.NAME,
				zoneName,
				Config.ZONE_MULTIPLIERS[zoneName] or 1,
				Minerals.format(reward)
			)
		)
	end

	-- Los efectos salen en el instante en que la punta toca el suelo, no al hacer click.
	-- El retardo se calcula solo con las duraciones de la animacion, asi que si cambias
	-- RAISE_TIME o STRIKE_TIME sigue quedando sincronizado.
	task.delay(impactDelay(), function()
		if not character.Parent or humanoid.Health <= 0 then
			return
		end

		-- Cartel flotante con el color del mineral, en un punto random alrededor del jugador
		MoneyPopup.show(character, reward, mineral)

		if effectHost and effectHost.Parent and effectPosition then
			playHitEffect(effectHost, effectPosition, mineral)
			sendHole(player, effectPosition, effectNormal or Vector3.yAxis, mineral)
		end
	end)
end

swingRemote.OnServerEvent:Connect(performSwing)

--------------------------------------------------------------------------------
-- Auto Swing (gamepass)
--------------------------------------------------------------------------------

local autoLoops = {} -- autoLoops[player] = true si ya tiene el bucle corriendo
local autoEnabled = {} -- autoEnabled[player] = si lo tiene encendido con el boton

-- El boton solo enciende o apaga. Aunque alguien falsee el remote, lo unico que
-- consigue es activar su propio auto swing, y solo si tiene el gamepass.
autoRemote.OnServerEvent:Connect(function(player: Player, value: any)
	autoEnabled[player] = value ~= false
end)

local function startAutoSwing(player: Player)
	if autoLoops[player] then
		return
	end
	autoLoops[player] = true

	if autoEnabled[player] == nil then
		autoEnabled[player] = true -- por defecto encendido al comprarlo
	end

	task.spawn(function()
		while player.Parent and Passes.autoSwing(player) do
			-- performSwing ya comprueba personaje, pico equipado, cooldown y zona,
			-- asi que el auto swing no puede dar mas dinero que picando a mano
			if autoEnabled[player] then
				performSwing(player)
			end

			task.wait(Passes.cooldown(player))
		end

		autoLoops[player] = nil
	end)
end

-- Al entrar y al comprar un pase
Passes.Changed.Event:Connect(function(player: Player)
	refreshTag(player)

	if Passes.autoSwing(player) then
		startAutoSwing(player)
	end
end)

--------------------------------------------------------------------------------
-- Jugadores
--------------------------------------------------------------------------------

-- El pico se queda pegado a la mano: si algo lo desequipa, se vuelve a equipar.
local function keepEquipped(tool: Tool, player: Player)
	if not Config.ALWAYS_EQUIPPED or tool:GetAttribute("AlwaysEquipped") then
		return
	end
	tool:SetAttribute("AlwaysEquipped", true)

	tool.Unequipped:Connect(function()
		-- defer para dejar que Roblox termine de moverlo a la mochila
		task.defer(function()
			local character = player.Character
			if not character or not tool.Parent then
				return
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 and tool.Parent ~= character then
				tool.Parent = character
			end
		end)
	end)
end

local function equipPickaxe(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- Ya lo tiene en la mano
	local tool = character:FindFirstChild(Config.TOOL_NAME)
	if tool and tool:IsA("Tool") then
		keepEquipped(tool, player)
		return
	end

	-- Reutiliza el que tenga en la mochila, si es que hay
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 10)
	local existing = backpack and backpack:FindFirstChild(Config.TOOL_NAME)

	local newTool = (existing and existing:IsA("Tool")) and existing or pickaxeTemplate:Clone()

	keepEquipped(newTool, player)

	-- Parentarlo al personaje es lo que lo equipa
	newTool.Parent = character
end

local function onPlayerAdded(player: Player)
	setupMoney(player)
	LevelService.setup(player)
	Passes.setup(player) -- comprueba los gamepasses que tiene

	player.CharacterAdded:Connect(function()
		-- se espera un momento a que el rig este listo antes de equipar
		task.delay(0.3, equipPickaxe, player)
	end)

	if player.Character then
		task.delay(0.3, equipPickaxe, player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	money[player] = nil
	lastSwing[player] = nil
	hitsSinceMineral[player] = nil
	LevelService.clear(player)
	Passes.clear(player)
	autoEnabled[player] = nil
end)
