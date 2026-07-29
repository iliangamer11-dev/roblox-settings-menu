--[[
	ZonesSetup (OPCIONAL)

	Solo para probar rapido: si en Workspace no existe ninguna zona
	(Naturaleza, Desierto, Mina, Luna, Dulces), crea 5 plataformas con esos
	nombres, una al lado de la otra.

	Si ya tienes tus propias zonas construidas, este script no hace nada.
	Si no lo quieres, borralo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))

local ZONE_ORDER = { "Naturaleza", "Desierto", "Mina", "Luna", "Dulces" }
local ZONE_SIZE = Vector3.new(60, 2, 60)
local ZONE_GAP = 10

local function zoneAlreadyExists(): boolean
	for _, descendant in workspace:GetDescendants() do
		if Config.ZONE_MULTIPLIERS[descendant.Name] then
			return true
		end
	end
	return false
end

if zoneAlreadyExists() then
	return
end

local folder = Instance.new("Folder")
folder.Name = "Zonas"
folder.Parent = workspace

for index, zoneName in ZONE_ORDER do
	local part = Instance.new("Part")
	part.Name = zoneName
	part.Size = ZONE_SIZE
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = Config.ZONE_COLORS[zoneName] or Color3.fromRGB(200, 200, 200)
	part.Position = Vector3.new((index - 1) * (ZONE_SIZE.X + ZONE_GAP), 0, 0)
	part.Parent = folder

	local sign = Instance.new("BillboardGui")
	sign.Name = "Etiqueta"
	sign.Size = UDim2.fromScale(14, 3)
	sign.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
	sign.AlwaysOnTop = true
	sign.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = string.format("%s (x%d)", zoneName, Config.ZONE_MULTIPLIERS[zoneName])
	label.Parent = sign
end
