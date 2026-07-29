--[[
	SetHojas1Morado

	Pone de color morado todo lo que se llame "Hojas1" en el Workspace.
	Funciona si Hojas1 es una Part sola o un Model/Folder con partes dentro.

	INSTALACION:
	ServerScriptService > Insert Object > Script, y pega este codigo.
]]

local TARGET_NAME = "Hojas1"
local PURPLE = Color3.fromRGB(120, 60, 190)

-- Si quieres que ademas se vean como hojas moradas, pon true
local CHANGE_MATERIAL = false
local MATERIAL = Enum.Material.Grass

local function paint(instance)
	local painted = 0

	if instance:IsA("BasePart") then
		instance.Color = PURPLE
		if CHANGE_MATERIAL then
			instance.Material = MATERIAL
		end
		painted += 1
	end

	-- Si es un Model o Folder, se pintan todas las partes de dentro
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = PURPLE
			if CHANGE_MATERIAL then
				descendant.Material = MATERIAL
			end
			painted += 1
		end
	end

	return painted
end

local total = 0
local found = 0

for _, descendant in workspace:GetDescendants() do
	if descendant.Name == TARGET_NAME then
		found += 1
		total += paint(descendant)
	end
end

if found == 0 then
	warn('[Hojas1] No se encontro nada llamado "' .. TARGET_NAME .. '" en Workspace. Revisa el nombre exacto (mayusculas incluidas).')
else
	print(string.format("[Hojas1] %d objeto(s) encontrados, %d parte(s) pintadas de morado", found, total))
end
