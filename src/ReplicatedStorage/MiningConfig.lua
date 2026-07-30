--[[
	MiningConfig
	Configuracion compartida (cliente + servidor) del sistema de mineria.
	Aqui se ajustan las recompensas, el pico, la animacion y el popup de dinero.
]]

local MiningConfig = {}

-- true = escribe en Output el mineral y el dinero de cada picazo
MiningConfig.DEBUG = false

--------------------------------------------------------------------------------
-- NIVELES
--------------------------------------------------------------------------------

MiningConfig.LEVEL = {
	ENABLED = true,

	-- true = la experiencia sale del valor BASE del mineral, sin el multiplicador de zona.
	-- Importante: con false, en Dulces (x50) se subiria de nivel 50 veces mas rapido que
	-- en Naturaleza y la barra perderia sentido.
	XP_FROM_BASE_VALUE = true,

	XP_PER_MONEY = 1, -- cuanta experiencia da cada punto de valor del mineral
	BASE_XP = 100, -- lo que cuesta pasar del nivel 1 al 2
	GROWTH = 1.15, -- cada nivel pide un 15% mas que el anterior
	MAX_LEVEL = 0, -- 0 = sin limite
}

-- Barra de nivel: verde lo conseguido, blanco lo que falta, "Level X" a la izquierda
-- y los puntos a la derecha, todo con contorno negro.
MiningConfig.LEVEL_BAR = {
	-- Ancho relativo a la pantalla (0.62 = 62%) para que sea grande en cualquier
	-- resolucion, y alto fijo en pixeles.
	SIZE = UDim2.new(0.34, 0, 0, 74),
	-- Abajo y centrada. El 1 del Y con ANCHOR 1 la pega al borde inferior,
	-- y el -28 la separa un poco.
	POSITION = UDim2.new(0.5, 0, 1, -28),
	ANCHOR = Vector2.new(0.5, 1),

	FILL_COLOR = Color3.fromRGB(60, 220, 45), -- progreso (verde)
	BACKGROUND_COLOR = Color3.fromRGB(238, 238, 238), -- lo que falta (blanco)
	OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
	OUTLINE_THICKNESS = 4, -- contorno del cuadro entero
	CORNER_RADIUS = 8,

	FONT = Enum.Font.FredokaOne,
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	TEXT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
	TEXT_OUTLINE_THICKNESS = 3, -- contorno del texto
	PADDING = 20,

	LEVEL_FORMAT = "Level %d",
	PROGRESS_FORMAT = "%s / %s", -- puntos actuales / puntos del nivel
	TWEEN_TIME = 0.35, -- lo que tarda la barra en moverse
}

--------------------------------------------------------------------------------
-- INTERFAZ: TEMA COMUN, BOTON DE AJUSTES Y PANEL
--------------------------------------------------------------------------------

-- Gris con opacidad, contorno blanco muy fino por dentro y contorno negro normal
-- por fuera, con esquinas redondeadas.
MiningConfig.UI_THEME = {
	BACKGROUND = Color3.fromRGB(70, 70, 74),
	BACKGROUND_TRANSPARENCY = 0.25,

	INNER_OUTLINE = Color3.fromRGB(255, 255, 255),
	INNER_THICKNESS = 1, -- contorno blanco muy pequeno
	OUTER_OUTLINE = Color3.fromRGB(0, 0, 0),
	OUTER_THICKNESS = 3, -- contorno negro normal
	CORNER_RADIUS = 10,

	FONT = Enum.Font.FredokaOne,
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	TEXT_OUTLINE = Color3.fromRGB(0, 0, 0),
	TEXT_OUTLINE_THICKNESS = 2,

	ON_COLOR = Color3.fromRGB(60, 200, 70), -- interruptor activado
	OFF_COLOR = Color3.fromRGB(200, 70, 70), -- interruptor desactivado
	BUTTON_COLOR = Color3.fromRGB(95, 95, 100), -- botones normales (+, -, X)
}

MiningConfig.SETTINGS_BUTTON = {
	SIZE = UDim2.fromOffset(84, 84), -- cuadrado pequeno
	-- A la izquierda y centrado en vertical. El boton de la tienda se coloca al lado y
	-- el cartel de dinero encima, los dos calculados desde esta posicion.
	POSITION = UDim2.new(0, 24, 0.5, 0),
	ANCHOR = Vector2.new(0, 0.5),

	-- >>> AQUI PONES TU IMAGEN DEL BOTON DE AJUSTES <<<
	-- Ej: ICON_ID = "rbxassetid://1234567890" (tambien vale solo el numero)
	-- Vacio = se ve el cuadro sin icono.
	ICON_ID = "",

	LABEL = "SETTINGS", -- texto, va DEBAJO del cuadro
	LABEL_HEIGHT = 26,
}

