--[[
	PickaxeTool
	Construye la herramienta "Pickaxe" por codigo, con el mango a lo largo del eje Z.
	La punta del pico apunta hacia -Z, asi el picazo (giro sobre el eje X) la baja
	hacia el suelo.
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
	local settings = Config.PICKAXE

	local tool = Instance.new("Tool")
	tool.Name = Config.TOOL_NAME
	tool.ToolTip = "Pica el suelo para ganar " .. Config.MONEY_NAME
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	-- Mango: largo sobre el eje Z
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = settings.HANDLE_SIZE
	handle.Color = settings.HANDLE_COLOR
	handle.Material = Enum.Material.Wood
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	-- La cabeza se cruza en la punta delantera del mango (-Z)
	local headZ = -(settings.HANDLE_SIZE.Z / 2 - settings.HEAD_SIZE.X / 2)
	local headAngle = math.rad(settings.HEAD_ANGLE)
	local headLength = settings.HEAD_SIZE.Y

	-- side = 1 -> punta de arriba, side = -1 -> punta de abajo (la que golpea el suelo).
	-- Las dos barras van sobre el eje Y y se echan hacia atras (+Z) para dar la curva del pico.
	local function makeHead(name: string, side: number)
		local head = Instance.new("Part")
		head.Name = name
		head.Size = settings.HEAD_SIZE
		head.Color = settings.HEAD_COLOR
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
		return head
	end

	makeHead("HeadUp", 1)
	makeHead("HeadDown", -1)

	-- Punto de agarre: la mano toma el mango por detras (Z positivo) y el pico queda
	-- un poco levantado en reposo (REST_ANGLE).
	local rotation = settings.GRIP_ROTATION
	tool.Grip = CFrame.new(settings.GRIP_OFFSET)
		* CFrame.fromEulerAnglesXYZ(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		* CFrame.fromEulerAnglesXYZ(math.rad(settings.REST_ANGLE * Config.SWING.AXIS_SIGN), 0, 0)

	return tool
end

return PickaxeTool
