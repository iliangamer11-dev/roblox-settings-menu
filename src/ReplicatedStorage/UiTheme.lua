--[[
	UiTheme
	Piezas de interfaz con el estilo comun: gris con opacidad, contorno blanco muy fino
	por dentro, contorno negro por fuera y esquinas redondeadas.

	Esta aqui para que el boton de ajustes, el panel y el cartel de dinero usen
	exactamente el mismo estilo sin repetir codigo.

	Colores y grosores en MiningConfig.UI_THEME.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))

local UiTheme = {}

local theme = Config.UI_THEME
UiTheme.theme = theme

-- Acepta "rbxassetid://123", "123" o "" (vacio = sin imagen)
function UiTheme.assetId(value: any): string
	if typeof(value) ~= "string" or value == "" then
		return ""
	end

	local digits = string.match(value, "^%s*(%d+)%s*$")
	return digits and ("rbxassetid://" .. digits) or value
end

function UiTheme.corner(parent: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

function UiTheme.stroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function UiTheme.textOutline(label: Instance): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.TEXT_OUTLINE
	stroke.Thickness = theme.TEXT_OUTLINE_THICKNESS
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return stroke
end

-- Cuadro con doble contorno. Hacen falta dos Frames porque un objeto solo admite
-- un UIStroke: el de fuera lleva el negro y el de dentro el blanco fino.
-- Devuelve (marco exterior, cuerpo donde va el contenido).
function UiTheme.framedBox(parent: Instance, size: UDim2, position: UDim2, anchor: Vector2): (Frame, Frame)
	local outer = Instance.new("Frame")
	outer.Name = "Outline"
	outer.BackgroundTransparency = 1
	outer.Size = size
	outer.Position = position
	outer.AnchorPoint = anchor
	outer.Parent = parent
	UiTheme.corner(outer, theme.CORNER_RADIUS + 2)
	UiTheme.stroke(outer, theme.OUTER_OUTLINE, theme.OUTER_THICKNESS)

	local inner = Instance.new("Frame")
	inner.Name = "Body"
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.new(1, -theme.OUTER_THICKNESS, 1, -theme.OUTER_THICKNESS)
	inner.BackgroundColor3 = theme.BACKGROUND
	inner.BackgroundTransparency = theme.BACKGROUND_TRANSPARENCY
	inner.BorderSizePixel = 0
	inner.Parent = outer
	UiTheme.corner(inner, theme.CORNER_RADIUS)
	UiTheme.stroke(inner, theme.INNER_OUTLINE, theme.INNER_THICKNESS)

	return outer, inner
end

function UiTheme.text(parent: Instance, text: string, size: UDim2, position: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = theme.FONT
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = theme.TEXT_COLOR
	label.Parent = parent
	UiTheme.textOutline(label)
	return label
end

function UiTheme.button(parent: Instance, text: string, size: UDim2, position: UDim2, anchor: Vector2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.AnchorPoint = anchor
	button.BackgroundColor3 = theme.BUTTON_COLOR
	button.BackgroundTransparency = 0.1
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = theme.FONT
	button.TextScaled = true
	button.Text = text
	button.TextColor3 = theme.TEXT_COLOR
	button.Parent = parent
	UiTheme.corner(button, math.max(2, theme.CORNER_RADIUS - 3))
	UiTheme.stroke(button, theme.OUTER_OUTLINE, 2)
	UiTheme.textOutline(button)
	return button
end

return UiTheme
