--[[
	PickaxeClient (LocalScript en StarterPlayer > StarterPlayerScripts)

	Detecta el click izquierdo con el Pickaxe equipado (Tool.Activated) y le avisa al
	servidor. El servidor decide todo: donde cae el pico, la animacion y el dinero.

	No se manda la posicion del cursor a proposito: el golpe cae siempre donde pica el
	pico, delante del personaje.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local swingRemote = ReplicatedStorage:WaitForChild(Config.REMOTE_NAME)

local player = Players.LocalPlayer

-- El pico esta siempre equipado, asi que la mochila/hotbar de Roblox no hace falta.
-- Se reintenta unas veces porque otros scripts pueden volver a activarla.
if Config.HIDE_BACKPACK_GUI then
	task.spawn(function()
		for _ = 1, 8 do
			pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end)
			task.wait(1)
		end
	end)
end

local lastSwing = 0

local function requestSwing()
	local now = os.clock()
	if now - lastSwing < Config.SWING_COOLDOWN then
		return
	end
	lastSwing = now

	swingRemote:FireServer()
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
