--[[
	Hojas1CambiaColor

	Hace que la part "Hojas1" vaya cambiando de color suavemente, en bucle.

	INSTALACION:
	ServerScriptService > Insert Object > Script, y pega este codigo.

	Nota: esta dentro de DecoracionNaturaleza > Arboles, pero el script la busca
	en todo el Workspace, asi que no importa donde la muevas.
]]

local TweenService = game:GetService("TweenService")

local TARGET_NAME = "Hojas1"

-- Colores por los que va pasando (puedes agregar o quitar los que quieras)
local COLORS = {
	Color3.fromRGB(120, 60, 190), -- morado
	Color3.fromRGB(80, 190, 100), -- verde
	Color3.fromRGB(240, 190, 70), -- amarillo
	Color3.fromRGB(230, 90, 90), -- rojo
	Color3.fromRGB(80, 150, 235), -- azul
}

local FADE_TIME = 1.5 -- cuanto tarda en pasar de un color al otro
local HOLD_TIME = 0.5 -- cuanto se queda quieto en cada color

--------------------------------------------------------------------------------

-- Junta todas las partes que hay que pintar.
-- Si Hojas1 es una Part, se pinta esa. Si fuera un Model/Folder, todas las de dentro.
local function collectParts()
	local parts = {}

	for _, descendant in workspace:GetDescendants() do
		if descendant.Name == TARGET_NAME then
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
			for _, inner in descendant:GetDescendants() do
				if inner:IsA("BasePart") then
					table.insert(parts, inner)
				end
			end
		end
	end

	return parts
end

local parts = collectParts()

if #parts == 0 then
	warn('[Hojas1] No se encontro ninguna part llamada "' .. TARGET_NAME .. '" en Workspace. Revisa el nombre exacto.')
	return
end

print(string.format("[Hojas1] %d part(s) encontradas, empezando el cambio de color", #parts))

local tweenInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local index = 0

while true do
	index = index % #COLORS + 1
	local color = COLORS[index]

	for i = #parts, 1, -1 do
		local part = parts[i]
		if part.Parent then
			TweenService:Create(part, tweenInfo, { Color = color }):Play()
		else
			table.remove(parts, i) -- la borraron del mapa
		end
	end

	if #parts == 0 then
		warn("[Hojas1] Ya no queda ninguna part, se detiene el cambio de color.")
		break
	end

	task.wait(FADE_TIME + HOLD_TIME)
end
