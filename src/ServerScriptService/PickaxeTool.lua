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

	-- Las puntas nacen en el extremo delantero del mango (-Z)
	local headZ = -(settings.HANDLE_SIZE.Z / 2 - settings.HEAD_SIZE.X / 2)

	-- side = 1 -> punta de arriba, side = -1 -> punta de abajo (la que golpea el suelo).
	-- Cada trozo se encadena al final del anterior, girado un poco mas hacia atras (+Z)
	-- y escalado por HEAD_TAPER, de forma que la punta se afila.
	local function makeSpike(name: string, side: number)
		local frame = handle.CFrame * CFrame.new(0, 0, headZ)
		local size = settings.HEAD_SIZE
		local angle = settings.HEAD_START_ANGLE

		for index = 1, settings.HEAD_SEGMENTS do
			frame = frame * CFrame.fromEulerAnglesXYZ(math.rad(angle * side), 0, 0)

			local segment = Instance.new("Part")
			segment.Name = string.format("%s%d", name, index)
			segment.Size = size
			segment.Color = settings.HEAD_COLOR
			segment.Material = Enum.Material.Metal
			segment.TopSurface = Enum.SurfaceType.Smooth
			segment.BottomSurface = Enum.SurfaceType.Smooth
			segment.CanCollide = false
			segment.Massless = true
			segment.CFrame = frame * CFrame.new(0, side * size.Y / 2, 0)
			segment.Parent = tool
			weld(handle, segment)

			-- Siguiente trozo: se parte del final de este, mas pequeno y mas girado
			frame = frame * CFrame.new(0, side * size.Y, 0)
			size = size * settings.HEAD_TAPER
			angle = settings.HEAD_CURVE
		end
	end

	makeSpike("HeadUp", 1)
	makeSpike("HeadDown", -1)

	-- Punto de agarre: la mano toma el mango por detras (Z positivo) y el pico queda
	-- un poco levantado en reposo (REST_ANGLE).
	local rotation = settings.GRIP_ROTATION
	tool.Grip = CFrame.new(settings.GRIP_OFFSET)
		* CFrame.fromEulerAnglesXYZ(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		* CFrame.fromEulerAnglesXYZ(math.rad(settings.REST_ANGLE * Config.SWING.AXIS_SIGN), 0, 0)

	return tool
end

return PickaxeTool
