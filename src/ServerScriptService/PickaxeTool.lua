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

	local function makeMetalPart(name: string, size: Vector3, cframe: CFrame): Part
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = settings.HEAD_COLOR
		part.Material = Enum.Material.Metal
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CanCollide = false
		part.Massless = true
		part.CFrame = cframe
		part.Parent = tool
		weld(handle, part)
		return part
	end

	-- Collar: va en el extremo delantero del mango (-Z) y lo tapa, de forma que las dos
	-- puntas salen de una pieza solida en vez de flotar pegadas al palo
	local collarZ = -(settings.HANDLE_SIZE.Z / 2 - settings.COLLAR_SIZE.Z / 2)
	makeMetalPart("HeadCollar", settings.COLLAR_SIZE, handle.CFrame * CFrame.new(0, 0, collarZ))

	-- side = 1 -> punta de arriba, side = -1 -> punta de abajo (la que golpea el suelo).
	-- Cada trozo arranca DENTRO del anterior (HEAD_OVERLAP), asi el giro de la union no
	-- deja hueco: el punto de giro queda por dentro de la pieza previa.
	local function makeSpike(name: string, side: number)
		-- Se empieza en el centro del collar, asi el primer trozo tambien queda metido
		local joint = handle.CFrame * CFrame.new(0, 0, collarZ)
		local size = settings.HEAD_SIZE
		local angle = settings.HEAD_START_ANGLE

		for index = 1, settings.HEAD_SEGMENTS do
			joint = joint * CFrame.fromEulerAnglesXYZ(math.rad(angle * side), 0, 0)

			makeMetalPart(string.format("%s%d", name, index), size, joint * CFrame.new(0, side * size.Y / 2, 0))

			-- El siguiente arranca antes del final de este: de ahi el solape
			joint = joint * CFrame.new(0, side * size.Y * (1 - settings.HEAD_OVERLAP), 0)

			size = Vector3.new(
				size.X * settings.HEAD_THICKNESS_TAPER,
				size.Y * settings.HEAD_TAPER,
				size.Z * settings.HEAD_THICKNESS_TAPER
			)
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
