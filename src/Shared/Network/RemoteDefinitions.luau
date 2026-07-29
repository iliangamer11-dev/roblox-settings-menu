--!strict
--[[
	RemoteDefinitions
	----------------------------------------------------------------------------
	Fuente unica de verdad de TODOS los RemoteEvents y RemoteFunctions.

	El servidor los crea al arrancar (Server/Network/RemoteBuilder) dentro de
	ReplicatedStorage.Remotes, y ambos lados los consumen a traves de
	Shared/Network/Net, que valida que el nombre exista. Asi es imposible
	tener remotes "fantasma" por un typo.

	Para anadir un remote nuevo: anadir una entrada aqui y nada mas.
--]]

export type RemoteKind = "RemoteEvent" | "RemoteFunction"
export type RemoteDirection = "ServerToClient" | "ClientToServer" | "Bidirectional"

export type Definition = {
	Kind: RemoteKind,
	Direction: RemoteDirection,
	Description: string,
	-- Llamadas maximas por segundo aceptadas del cliente (solo entrantes)
	RateLimit: number?,
}

local Definitions: { [string]: Definition } = {
	--------------------------------------------------------------------------
	-- Datos del jugador / estadisticas
	--------------------------------------------------------------------------
	ProfileLoaded = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "Envia el perfil completo al cliente cuando termina de cargar.",
	},
	ProfileUpdated = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "Envia cambios parciales del perfil (monedas, stats, nivel...).",
	},
	GetProfile = {
		Kind = "RemoteFunction",
		Direction = "ClientToServer",
		Description = "El cliente solicita su perfil (fallback si perdio ProfileLoaded).",
		RateLimit = 2,
	},

	--------------------------------------------------------------------------
	-- Globos (aparicion y pinchado)
	--------------------------------------------------------------------------
	BalloonSpawned = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "Notifica la aparicion de un globo.",
	},
	BalloonPopped = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "Notifica que un globo ha sido reventado (efectos, sonido, recompensa).",
	},
	RequestPopBalloon = {
		Kind = "RemoteEvent",
		Direction = "ClientToServer",
		Description = "El cliente pide pinchar un globo; el servidor valida y aplica.",
		RateLimit = 20,
	},

	--------------------------------------------------------------------------
	-- Herramientas y mejoras
	--------------------------------------------------------------------------
	RequestEquipTool = {
		Kind = "RemoteFunction",
		Direction = "ClientToServer",
		Description = "Equipar una herramienta que el jugador posee.",
		RateLimit = 5,
	},
	RequestUpgradeTool = {
		Kind = "RemoteFunction",
		Direction = "ClientToServer",
		Description = "Comprar un nivel de mejora para la herramienta indicada.",
		RateLimit = 5,
	},
	ToolUpdated = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "El estado o las mejoras de una herramienta han cambiado.",
	},

	--------------------------------------------------------------------------
	-- Tiendas
	--------------------------------------------------------------------------
	RequestPurchase = {
		Kind = "RemoteFunction",
		Direction = "ClientToServer",
		Description = "Comprar un articulo de una tienda.",
		RateLimit = 5,
	},
	PurchaseResult = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "Resultado de una compra para mostrar feedback en la interfaz.",
	},

	--------------------------------------------------------------------------
	-- Niveles y multiplicadores
	--------------------------------------------------------------------------
	LevelChanged = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "El jugador ha subido de nivel.",
	},
	MultipliersChanged = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "Los multiplicadores activos del jugador han cambiado.",
	},

	--------------------------------------------------------------------------
	-- Mascotas
	--------------------------------------------------------------------------
	RequestTogglePet = {
		Kind = "RemoteFunction",
		Direction = "ClientToServer",
		Description = "Equipar o desequipar una mascota.",
		RateLimit = 10,
	},
	PetsUpdated = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "El inventario de mascotas del jugador ha cambiado.",
	},

	--------------------------------------------------------------------------
	-- Misiones
	--------------------------------------------------------------------------
	RequestClaimQuest = {
		Kind = "RemoteFunction",
		Direction = "ClientToServer",
		Description = "Reclamar la recompensa de una mision completada.",
		RateLimit = 5,
	},
	QuestsUpdated = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "Progreso o estado de las misiones del jugador.",
	},

	--------------------------------------------------------------------------
	-- Zonas
	--------------------------------------------------------------------------
	RequestUnlockZone = {
		Kind = "RemoteFunction",
		Direction = "ClientToServer",
		Description = "Desbloquear una zona pagando su precio.",
		RateLimit = 5,
	},
	ZoneChanged = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "El jugador ha entrado en otra zona o ha desbloqueado una nueva.",
	},

	--------------------------------------------------------------------------
	-- Interfaz / utilidades
	--------------------------------------------------------------------------
	Notify = {
		Kind = "RemoteEvent",
		Direction = "ServerToClient",
		Description = "Mensaje generico para mostrar un aviso en pantalla.",
	},
	UpdateSetting = {
		Kind = "RemoteEvent",
		Direction = "ClientToServer",
		Description = "El cliente guarda un ajuste (musica, efectos...).",
		RateLimit = 5,
	},
}

return {
	-- Nombre de las carpetas creadas en ReplicatedStorage
	FolderName = "Remotes",
	EventsFolderName = "Events",
	FunctionsFolderName = "Functions",

	Definitions = Definitions,
}
