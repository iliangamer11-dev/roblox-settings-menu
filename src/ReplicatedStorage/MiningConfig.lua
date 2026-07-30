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
	-- Tamano en pixeles: del ajuste a cada pantalla se encarga el UIScale de UiTheme
	-- (ver UI_THEME.SCALE), asi el ancho y el alto crecen juntos y no se deforma.
	SIZE = UDim2.fromOffset(560, 74),
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

	-- Escalado automatico de TODA la interfaz segun el tamano de la pantalla.
	-- Los tamanos estan pensados para REFERENCE (un monitor normal); en pantallas mas
	-- pequenas (movil) se encoge y en 4K se agranda, siempre entre MIN y MAX.
	SCALE = {
		REFERENCE = Vector2.new(1600, 900),
		MIN = 0.55,
		MAX = 1.3,
	},
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
	SLOT = 1, -- 0 = ajustes, 1 = tienda, 2 = tags
	GAP_X = 12, -- separacion entre los botones del HUD

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
-- TAGS (etiqueta sobre el personaje)
--------------------------------------------------------------------------------

-- Cada tag tiene su degradado (TOP arriba, BOTTOM abajo) y como se desbloquea:
--   DEFAULT = true -> lo tiene todo el mundo desde el principio
--   WALL = "ParedX" -> se desbloquea al comprar esa pared
--   PASS = "VIP"    -> se desbloquea con ese gamepass
MiningConfig.TAGS = {
	{
		KEY = "NOOB",
		LABEL = "Noob",
		DEFAULT = true,
		TOP = Color3.fromRGB(190, 145, 95), -- marron claro
		BOTTOM = Color3.fromRGB(85, 55, 25), -- marron oscuro
	},
	{
		KEY = "PRINCIPIANTE",
		LABEL = "Beginner",
		WALL = "Pared2",
		TOP = Color3.fromRGB(130, 205, 255), -- azul claro
		BOTTOM = Color3.fromRGB(18, 62, 175), -- azul oscuro
	},
	{
		KEY = "PRO",
		LABEL = "Pro",
		WALL = "Pared4",
		TOP = Color3.fromRGB(255, 155, 30), -- naranja
		BOTTOM = Color3.fromRGB(190, 25, 25), -- rojo
	},
	{
		KEY = "VIP",
		LABEL = "VIP",
		PASS = "VIP",
		TOP = Color3.fromRGB(255, 140, 20), -- naranja
		BOTTOM = Color3.fromRGB(255, 240, 90), -- amarillo
	},
}

MiningConfig.TAG_REMOTE_NAME = "TagSelect"

--------------------------------------------------------------------------------
-- SKINS DEL PICO
--------------------------------------------------------------------------------

-- Cada skin cambia el color y el material del mango y de la cabeza.
-- Se desbloquean comprando paredes (WALL), igual que los tags.
MiningConfig.SKINS = {
	{
		KEY = "WOODEN",
		LABEL = "Wooden",
		DEFAULT = true,
		HANDLE_COLOR = Color3.fromRGB(110, 75, 45),
		HANDLE_MATERIAL = Enum.Material.Wood,
		HEAD_COLOR = Color3.fromRGB(160, 160, 165),
		HEAD_MATERIAL = Enum.Material.Metal,
	},
	{
		KEY = "NATURE",
		LABEL = "Nature",
		WALL = "Pared1",
		HANDLE_COLOR = Color3.fromRGB(90, 60, 35),
		HANDLE_MATERIAL = Enum.Material.Wood,
		HEAD_COLOR = Color3.fromRGB(70, 190, 90),
		HEAD_MATERIAL = Enum.Material.Grass,
	},
	{
		KEY = "GOLDEN",
		LABEL = "Golden",
		WALL = "Pared2",
		HANDLE_COLOR = Color3.fromRGB(140, 105, 60),
		HANDLE_MATERIAL = Enum.Material.Wood,
		HEAD_COLOR = Color3.fromRGB(255, 205, 60),
		HEAD_MATERIAL = Enum.Material.Foil,
	},
	{
		KEY = "DIAMOND",
		LABEL = "Diamond",
		WALL = "Pared3",
		HANDLE_COLOR = Color3.fromRGB(90, 100, 115),
		HANDLE_MATERIAL = Enum.Material.Metal,
		HEAD_COLOR = Color3.fromRGB(90, 240, 255),
		HEAD_MATERIAL = Enum.Material.Glass,
	},
	{
		KEY = "COSMIC",
		LABEL = "Cosmic",
		WALL = "Pared4",
		HANDLE_COLOR = Color3.fromRGB(45, 30, 70),
		HANDLE_MATERIAL = Enum.Material.Slate,
		HEAD_COLOR = Color3.fromRGB(180, 90, 255),
		HEAD_MATERIAL = Enum.Material.Neon,
	},
}

