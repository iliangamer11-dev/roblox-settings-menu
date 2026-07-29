--!strict
--[[
	BalloonConfig
	----------------------------------------------------------------------------
	Catalogo de globos y reglas de aparicion.

	Anadir un tipo de globo nuevo es SOLO anadir una entrada en `Balloons`.
	Ningun script necesita cambios: el manager lee el catalogo, reparte por
	peso de rareza y escribe los atributos en la instancia.

	Si `Model` apunta a un modelo existente en ServerStorage.Assets.Balloons se
	clona ese modelo. Si no existe, el globo se construye por codigo (una Part
	esferica del color y tamano indicados), asi que el sistema funciona en un
	mapa vacio sin necesidad de assets.
--]]

--------------------------------------------------------------------------------
-- Tipos
--------------------------------------------------------------------------------

export type BalloonReward = {
	Coins: number,
	Experience: number,
}

export type BalloonDefinition = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	-- Peso relativo de aparicion dentro de su zona. Mayor = mas frecuente.
	Weight: number,
	-- Golpes de dano necesarios para reventarlo
	Health: number,
	Reward: BalloonReward,
	Color: Color3,
	-- Diametro en studs
	Size: number,
	-- Nombre del modelo en ServerStorage.Assets.Balloons (opcional)
	Model: string?,
	-- Segundos de vida antes de desaparecer solo. 0 = permanece hasta que lo pinchen
	Lifetime: number,
}

export type RarityDefinition = {
	Id: string,
	DisplayName: string,
	Color: Color3,
	-- Orden para la interfaz (1 = mas comun)
	Order: number,
}

--------------------------------------------------------------------------------
-- Rarezas
--------------------------------------------------------------------------------

local Rarities: { [string]: RarityDefinition } = {
	Common = {
		Id = "Common",
		DisplayName = "Comun",
		Color = Color3.fromRGB(200, 200, 200),
		Order = 1,
	},
	Uncommon = {
		Id = "Uncommon",
		DisplayName = "Poco comun",
		Color = Color3.fromRGB(85, 255, 127),
		Order = 2,
	},
	Rare = {
		Id = "Rare",
		DisplayName = "Raro",
		Color = Color3.fromRGB(85, 170, 255),
		Order = 3,
	},
	Epic = {
		Id = "Epic",
		DisplayName = "Epico",
		Color = Color3.fromRGB(170, 85, 255),
		Order = 4,
	},
	Legendary = {
		Id = "Legendary",
		DisplayName = "Legendario",
		Color = Color3.fromRGB(255, 200, 60),
		Order = 5,
	},
}

--------------------------------------------------------------------------------
-- Catalogo de globos
--------------------------------------------------------------------------------

local Balloons: { [string]: BalloonDefinition } = {
	Red = {
		Id = "Red",
		DisplayName = "Globo Rojo",
		Rarity = "Common",
		Weight = 100,
		Health = 1,
		Reward = { Coins = 1, Experience = 1 },
		Color = Color3.fromRGB(196, 40, 28),
		Size = 3,
		Lifetime = 0,
	},
	Blue = {
		Id = "Blue",
		DisplayName = "Globo Azul",
		Rarity = "Common",
		Weight = 80,
		Health = 2,
		Reward = { Coins = 3, Experience = 2 },
		Color = Color3.fromRGB(13, 105, 172),
		Size = 3.2,
		Lifetime = 0,
	},
	Green = {
		Id = "Green",
		DisplayName = "Globo Verde",
		Rarity = "Uncommon",
		Weight = 40,
		Health = 4,
		Reward = { Coins = 8, Experience = 5 },
		Color = Color3.fromRGB(75, 151, 75),
		Size = 3.5,
		Lifetime = 0,
	},
	Purple = {
		Id = "Purple",
		DisplayName = "Globo Morado",
		Rarity = "Rare",
		Weight = 15,
		Health = 8,
		Reward = { Coins = 25, Experience = 12 },
		Color = Color3.fromRGB(107, 50, 124),
		Size = 4,
		Lifetime = 0,
	},
	Golden = {
		Id = "Golden",
		DisplayName = "Globo Dorado",
		Rarity = "Legendary",
		Weight = 2,
		Health = 20,
		Reward = { Coins = 250, Experience = 60 },
		Color = Color3.fromRGB(245, 205, 48),
		Size = 4.5,
		-- Los legendarios se marchan si nadie los pincha
		Lifetime = 90,
	},
}

