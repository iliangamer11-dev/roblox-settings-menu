--[[
	PICKAXE + MONEY  (VERSION TODO EN UNO)

	INSTALACION:
	1. En Studio, click derecho en ServerScriptService > Insert Object > Script
	2. Pega TODO este codigo dentro
	3. Play

	No necesita ModuleScripts, ni RemoteEvent, ni LocalScript.
	Click izquierdo con el pico equipado = picazo + money segun la zona pisada.

	Naturaleza = 1 | Desierto = 5 | Mina = 10 | Luna = 25 | Dulces = 50
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

local SWING_COOLDOWN = 0.55 -- segundos entre picazos
local GROUND_CHECK_DISTANCE = 12 -- cuanto se busca hacia abajo la zona
local DEBUG = true -- pon false cuando ya funcione

local function log(...)
	if DEBUG then
		print("[Pickaxe]", ...)
	end
end

--------------------------------------------------------------------------------
-- LA HERRAMIENTA (se construye por codigo)
--------------------------------------------------------------------------------

local function weld(partA, partB)
	local joint = Instance.new("Weld")
	joint.Part0 = partA
	joint.Part1 = partB
	joint.C0 = partA.CFrame:Inverse() * partB.CFrame
	joint.C1 = CFrame.new()
	joint.Parent = partA
end

local function buildPickaxe()
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = "Pica el suelo para ganar money"
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 3, 0.3)
	handle.Color = Color3.fromRGB(110, 75, 45)
	handle.Material = Enum.Material.Wood
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local headLeft = Instance.new("Part")
	headLeft.Name = "HeadLeft"
	headLeft.Size = Vector3.new(1.4, 0.35, 0.4)
	headLeft.Color = Color3.fromRGB(160, 160, 165)
	headLeft.Material = Enum.Material.Metal
	headLeft.CanCollide = false
	headLeft.Massless = true
	headLeft.CFrame = CFrame.new(-0.6, 1.4, 0) * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(12))
	headLeft.Parent = tool

	local headRight = Instance.new("Part")
	headRight.Name = "HeadRight"
	headRight.Size = headLeft.Size
	headRight.Color = headLeft.Color
	headRight.Material = headLeft.Material
	headRight.CanCollide = false
	headRight.Massless = true
	headRight.CFrame = CFrame.new(0.6, 1.4, 0) * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(-12))
	headRight.Parent = tool

	weld(handle, headLeft)
	weld(handle, headRight)

	-- Si te queda raro en la mano, ajusta este Grip
	tool.Grip = CFrame.new(0, -1, 0)

	return tool
end

local pickaxeTemplate = buildPickaxe()

-- Copia en StarterPack: asi todos los jugadores la reciben al spawnear
if not StarterPack:FindFirstChild(TOOL_NAME) then
	local starterCopy = pickaxeTemplate:Clone()
	starterCopy.Parent = StarterPack
	log("Pico agregado a StarterPack")
end

--------------------------------------------------------------------------------
-- VARIABLE money
--------------------------------------------------------------------------------

local money = {} -- money[player] = IntValue

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
-- ZONAS
--------------------------------------------------------------------------------

-- Sube por la jerarquia: sirve si la zona es una Part sola o un Model/Folder
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

-- Zona sobre la que esta parado el jugador
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
			return zoneName, reward, result.Instance, result.Position
		end
		log("Piso detectado:", result.Instance:GetFullName(), "- no es una zona valida")
	else
		log("No se detecto piso debajo del jugador")
	end

	return nil, nil, nil, nil
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

local function playSwing(tool)
	if swinging[tool] then
		return
	end
	swinging[tool] = true

	local baseGrip = tool:GetAttribute("BaseGrip")
	if typeof(baseGrip) ~= "CFrame" then
		baseGrip = tool.Grip
		tool:SetAttribute("BaseGrip", baseGrip)
	end

	local raised = baseGrip * CFrame.fromEulerAnglesXYZ(math.rad(75), 0, 0)
	local struck = baseGrip * CFrame.fromEulerAnglesXYZ(math.rad(-60), 0, 0)

	task.spawn(function()
		lerpGrip(tool, baseGrip, raised, 0.12) -- levanta el pico
		lerpGrip(tool, raised, struck, 0.07) -- picazo
		task.wait(0.05)
		lerpGrip(tool, struck, baseGrip, 0.16) -- vuelve
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

	-- El picazo se ve siempre
	playSwing(tool)

	local zoneName, reward, host, position = findZoneUnderCharacter(character)
	if not zoneName then
		return
	end

	local moneyValue = money[player]
	if moneyValue then
		moneyValue.Value += reward
		log(player.Name, "pico en", zoneName, "+" .. reward, "=> money:", moneyValue.Value)
	end

	if host and position then
		playHitEffect(host, position, zoneName)
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

	-- Red de seguridad: si StarterPack no lo entrego, se lo damos aqui
	task.wait(0.5)
	if not backpack:FindFirstChild(TOOL_NAME) and not character:FindFirstChild(TOOL_NAME) then
		local tool = pickaxeTemplate:Clone()
		tool.Parent = backpack
		log("Pico entregado manualmente a", player.Name)
	end

	-- DIAGNOSTICO: 2 segundos despues dice si el pico esta o no en la mochila.
	-- Si dice que SI esta pero no lo ves en la pantalla, el problema es la
	-- interfaz de la mochila (ver PickaxeBackpackFix), no la entrega del pico.
	if DEBUG then
		task.wait(2)
		local names = {}
		for _, child in backpack:GetChildren() do
			table.insert(names, child.Name .. " (" .. child.ClassName .. ")")
		end
		log("Contenido del Backpack de " .. player.Name .. ": " .. (#names > 0 and table.concat(names, ", ") or "VACIO"))

		local hasTool = backpack:FindFirstChild(TOOL_NAME) or character:FindFirstChild(TOOL_NAME)
		if hasTool then
			log("El pico SI existe. Si no lo ves, revisa la interfaz de la mochila.")
		else
			warn("[Pickaxe] El pico fue entregado pero YA NO ESTA: algun otro script de tu juego esta borrando las tools del Backpack.")
		end
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