MiningConfig.SKIN_REMOTE_NAME = "SkinSelect"

-- Boton de skins, al lado del de tags
MiningConfig.SKIN_BUTTON = {
	ENABLED = true,
	SLOT = 3, -- 0 = ajustes, 1 = tienda, 2 = tags, 3 = skins
	ICON_ID = "", -- >>> AQUI PONES TU IMAGEN DEL BOTON DE SKINS <<<
	LABEL = "SKINS",
}

MiningConfig.SKIN_PANEL = {
	SIZE = UDim2.fromOffset(560, 460),
	TITLE = "Pickaxe Skins",
	TITLE_ICON_ID = "",

	EQUIP_TEXT = "EQUIP",
	EQUIPPED_TEXT = "EQUIPPED",
	LOCKED_TEXT = "LOCKED",
	WALL_REQUIREMENT = "Buy %s", -- %s = titulo de la pared

	-- Aviso al desbloquear una nueva. No se equipa sola.
	UNLOCK_MESSAGE = "New skin unlocked: %s",
	UNLOCK_HINT = "Open SKINS to equip it",
	UNLOCK_DURATION = 4,
	UNLOCK_POSITION = UDim2.new(0.5, 0, 0, 96),
	UNLOCK_SIZE = UDim2.fromOffset(420, 74),

	ROW_HEIGHT = 76,
	ROW_PADDING = 10,
	EXTRA_SCROLL = 40,
}

-- Boton para cambiar de tag, en la misma fila que ajustes y tienda
MiningConfig.TAG_BUTTON = {
	ENABLED = true,
	SLOT = 2, -- 0 = ajustes, 1 = tienda, 2 = tags
	ICON_ID = "", -- >>> AQUI PONES TU IMAGEN DEL BOTON DE TAGS <<<
	LABEL = "TAGS",
}

MiningConfig.TAG_PANEL = {
	SIZE = UDim2.fromOffset(560, 460),
	TITLE = "Tags",
	TITLE_ICON_ID = "",

	EQUIP_TEXT = "EQUIP",
	EQUIPPED_TEXT = "EQUIPPED",
	LOCKED_TEXT = "LOCKED",

	-- Aviso al desbloquear uno nuevo. No se equipa solo: hay que ir al menu.
	UNLOCK_MESSAGE = "New tag unlocked: %s", -- %s = nombre del tag
	UNLOCK_HINT = "Open TAGS to equip it",
	UNLOCK_DURATION = 4, -- segundos que dura el aviso
	UNLOCK_POSITION = UDim2.new(0.5, 0, 0, 96), -- debajo del boton de auto swing
	UNLOCK_SIZE = UDim2.fromOffset(420, 74),
	-- Como se lee el requisito de los que faltan
	WALL_REQUIREMENT = "Buy %s", -- %s = titulo de la pared
	PASS_REQUIREMENT = "Gamepass",

	ROW_HEIGHT = 76,
	ROW_PADDING = 10,
	EXTRA_SCROLL = 40,
}

--------------------------------------------------------------------------------
-- GAMEPASSES: IDS Y EFECTOS
--------------------------------------------------------------------------------

-- >>> AQUI ESTAN LOS IDS <<< (la tienda y los efectos leen de aqui, no hay que
-- escribirlos dos veces). ID = 0 desactiva ese pase.
MiningConfig.PASSES = {
	X2_MONEY = 1928876737,
	FAST_PICKAXE = 1932616657,
	LUCKY_ORES = 1930986994,
	AUTO_SWING = 1931716716,
	ALL_ZONES = 1932592656,
	VIP = 1927580748,
}

MiningConfig.PASS_EFFECTS = {
	-- X2 Money: multiplica el dinero de cada mineral
	MONEY_MULTIPLIER = 2,

	-- Fast Pickaxe: multiplica el cooldown (0.35 => de 0.75s a 0.26s, casi 3x mas golpes)
	COOLDOWN_MULTIPLIER = 0.35,

	-- Lucky Ores: multiplica la probabilidad de los minerales marcados como RARE.
	-- Con 5: Gold pasa de 1.4% a 6.5% y Diamond de 0.04% a 0.185% (4.6 veces mas).
	LUCK_MULTIPLIER = 5,

	-- Auto Swing: pica solo mientras estas sobre una zona
	AUTO_SWING = true,

	-- VIP: incluye estos pases, ademas de la placa VIP sobre el personaje
	VIP_INCLUDES = { "X2_MONEY", "FAST_PICKAXE" },
	-- El texto y el degradado del tag VIP estan en MiningConfig.TAGS (clave "VIP"),
	-- junto con Noob, Principiante y Pro. Como se escribe al lado del nombre se
	-- configura en NAMEPLATE.TAG_PREFIX_FORMAT.
}