-- Boton de la tienda, al lado del de ajustes
MiningConfig.SHOP_BUTTON = {
	ENABLED = true,
	GAP_X = 12, -- separacion con el boton de ajustes

	-- >>> AQUI PONES TU IMAGEN DEL BOTON DE LA TIENDA <<<
	ICON_ID = "",

	LABEL = "SHOP", -- texto, va DEBAJO del cuadro
}

-- Cartel del dinero: ancho, justo ENCIMA del boton de ajustes.
-- Imagen a la izquierda y la cantidad a la derecha.
MiningConfig.MONEY_PANEL = {
	ENABLED = true,
	SIZE = UDim2.fromOffset(260, 68), -- ancho
	GAP = 12, -- separacion con el boton de ajustes

	-- >>> AQUI PONES TU IMAGEN DE LA MONEDA <<<
	-- Ej: ICON_ID = "rbxassetid://1234567890" (tambien vale solo el numero)
	ICON_ID = "",
	ICON_SIZE = 0.74, -- tamano del icono respecto al alto del cartel

	PREFIX = "$", -- delante de la cantidad
	PADDING = 12,
}

MiningConfig.SETTINGS_PANEL = {
	SIZE = UDim2.fromOffset(420, 400),
	TITLE = "Settings",

	MUSIC_ID = "rbxassetid://1848354536",
	VOLUME_STEP = 0.1, -- cuanto sube o baja cada clic

	-- Textos de las opciones, en ingles
	MUSIC_LABEL = "Music",
	MUTE_LABEL = "Mute",
	UNMUTE_LABEL = "Unmute",
	ROWS = {
		{ KEY = "showLevelBar", LABEL = "Level bar" },
		{ KEY = "showMoneyPopups", LABEL = "Money popups" },
		{ KEY = "showHoles", LABEL = "Mining holes" },
		{ KEY = "showNameplates", LABEL = "Player nameplates" },
	},
	ON_TEXT = "ON",
	OFF_TEXT = "OFF",
}

--------------------------------------------------------------------------------
-- TIENDA
--------------------------------------------------------------------------------

MiningConfig.SHOP_PANEL = {
	-- 520 de alto para que se vean dos filas de gamepasses sin tener que hacer scroll
	SIZE = UDim2.fromOffset(600, 520),
	TITLE = "Exclusive Shop",
	TITLE_ICON_ID = "", -- iconito de la cabecera (opcional)

	-- Cartel grande de arriba
	BANNER = {
		TITLE = "Best value!",
		SUBTITLE = "Get more money per swing",
		IMAGE_ID = "", -- imagen de fondo del cartel (opcional)
		COLOR = Color3.fromRGB(60, 150, 225),
		HEIGHT = 118,
	},

	SECTION_LABEL = "Gamepasses",
	OWNED_TEXT = "OWNED",
	LOADING_TEXT = "...",
	ROBUX_FORMAT = "%s R$", -- %s = precio

	-- >>> AQUI PONES TUS GAMEPASSES <<<
	-- ID = el numero del gamepass (el de la url del gamepass en la web de Roblox).
	-- Con ID = 0 el boton sale desactivado, para que puedas ver el diseno sin tener
	-- todavia los gamepasses creados.
	GAMEPASSES = {
		{ ID = 0, NAME = "2x Money", ICON_ID = "" },
		{ ID = 0, NAME = "Auto Swing", ICON_ID = "" },
		{ ID = 0, NAME = "Lucky Ores", ICON_ID = "" },
		{ ID = 0, NAME = "VIP", ICON_ID = "" },
		{ ID = 0, NAME = "Fast Pickaxe", ICON_ID = "" },
		{ ID = 0, NAME = "All Zones", ICON_ID = "" },
	},

	TILE_SIZE = UDim2.fromOffset(160, 120),
	TILE_PADDING = 12,
}

--------------------------------------------------------------------------------
-- PLACA SOBRE EL PERSONAJE (nombre + nivel)
--------------------------------------------------------------------------------

