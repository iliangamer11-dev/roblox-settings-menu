--[[
	PickaxeClient (LocalScript en StarterPlayer > StarterPlayerScripts)

	Detecta el click izquierdo con el Pickaxe equipado (Tool.Activated) y le avisa
	al servidor a que parte le esta apuntando. El servidor valida, hace la
	animacion del picazo y suma el money.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local swingRemote = ReplicatedStorage:WaitForChild(Config.REMOTE_NAME)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local lastSwing = 0

local function requestSwing()
	local now = os.clock()
	if now - lastSwing < Config.SWING_COOLDOWN then
		return
	end
	lastSwing = now

	local target = mouse.Target
	local hitPosition = mouse.Hit and mouse.Hit.Position or nil
	swingRemote:FireServer(target, hitPosition)
end

-- Tool.Activated = click izquierdo (o tap en movil) con la herramienta equipada
local connectedTools = setmetatable({}, { __mode = "k" })

local function hookTool(child: Instance)
	if not child:IsA("Tool") or child.Name ~= Config.TOOL_NAME then
		return
	end
	if connectedTools[child] then
		return
	end
	connectedTools[child] = true
	child.Activated:Connect(requestSwing)
end

local function watch(container: Instance)
	for _, child in container:GetChildren() do
		hookTool(child)
	end
	container.ChildAdded:Connect(hookTool)
end

local function onCharacterAdded(character: Model)
	mouse.TargetFilter = character -- no apuntar al propio personaje
	watch(character)

	local backpack = player:WaitForChild("Backpack", 10)
	if backpack then
		watch(backpack)
	end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
