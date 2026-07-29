--[[
	PickaxeTool
	Construye la herramienta "Pickaxe" por codigo, asi no hay que armar nada a mano.
	Si prefieres tu propio modelo, mira el README (seccion "Usar tu propio pico").
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))

local PickaxeTool = {}

-- Weld clasico con C0/C1: mantiene el offset exacto aunque la Tool se equipe/desequipe
local function weld(partA: BasePart, partB: BasePart)
	local joint = Instance.new("Weld")
	joint.Name = "PickaxeWeld"
	joint.Part0 = partA
	joint.Part1 = partB
	joint.C0 = partA.CFrame:Inverse() * partB.CFrame
	joint.C1 = CFrame.new()
	joint.Parent = partA
end

function PickaxeTool.build(): Tool
	local tool = Instance.new("Tool")
	tool.Name = Config.TOOL_NAME
	tool.ToolTip = "Pica el suelo para ganar money"
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	-- Mango
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

	-- Cabeza del pico (dos bloques en cruz sobre el mango)
	local headLeft = Instance.new("Part")
	headLeft.Name = "HeadLeft"
	headLeft.Size = Vector3.new(1.4, 0.35, 0.4)
	headLeft.Color = Color3.fromRGB(160, 160, 165)
	headLeft.Material = Enum.Material.Metal
	headLeft.CanCollide = false
	headLeft.Massless = true
	headLeft.CFrame = handle.CFrame * CFrame.new(-0.6, 1.4, 0) * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(12))
	headLeft.Parent = tool

	local headRight = headLeft:Clone()
	headRight.Name = "HeadRight"
	headRight.CFrame = handle.CFrame * CFrame.new(0.6, 1.4, 0) * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(-12))
	headRight.Parent = tool

	weld(handle, headLeft)
	weld(handle, headRight)

	-- Como se agarra: la mano toma el mango cerca de la parte baja.
	-- Si en tu avatar queda raro, ajusta este Grip en Studio (o aqui mismo).
	tool.Grip = CFrame.new(0, -1, 0)

	return tool
end

return PickaxeTool
