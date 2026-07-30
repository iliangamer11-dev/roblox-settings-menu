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

-- Escala toda la interfaz de un ScreenGui segun el tamano de la pantalla, para que se
-- vea bien en movil, tablet, monitor y 4K. Se mete un UIScale en cada elemento de
-- primer nivel y se recalcula cuando cambia la resolucion.
-- Los AnchorPoint ya colocan cada cosa respecto a su borde, asi que el escalado no
-- descoloca nada.
function UiTheme.autoScale(gui: ScreenGui)
	local settings = theme.SCALE
	local scales = {}

	local function ensure(child: Instance)
		if child:IsA("GuiObject") and not child:FindFirstChildOfClass("UIScale") then
			local scale = Instance.new("UIScale")
			scale.Parent = child
			table.insert(scales, scale)
		end
	end

	local function update()
		-- AbsoluteSize del ScreenGui es el tamano util de la pantalla
		local viewport = gui.AbsoluteSize
		if viewport.X <= 0 or viewport.Y <= 0 then
			return
		end

		local factor = math.min(viewport.X / settings.REFERENCE.X, viewport.Y / settings.REFERENCE.Y)
		factor = math.clamp(factor, settings.MIN, settings.MAX)

		for _, scale in scales do
			scale.Scale = factor
		end
	end

	for _, child in gui:GetChildren() do
		ensure(child)
	end

	gui.ChildAdded:Connect(function(child)
		ensure(child)
		update()
	end)

	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	update()
end

-- Degradado vertical (de TOP arriba a BOTTOM abajo) sobre un texto
function UiTheme.gradient(label: Instance, top: Color3, bottom: Color3): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(1, bottom),
	})
	gradient.Parent = label
	return gradient
end

-- Posicion de los botones del HUD en fila: 0 = ajustes, 1 = tienda, 2 = tags...
-- Se calcula desde SETTINGS_BUTTON, y si el HUD esta a la derecha crecen hacia la
-- izquierda para no salirse de la pantalla.
function UiTheme.hudSlotX(slot: number): number
	local settingsCfg = Config.SETTINGS_BUTTON
	local gap = Config.SHOP_BUTTON.GAP_X
	local side = settingsCfg.ANCHOR.X >= 0.5 and -1 or 1

	return settingsCfg.POSITION.X.Offset + side * slot * (settingsCfg.SIZE.X.Offset + gap)
end

-- Boton del HUD completo: cuadro con doble contorno, icono pulsable y texto debajo.
-- Devuelve el ImageButton (para conectar el clic).
function UiTheme.hudButton(parent: Instance, slot: number, iconId: any, labelText: string): ImageButton
	local settingsCfg = Config.SETTINGS_BUTTON
	local x = UiTheme.hudSlotX(slot)

	local position =
		UDim2.new(settingsCfg.POSITION.X.Scale, x, settingsCfg.POSITION.Y.Scale, settingsCfg.POSITION.Y.Offset)

	local _, body = UiTheme.framedBox(parent, settingsCfg.SIZE, position, settingsCfg.ANCHOR)

	local icon = Instance.new("ImageButton")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromScale(0.82, 0.82)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Image = UiTheme.assetId(iconId)
	icon.Parent = body

	-- Texto centrado en su propio cuadro, para que no toque el del boton de al lado
	local labelY = settingsCfg.POSITION.Y.Offset + settingsCfg.SIZE.Y.Offset * (1 - settingsCfg.ANCHOR.Y) + 2
	local centerX = x + settingsCfg.SIZE.X.Offset * (0.5 - settingsCfg.ANCHOR.X)

	local label = UiTheme.text(
		parent,
		labelText,
		UDim2.new(0, settingsCfg.SIZE.X.Offset + 8, 0, settingsCfg.LABEL_HEIGHT),
		UDim2.new(settingsCfg.POSITION.X.Scale, centerX, settingsCfg.POSITION.Y.Scale, labelY)
	)
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 0)

	return icon
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