--------------------------------------------------------------------------------
-- TIENDA
--------------------------------------------------------------------------------

MiningConfig.SHOP_PANEL = {
	SIZE = UDim2.fromOffset(820, 620),
	TITLE = "Shop",
	TITLE_ICON_ID = "", -- iconito de la cabecera (opcional)

	-- Cartel grande de arriba, desactivado (era el rectangulo azul).
	-- Si algun dia quieres poner una imagen promocional, ENABLED = true.
	BANNER = {
		ENABLED = false,
		TITLE = "", -- vacio = no se dibuja
		SUBTITLE = "", -- vacio = no se dibuja
		IMAGE_ID = "",
		COLOR = Color3.fromRGB(60, 150, 225),
		HEIGHT = 150,
	},

	SECTION_LABEL = "Gamepasses",
	OWNED_TEXT = "OWNED",
	LOADING_TEXT = "...",
	PRICE_FORMAT = "%s R$", -- %s = precio en robux

	-- Cuanto se puede seguir bajando el scroll despues del ultimo gamepass
	EXTRA_SCROLL = 70,

	-- >>> AQUI ESTAN TUS GAMEPASSES <<<
	-- ID    = numero del gamepass (el de la url: roblox.com/game-pass/ID/nombre)
	-- DESC  = que hace, en ingles, se lee dentro del cuadro
	-- PRICE = precio que se muestra al momento. Si Roblox devuelve otro, se corrige solo.
	-- ICON_ID = imagen del gamepass (opcional)
	GAMEPASSES = {
		{
			KEY = "X2_MONEY",
			ID = MiningConfig.PASSES.X2_MONEY,
			NAME = "X2 Money",
			DESC = "Doubles the money from every ore you mine",
			PRICE = 50,
			ICON_ID = "",
		},
		{
			KEY = "FAST_PICKAXE",
			ID = MiningConfig.PASSES.FAST_PICKAXE,
			NAME = "Fast Pickaxe",
			DESC = "Shorter cooldown, so you mine much faster",
			PRICE = 70,
			ICON_ID = "",
		},
		{
			KEY = "LUCKY_ORES",
			ID = MiningConfig.PASSES.LUCKY_ORES,
			NAME = "Lucky Ores",
			DESC = "Doubles your chance of finding rare ores",
			PRICE = 200,
			ICON_ID = "",
		},
		{
			KEY = "AUTO_SWING",
			ID = MiningConfig.PASSES.AUTO_SWING,
			NAME = "Auto Swing",
			DESC = "Mines by itself while you stand on a zone",
			PRICE = 250,
			ICON_ID = "",
		},
		{
			KEY = "ALL_ZONES",
			ID = MiningConfig.PASSES.ALL_ZONES,
			NAME = "All Zones",
			DESC = "Unlocks every zone wall instantly",
			PRICE = 199,
			ICON_ID = "",
		},
		{
			KEY = "VIP",
			ID = MiningConfig.PASSES.VIP,
			NAME = "VIP",
			DESC = "X2 Money and Fast Pickaxe plus a VIP tag",
			PRICE = 350,
			ICON_ID = "",
		},
	},

	-- Gamepasses grandes. Si no caben todos se baja con el scroll, no pasa nada.
	TILE_SIZE = UDim2.fromOffset(230, 216),
	TILE_PADDING = 14,

	-- Boton verde de comprar, dentro de cada gamepass
	BUY_COLOR = Color3.fromRGB(50, 195, 65),
	OWNED_COLOR = Color3.fromRGB(90, 90, 95),
}

--------------------------------------------------------------------------------
-- PLACA SOBRE EL PERSONAJE (nombre + nivel)
--------------------------------------------------------------------------------