--------------------------------------------------------------------------------
-- Aparicion
--------------------------------------------------------------------------------

local Spawning = {
	Enabled = true,

	-- Nombre de la Part que hace de area de aparicion. Cualquier BasePart del
	-- Workspace con este nombre se convierte en punto de aparicion, este donde
	-- este en el arbol. Es la forma mas simple: colocas una Part, la llamas
	-- asi, y ya salen globos encima.
	SpawnPartName = "BalloonSpawn",
	-- Detectar Parts anadidas o borradas durante la partida. El coste es una
	-- comparacion de nombre por instancia que entra en Workspace.
	WatchWorkspace = true,

	-- Tope global de globos vivos en el servidor. Es el limite que protege el
	-- rendimiento: no crece con el numero de jugadores.
	MaxActive = 150,
	-- Tope por zona, para que una zona no se coma el presupuesto global
	MaxActivePerZone = 40,
	-- Tope MINIMO por punto de aparicion. Si el area de la Part da para mas
	-- globos respetando MinSeparation, el tope real se calcula a partir de su
	-- superficie. Asi una Part pequena no se apelmaza y una grande se
	-- aprovecha, sin tener que configurar nada.
	MaxActivePerSpawnPoint = 6,

	-- Segundos entre ciclos del planificador (un solo hilo para todo)
	Interval = 0.4,
	-- Maximo de globos creados en un mismo ciclo, para repartir el coste
	SpawnsPerTick = 4,

	-- Al arrancar, llenar el mapa de golpe en lugar de esperar al goteo
	InitialBurst = true,
	-- Globos creados por ciclo durante el llenado inicial
	BurstPerTick = 12,

	-- Altura a la que flota el globo sobre el punto de aparicion
	FloatHeightMin = 4,
	FloatHeightMax = 9,
	-- Distancia minima entre globos del mismo punto de aparicion
	MinSeparation = 4,
	-- Intentos de buscar hueco antes de rendirse en este ciclo
	PlacementAttempts = 6,

	-- Reserva de instancias creadas al arrancar para evitar picos de
	-- Instance.new durante la partida (0 = desactivado)
	PrewarmPerType = 10,
}

--------------------------------------------------------------------------------
-- Nombres de los atributos escritos en cada globo
--------------------------------------------------------------------------------

--[[
	Los datos viajan al cliente como atributos de la instancia, no como
	ValueObjects hijos: menos instancias que replicar y se leen con
	instance:GetAttribute(). Centralizarlos aqui permite renombrarlos sin
	buscar strings por todo el proyecto.
--]]
local Attributes = {
	Id = "BalloonId", -- identificador unico de esta instancia
	Type = "BalloonType", -- id de la definicion (Red, Golden...)
	Name = "DisplayName", -- nombre visible
	Rarity = "Rarity",
	Reward = "Reward", -- monedas
	Experience = "RewardExperience",
	Health = "Health",
	MaxHealth = "MaxHealth",
	Zone = "ZoneId",
}

--------------------------------------------------------------------------------
-- Presentacion en el cliente
--------------------------------------------------------------------------------

local Visuals = {
	-- Balanceo vertical calculado en el cliente: cuesta 0 al servidor y no
	-- genera trafico de replicacion.
	BobEnabled = true,
	BobAmplitude = 0.6, -- studs
	BobSpeed = 1.2,
	-- Solo se animan los globos a esta distancia de la camara
	BobRenderDistance = 120,
	-- Cada cuanto se recalcula que globos estan cerca
	CullRefreshInterval = 0.5,
	-- Tope de globos animados por frame
	MaxAnimatedPerFrame = 60,
}

--------------------------------------------------------------------------------

return {
	Rarities = Rarities,
	Balloons = Balloons,
	Spawning = Spawning,
	Attributes = Attributes,
	Visuals = Visuals,

	-- Reglas de pinchado. TODO: las consumira el sistema de pinchado.
	Popping = {
		MaxHitDistance = 18, -- validacion de distancia en el servidor
		DefaultCooldown = 0.2,
	},
}
