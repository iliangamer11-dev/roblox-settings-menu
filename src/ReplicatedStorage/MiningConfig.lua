--[[
	MiningConfig
	Configuracion compartida (cliente + servidor) del sistema de mineria.
	Aqui se ajustan las recompensas, el pico, la animacion y el popup de dinero.
]]

local MiningConfig = {}

-- Nombre de la variable de dinero (aparece en leaderstats como "money")
MiningConfig.MONEY_NAME = "money"
MiningConfig.STARTING_MONEY = 0

-- Nombre de la herramienta
MiningConfig.TOOL_NAME = "Pickaxe"

-- Nombre del RemoteEvent que crea el servidor en ReplicatedStorage
MiningConfig.REMOTE_NAME = "PickaxeSwing"

-- Dinero que suma cada picazo segun la zona (nombre exacto de la Part)
MiningConfig.REWARDS = {
	Naturaleza = 1,
	Desierto = 5,
	Mina = 10,
	Luna = 25,
	Dulces = 50,
}

-- Color de las chispas del picazo por zona
MiningConfig.ZONE_COLORS = {
	Naturaleza = Color3.fromRGB(88, 200, 96),
	Desierto = Color3.fromRGB(235, 200, 120),
	Mina = Color3.fromRGB(170, 170, 175),
	Luna = Color3.fromRGB(150, 170, 230),
	Dulces = Color3.fromRGB(245, 120, 190),
}

-- Agujero que queda marcado donde se pica
MiningConfig.HOLE = {
	ENABLED = true,
	SIZE = 1.6, -- diametro en studs
	DEPTH = 0.15, -- grosor del disco
	COLOR = Color3.fromRGB(38, 32, 28),
	MATERIAL = Enum.Material.Slate,
	LIFETIME = 2, -- segundos que tarda en desaparecer

	-- Si es true, el agujero usa el color de la zona oscurecido en vez de COLOR
	USE_ZONE_COLOR = false,
	DARKEN = 0.55,
}

-- Tiempo minimo entre picazos (segundos)
MiningConfig.SWING_COOLDOWN = 0.55

-- Cuanto se busca hacia abajo para saber sobre que zona esta parado el jugador
MiningConfig.GROUND_CHECK_DISTANCE = 12

--------------------------------------------------------------------------------
-- EL PICO
--------------------------------------------------------------------------------

MiningConfig.PICKAXE = {
	-- El mango va a lo largo del eje Z. La punta del pico queda en -Z.
	HANDLE_SIZE = Vector3.new(0.32, 0.32, 3),
	HANDLE_COLOR = Color3.fromRGB(110, 75, 45),

	-- La cabeza son dos barras a lo largo del eje Y (una punta arriba y otra abajo),
	-- o sea en el mismo plano en el que baja el picazo.
	HEAD_SIZE = Vector3.new(0.4, 0.85, 0.5), -- (grosor X, largo de la punta Y, grosor Z)
	HEAD_COLOR = Color3.fromRGB(160, 160, 165),
	-- 0 = cabeza recta, perpendicular al mango (en T). Sube el valor si quieres las
	-- puntas echadas hacia atras (curva de pico clasico).
	HEAD_ANGLE = 0,

	-- Donde agarra la mano el mango (offset dentro del propio mango, en studs).
	-- Z positivo = mas atras en el mango.
	GRIP_OFFSET = Vector3.new(0, 0, 1.3),
	-- Rotacion del agarre en grados (X, Y, Z). Cambialo si te queda raro en la mano.
	GRIP_ROTATION = Vector3.new(0, 0, 0),
	-- Inclinacion en reposo. 0 = pico totalmente recto (mango horizontal).
	-- Negativo lo levanta, positivo lo baja.
	REST_ANGLE = 0,
}

--------------------------------------------------------------------------------
-- ANIMACION DEL PICAZO
--------------------------------------------------------------------------------

MiningConfig.SWING = {
	-- El pico gira sobre el punto donde lo agarra la mano, bajando hasta tocar el suelo.
	START_ANGLE = -22, -- grados: pequeno amago hacia arriba antes del golpe (0 = sin amago)
	MAX_ANGLE = 95, -- limite hacia abajo. Pasa un poco de la vertical para clavar la punta
	-- Studs desde el punto de agarre hasta la punta del pico.
	-- Con el mango por defecto: 1.3 (agarre) + 1.5 (medio mango) = 2.8
	HEAD_REACH = 2.8,

	RAISE_TIME = 0.14, -- levantar
	STRIKE_TIME = 0.08, -- bajar (el picazo)
	HOLD_TIME = 0.06, -- quedarse clavado un instante
	RETURN_TIME = 0.18, -- volver a la posicion normal

	-- Si el pico gira al lado contrario en tu avatar, pon -1
	AXIS_SIGN = 1,

	-- A cuantos studs delante del jugador cae la punta del pico.
	-- Aqui es donde salen las chispas y el agujero (NO donde apunta el cursor).
	HIT_OFFSET = 2.2,
}

--------------------------------------------------------------------------------
-- POPUP DE DINERO (ImageLabel + TextLabel)
--------------------------------------------------------------------------------

MiningConfig.POPUP = {
	ENABLED = true,

	-- Tu icono. Ej: "rbxassetid://1234567890"
	-- Si pones solo el numero ("1234567890") tambien vale, se le agrega el prefijo.
	-- Si lo dejas vacio se dibuja un circulo del color de abajo.
	IMAGE_ID = "",
	IMAGE_COLOR = Color3.fromRGB(255, 210, 60),
	IMAGE_TRANSPARENCY = 0,

	-- Ponlo en true para dibujar el circulo de color DETRAS de tu imagen.
	-- Sirve para saber si el problema es la imagen (no carga) o el cartel (no aparece):
	-- si ves el circulo pero no tu icono, el id de la imagen es el problema.
	ALWAYS_SHOW_CIRCLE = false,

	-- Texto de abajo. %d es la cantidad ganada.
	TEXT_FORMAT = "+%d",
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	TEXT_STROKE_COLOR = Color3.fromRGB(0, 0, 0),
	TEXT_STROKE_TRANSPARENCY = 0,
	FONT = Enum.Font.GothamBold,

	-- Tamano del cartel en studs
	WIDTH = 2.4,
	HEIGHT = 2.4,
	-- Que parte del alto ocupa la imagen (el resto es el texto)
	IMAGE_RATIO = 0.68,
	-- Escala fina de la imagen dentro de su hueco. 1 = a tope, 0.9 = un poquito mas pequena
	IMAGE_SCALE = 0.9,

	ALWAYS_ON_TOP = false,
	MAX_DISTANCE = 150,

	-- Posicion random alrededor del jugador
	MIN_RADIUS = 2,
	MAX_RADIUS = 5,
	MIN_HEIGHT = 0.5,
	MAX_HEIGHT = 4,

	-- Movimiento
	RISE_HEIGHT = 3, -- cuanto sube mientras se desvanece
	DURATION = 1.2, -- cuanto dura en pantalla
}

-- Si subes tu propia animacion a Roblox, pon el id aqui (ej: "rbxassetid://123456789").
-- Se reproduce ademas del movimiento del pico.
MiningConfig.ANIMATION_ID = ""

-- Sonido opcional del golpe (ej: "rbxassetid://123456789"). Vacio = sin sonido.
MiningConfig.HIT_SOUND_ID = ""

return MiningConfig