MiningConfig.NAMEPLATE = {
	ENABLED = true,
	-- Quita el nombre que dibuja Roblox por defecto, para que no salga duplicado
	HIDE_DEFAULT_NAME = true,

	-- 380 de ancho para que quepa "[Principiante] Nombre" en una linea
	SIZE = UDim2.new(0, 380, 0, 76),
	OFFSET = Vector3.new(0, 1.9, 0), -- altura sobre la cabeza, en studs (mas bajo = mas cerca)
	MAX_DISTANCE = 140, -- desde cuan lejos se ve
	ALWAYS_ON_TOP = false, -- true = se ve a traves de las paredes

	FONT = Enum.Font.FredokaOne,
	NAME_HEIGHT = 0.56, -- parte del cartel que ocupa el nombre (el resto, el nivel)

	-- El nombre y el [Tag] van en la misma linea, cada uno con su ancho automatico, asi
	-- que el tamano del texto es fijo (con TextScaled no se puede medir el ancho).
	NAME_TEXT_SIZE = 28,
	TAG_PREFIX_FORMAT = "[%s]", -- como se escribe el tag al lado del nombre
	TAG_PREFIX_PADDING = 6, -- hueco entre el tag y el nombre
	-- false = el tag solo sale al lado del nombre. Ponlo en true si tambien lo quieres
	-- repetido encima, en grande.
	SHOW_TAG_ABOVE = false,

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
MiningConfig.AUTO_REMOTE_NAME = "AutoSwingToggle" -- boton de auto swing

-- Columna de la lista de jugadores donde sale el [VIP]
MiningConfig.LEADERSTATS_TAG_NAME = "Tag"

-- Boton para activar o desactivar el Auto Swing. Solo lo ve quien tiene el gamepass.
MiningConfig.AUTO_SWING_BUTTON = {
	SIZE = UDim2.fromOffset(190, 54),
	POSITION = UDim2.new(0.5, 0, 0, 18), -- arriba en el centro
	ANCHOR = Vector2.new(0.5, 0),
	ON_TEXT = "AUTO: ON",
	OFF_TEXT = "AUTO: OFF",
}

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
	-- RARE = true: son los que el gamepass Lucky Ores hace mas probables
	{ NAME = "Oro", NAME_EN = "Gold", CHANCE = 1.4, MONEY = 20, RARE = true, COLOR = Color3.fromRGB(255, 199, 44) },
	{ NAME = "Zafiro", NAME_EN = "Sapphire", CHANCE = 0.4, MONEY = 40, RARE = true, COLOR = Color3.fromRGB(40, 98, 255) },
	{
		NAME = "Amatista",
		NAME_EN = "Amethyst",
		CHANCE = 0.15,
		MONEY = 75,
		RARE = true,
		COLOR = Color3.fromRGB(158, 60, 220),
	},
	{
		NAME = "Diamante",
		NAME_EN = "Diamond",
		CHANCE = 0.04,
		MONEY = 150,
		RARE = true,
		COLOR = Color3.fromRGB(80, 238, 255),
	},
	{
		NAME = "Esmeralda",
		NAME_EN = "Emerald",
		CHANCE = 0.008,
		MONEY = 400,
		RARE = true,
		COLOR = Color3.fromRGB(42, 220, 92),
	},
	-- RAINBOW = el color va cambiando (efecto arcoiris) y suelta mas chispas
	{
		NAME = "Legendario",
		NAME_EN = "Legendary",
		CHANCE = 0.002,
		MONEY = 2500,
		RARE = true,
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
	HEAD_SIZE = Vector3.new(0.44, 0.55, 0.6), -- (grosor X, largo de cada trozo Y, grosor Z)
	HEAD_SEGMENTS = 3, -- trozos por punta: mas trozos = curva mas suave
	HEAD_TAPER = 0.86, -- cuanto se acorta cada trozo respecto al anterior
	HEAD_THICKNESS_TAPER = 0.82, -- cuanto se afina cada trozo (la punta acaba fina)

	-- Clave para que no queden huecos: cada trozo se mete este porcentaje dentro del
	-- anterior. Al girar en la union se abre un hueco de (grosor/2 * tan(angulo)) y el
	-- solape tiene que ser mayor que eso.
	HEAD_OVERLAP = 0.28,

	HEAD_START_ANGLE = 10, -- inclinacion del primer trozo
	HEAD_CURVE = 18, -- grados que se cierra hacia atras cada trozo siguiente

	-- Pieza que une las dos puntas con el mango, para que la cabeza se vea de una pieza.
	-- Tiene que ser mas gorda que el mango en X e Y para taparlo por completo.
	COLLAR_SIZE = Vector3.new(0.52, 0.58, 0.62),
	-- Cuanto sobresale el collar por delante de la punta del mango. Si es 0, las caras
	-- quedan al ras y se ve la madera asomando; con 0.16 la madera queda tapada.
	COLLAR_OVERHANG = 0.16,

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
