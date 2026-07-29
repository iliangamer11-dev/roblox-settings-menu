--[[
	MiningConfig
	Configuracion compartida (cliente + servidor) del sistema de mineria.
	Aqui se ajustan las recompensas, el pico, la animacion y el popup de dinero.
]]

local MiningConfig = {}

-- true = escribe en Output el mineral y el dinero de cada picazo
MiningConfig.DEBUG = false

-- Nombre de la variable de dinero (aparece en leaderstats como "money")
MiningConfig.MONEY_NAME = "money"
MiningConfig.STARTING_MONEY = 0

-- Nombre de la herramienta
MiningConfig.TOOL_NAME = "Pickaxe"

-- Nombre del RemoteEvent que crea el servidor en ReplicatedStorage
MiningConfig.REMOTE_NAME = "PickaxeSwing"

-- Multiplicador de cada zona (nombre exacto de la Part).
-- Dinero final = dinero base del mineral * multiplicador de la zona.
MiningConfig.ZONE_MULTIPLIERS = {
	Naturaleza = 1,
	Desierto = 5,
	Mina = 10,
	Luna = 25,
	Dulces = 50,
}

-- Minerales: probabilidad en %, dinero base y color que se usa en el popup.
-- Las probabilidades suman 100, pero no hace falta que sumen exactamente eso:
-- el sorteo usa el total real, asi que puedes anadir minerales sin recalcular nada.
MiningConfig.MINERALS = {
	{ NAME = "Piedra", CHANCE = 55, MONEY = 1, COLOR = Color3.fromRGB(145, 145, 145) },
	{ NAME = "Carbon", CHANCE = 20, MONEY = 3, COLOR = Color3.fromRGB(28, 28, 30) },
	{ NAME = "Cobre", CHANCE = 10, MONEY = 8, COLOR = Color3.fromRGB(178, 102, 52) },
	{ NAME = "Hierro", CHANCE = 7, MONEY = 15, COLOR = Color3.fromRGB(214, 216, 222) },
	{ NAME = "Oro", CHANCE = 4, MONEY = 40, COLOR = Color3.fromRGB(255, 199, 44) },
	{ NAME = "Zafiro", CHANCE = 2, MONEY = 80, COLOR = Color3.fromRGB(40, 98, 255) },
	{ NAME = "Amatista", CHANCE = 1, MONEY = 150, COLOR = Color3.fromRGB(158, 60, 220) },
	{ NAME = "Diamante", CHANCE = 0.8, MONEY = 400, COLOR = Color3.fromRGB(80, 238, 255) },
	{ NAME = "Esmeralda", CHANCE = 0.15, MONEY = 1000, COLOR = Color3.fromRGB(42, 220, 92) },
	-- RAINBOW = el color va cambiando (efecto arcoiris) y suelta mas chispas
	{ NAME = "Legendario", CHANCE = 0.05, MONEY = 10000, COLOR = Color3.fromRGB(255, 255, 255), RAINBOW = true },
}

-- Color de cada zona, solo se usa para pintar las plataformas de prueba de ZonesSetup
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

	-- El agujero se pinta del color del mineral que ha salido: asi se identifica
	-- mirando el suelo. DARKEN es cuanto se oscurece ese color (0 = tal cual).
	USE_MINERAL_COLOR = true,
	DARKEN = 0.25,

	-- El mineral legendario hace que el agujero cicle colores (arcoiris)
	RAINBOW_SPEED = 1.2, -- vueltas por segundo
}

-- Cuantos picazos hacen falta para sacar un mineral.
-- Los golpes intermedios hacen chispas y agujero, pero no dan dinero.
-- Es la forma mas directa de que ganar dinero no sea tan facil: con 3, la ganancia
-- por segundo se divide entre 3 sin tocar las probabilidades ni las recompensas.
MiningConfig.HITS_PER_MINERAL = 3

-- Tiempo minimo entre picazos (segundos)
MiningConfig.SWING_COOLDOWN = 0.75

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
	-- Inclinacion en reposo, en grados.
	--   -90 = mango vertical, cabeza arriba (asi se lleva el pico en alto)
	--     0 = mango horizontal, apuntando al frente
	-- Si te queda apuntando al suelo en vez de al cielo, ponlo en 90.
	REST_ANGLE = -90,
}

--------------------------------------------------------------------------------
-- ANIMACION DEL PICAZO
--------------------------------------------------------------------------------

MiningConfig.SWING = {
	-- El pico gira sobre el punto donde lo agarra la mano, bajando hasta tocar el suelo.
	-- Los angulos son absolutos: 0 = mango horizontal, negativo = arriba, positivo = abajo.
	START_ANGLE = -105, -- amago: un poco mas atras de la vertical antes de bajar
	MAX_ANGLE = 95, -- final del golpe: pasa un poco de la vertical para clavar la punta
	-- Studs desde el punto de agarre hasta la punta del pico.
	-- Con el mango por defecto: 1.3 (agarre) + 1.5 (medio mango) = 2.8
	HEAD_REACH = 2.8,

	-- Ahora el recorrido es de casi 200 grados, asi que la bajada necesita algo mas de
	-- tiempo para que se vea el arco y no un teletransporte
	RAISE_TIME = 0.12, -- amago hacia atras
	STRIKE_TIME = 0.13, -- bajar (el picazo)
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
	-- Si lo dejas vacio se dibuja un circulo del color CIRCLE_COLOR.
	IMAGE_ID = "",
	-- Tinte de la imagen. Blanco = se ve con sus colores originales.
	IMAGE_COLOR = Color3.fromRGB(255, 255, 255),
	-- Color del circulo que se dibuja cuando no hay imagen
	CIRCLE_COLOR = Color3.fromRGB(255, 210, 60),
	IMAGE_TRANSPARENCY = 0,

	-- Ponlo en true para dibujar el circulo de color DETRAS de tu imagen.
	-- Sirve para saber si el problema es la imagen (no carga) o el cartel (no aparece):
	-- si ves el circulo pero no tu icono, el id de la imagen es el problema.
	ALWAYS_SHOW_CIRCLE = false,

	-- Texto de abajo. %s es la cantidad ya formateada (20.000 en vez de 20000).
	TEXT_FORMAT = "+%s$",
	-- true = ademas del dinero, escribe el nombre del mineral encima
	SHOW_MINERAL_NAME = false,

	-- false = el popup NO se pinta del color del mineral (ese color va en el agujero).
	-- Ponlo en true si algun dia quieres que tambien lo haga el cartel.
	USE_MINERAL_COLOR = false,
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