MiningConfig.NAMEPLATE = {
	ENABLED = true,
	-- Quita el nombre que dibuja Roblox por defecto, para que no salga duplicado
	HIDE_DEFAULT_NAME = true,

	SIZE = UDim2.new(0, 260, 0, 76), -- tamano del cartel
	OFFSET = Vector3.new(0, 1.9, 0), -- altura sobre la cabeza, en studs (mas bajo = mas cerca)
	MAX_DISTANCE = 140, -- desde cuan lejos se ve
	ALWAYS_ON_TOP = false, -- true = se ve a traves de las paredes

	FONT = Enum.Font.FredokaOne,
	NAME_HEIGHT = 0.56, -- parte del cartel que ocupa el nombre (el resto, el nivel)

	-- Nombre: blanco con contorno negro
	NAME_COLOR = Color3.fromRGB(255, 255, 255),
	USE_DISPLAY_NAME = true, -- true = DisplayName, false = nombre de usuario

	-- Nivel: degradado de azul claro (arriba) a azul oscuro (abajo), contorno negro
	LEVEL_FORMAT = "Level %d",
	LEVEL_GRADIENT_TOP = Color3.fromRGB(130, 205, 255),
	LEVEL_GRADIENT_BOTTOM = Color3.fromRGB(18, 62, 175),

	OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
	OUTLINE_THICKNESS = 2.5,
}

-- Aviso de subida de nivel: texto en ingles encima de la barra + sonido
MiningConfig.LEVEL_UP = {
	ENABLED = true,

	-- Si pones un %d dentro del texto, se sustituye por el nivel nuevo.
	-- Ej: "LEVEL UP!  Level %d"
	TEXT_FORMAT = "LEVEL UP!",
	TEXT_COLOR = Color3.fromRGB(255, 232, 120),
	TEXT_SIZE = 64, -- alto del texto en pixeles
	OFFSET = 22, -- separacion sobre la barra

	SOUND_ID = "rbxassetid://112485797063762",
	SOUND_VOLUME = 0.7,

	RISE = 45, -- pixeles que sube el texto mientras se desvanece
	DURATION = 1.5, -- cuanto dura el aviso
}

-- Nombre de la variable de dinero (aparece en leaderstats como "money")
MiningConfig.MONEY_NAME = "money"
MiningConfig.STARTING_MONEY = 0

-- Nombre de la herramienta
MiningConfig.TOOL_NAME = "Pickaxe"

-- El pico va siempre en la mano: se equipa al aparecer y si el jugador lo desequipa
-- (tecla, backspace, otro script...) se le vuelve a poner al instante.
MiningConfig.ALWAYS_EQUIPPED = true

-- Oculta la mochila/hotbar de Roblox, ya que el pico esta siempre equipado
MiningConfig.HIDE_BACKPACK_GUI = true

-- Nombres de los RemoteEvent que crea el servidor en ReplicatedStorage
MiningConfig.REMOTE_NAME = "PickaxeSwing" -- click del pico
MiningConfig.HOLE_REMOTE_NAME = "PickaxeHole" -- avisa al jugador para que dibuje su agujero
MiningConfig.WALL_REMOTE_NAME = "WallPurchase" -- compra de paredes

--------------------------------------------------------------------------------
-- PAREDES QUE SE COMPRAN (una por zona)
--------------------------------------------------------------------------------

-- Cada pared se quita SOLO para el jugador que la compra.
-- TITLE es lo que se lee en el boton, en ingles.
MiningConfig.WALLS = {
	{ NAME = "Pared1", PRICE = 100, TITLE = "Desert Zone" },
	{ NAME = "Pared2", PRICE = 1000, TITLE = "Mine Zone" },
	{ NAME = "Pared3", PRICE = 5000, TITLE = "Moon Zone" },
	{ NAME = "Pared4", PRICE = 10000, TITLE = "Candy Zone" },
}

