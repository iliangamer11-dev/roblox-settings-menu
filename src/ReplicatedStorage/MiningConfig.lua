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

-- Tiempo minimo entre picazos (segundos)
MiningConfig.SWING_COOLDOWN = 0.55

-- Distancia maxima a la que se puede picar una zona (studs)
MiningConfig.MAX_REACH = 18

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
	-- o sea en el mismo plano en el que baja el picazo. Asi se ve como un pico de verdad
	-- y la punta de abajo es la que golpea el suelo.
	HEAD_SIZE = Vector3.new(0.4, 1.15, 0.5), -- (grosor X, largo de la punta Y, grosor Z)
	HEAD_COLOR = Color3.fromRGB(160, 160, 165),
	HEAD_ANGLE = 24, -- grados: cuanto se echan las puntas hacia atras (curva del pico)

	-- Donde agarra la mano el mango (offset dentro del propio mango, en studs).
	-- Z positivo = mas atras en el mango.
	GRIP_OFFSET = Vector3.new(0, 0, 1.3),
	-- Rotacion del agarre en grados (X, Y, Z). Cambialo si te queda raro en la mano.
	GRIP_ROTATION = Vector3.new(0, 0, 0),
	-- Inclinacion en reposo: negativo = la punta queda levantada, listo para picar
	REST_ANGLE = -20,
}

--------------------------------------------------------------------------------
-- ANIMACION DEL PICAZO
--------------------------------------------------------------------------------

MiningConfig.SWING = {
	-- El pico gira sobre el punto donde lo agarra la mano, bajando hasta tocar el suelo.
	START_ANGLE = -50, -- grados: cuanto se levanta el pico antes del golpe
	MAX_ANGLE = 88, -- limite hacia abajo, para que no atraviese el piso
	-- Studs desde el punto de agarre hasta la punta del pico.
	-- Con el mango por defecto: 1.3 (agarre) + 1.5 (medio mango) + la punta = ~3.2
	HEAD_REACH = 3.2,

	RAISE_TIME = 0.14, -- levantar
	STRIKE_TIME = 0.08, -- bajar (el picazo)
	HOLD_TIME = 0.06, -- quedarse clavado un instante
	RETURN_TIME = 0.18, -- volver a la posicion normal

	-- Si el pico gira al lado contrario en tu avatar, pon -1
	AXIS_SIGN = 1,
}

--------------------------------------------------------------------------------
-- POPUP DE DINERO (ImageLabel + TextLabel)
--------------------------------------------------------------------------------

MiningConfig.POPUP = {
	ENABLED = true,

	-- Tu icono. Ej: "rbxassetid://1234567890"
	-- Si lo dejas vacio se dibuja un circulo del color de abajo.
	IMAGE_ID = "",
	IMAGE_COLOR = Color3.fromRGB(255, 210, 60),
	IMAGE_TRANSPARENCY = 0,

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