-- Textos y comportamiento del boton que sale al acercarse (ProximityPrompt).
-- Todo en ingles, como pediste.
MiningConfig.WALL_PROMPT = {
	KEY = Enum.KeyCode.E,
	HOLD_DURATION = 0.4, -- segundos que hay que mantener la tecla
	MAX_DISTANCE = 14, -- a cuantos studs aparece el boton
	REQUIRES_LINE_OF_SIGHT = false,

	ACTION_TEXT = "Buy for $%s", -- %s = precio
	OBJECT_TEXT = "%s", -- %s = TITLE de la pared
	FAILED_TEXT = "Need $%s more", -- %s = lo que falta
	FEEDBACK_TIME = 1.5, -- cuanto se queda el aviso antes de volver al texto normal
}

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
-- NAME = nombre interno (logs), NAME_EN = el que se muestra en el cartel
MiningConfig.MINERALS = {
	{ NAME = "Piedra", NAME_EN = "Stone", CHANCE = 70, MONEY = 1, COLOR = Color3.fromRGB(145, 145, 145) },
	{ NAME = "Carbon", NAME_EN = "Coal", CHANCE = 18, MONEY = 2, COLOR = Color3.fromRGB(28, 28, 30) },
	{ NAME = "Cobre", NAME_EN = "Copper", CHANCE = 7, MONEY = 4, COLOR = Color3.fromRGB(178, 102, 52) },
	{ NAME = "Hierro", NAME_EN = "Iron", CHANCE = 3, MONEY = 8, COLOR = Color3.fromRGB(214, 216, 222) },
	{ NAME = "Oro", NAME_EN = "Gold", CHANCE = 1.4, MONEY = 20, COLOR = Color3.fromRGB(255, 199, 44) },
	{ NAME = "Zafiro", NAME_EN = "Sapphire", CHANCE = 0.4, MONEY = 40, COLOR = Color3.fromRGB(40, 98, 255) },
	{ NAME = "Amatista", NAME_EN = "Amethyst", CHANCE = 0.15, MONEY = 75, COLOR = Color3.fromRGB(158, 60, 220) },
	{ NAME = "Diamante", NAME_EN = "Diamond", CHANCE = 0.04, MONEY = 150, COLOR = Color3.fromRGB(80, 238, 255) },
	{ NAME = "Esmeralda", NAME_EN = "Emerald", CHANCE = 0.008, MONEY = 400, COLOR = Color3.fromRGB(42, 220, 92) },
	-- RAINBOW = el color va cambiando (efecto arcoiris) y suelta mas chispas
	{
		NAME = "Legendario",
		NAME_EN = "Legendary",
		CHANCE = 0.002,
		MONEY = 2500,
		COLOR = Color3.fromRGB(255, 255, 255),
		RAINBOW = true,
	},
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
	LIFETIME = 3, -- segundos que dura el agujero
	-- Segundos que tarda en desvanecerse. Si es igual a LIFETIME se va apagando poco a
	-- poco desde el principio; si es menor, se queda opaco un rato y luego se desvanece.
	FADE_TIME = 3,

	-- El agujero se pinta del color del mineral que ha salido: asi se identifica
	-- mirando el suelo. DARKEN es cuanto se oscurece ese color (0 = tal cual).
	USE_MINERAL_COLOR = true,
	DARKEN = 0.25,

	-- El mineral legendario hace que el agujero cicle colores (arcoiris)
	RAINBOW_SPEED = 1.2, -- vueltas por segundo
}

-- Cuantos picazos hacen falta para sacar un mineral.
-- 1 = cada golpe da mineral y sale el cartel siempre (lo normal).
-- Si algun dia quieres que ganar dinero cueste mas, sube este numero: con 3 la ganancia
-- se divide entre 3, pero ojo, los golpes intermedios no muestran cartel.
MiningConfig.HITS_PER_MINERAL = 1

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

	-- La cabeza son dos puntas (arriba y abajo) hechas de varios trozos encadenados:
	-- cada trozo se gira un poco mas y es mas pequeno que el anterior, asi la punta
	-- queda curvada y afilada como un pico de verdad (y no recta como un martillo).
	HEAD_COLOR = Color3.fromRGB(160, 160, 165),
	HEAD_SIZE = Vector3.new(0.42, 0.5, 0.55), -- (grosor X, largo de cada trozo Y, grosor Z)
	HEAD_SEGMENTS = 3, -- trozos por punta: mas trozos = curva mas suave
	HEAD_TAPER = 0.72, -- cuanto se encoge cada trozo respecto al anterior (afila la punta)
	HEAD_START_ANGLE = 12, -- inclinacion del primer trozo
	HEAD_CURVE = 20, -- grados que se cierra hacia atras cada trozo siguiente

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
	-- Nombre del mineral (en ingles) debajo del dinero, con el color del mineral
	SHOW_MINERAL_NAME = true,
	-- Que parte del hueco de texto se lleva el nombre (el resto es el dinero)
	NAME_RATIO = 0.42,

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
