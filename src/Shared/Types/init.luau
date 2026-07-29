--!strict
--[[
	Types
	----------------------------------------------------------------------------
	Fuente unica de verdad para los tipos compartidos entre cliente y servidor.
	Al anadir una nueva feature (mascotas, misiones, zonas...) se amplia el tipo
	correspondiente aqui y todo el proyecto queda tipado de forma coherente.
--]]

local Types = {}

--------------------------------------------------------------------------------
-- Identificadores
--------------------------------------------------------------------------------

export type ToolId = string
export type BalloonId = string
export type ShopId = string
export type PetId = string
export type QuestId = string
export type ZoneId = string
export type UpgradeId = string
export type CurrencyId = string

--------------------------------------------------------------------------------
-- Monedas
--------------------------------------------------------------------------------

export type CurrencyWallet = {
	Coins: number,
	Gems: number,
}

--------------------------------------------------------------------------------
-- Estadisticas del jugador
--------------------------------------------------------------------------------

export type PlayerStats = {
	BalloonsPopped: number,
	CoinsEarned: number,
	GemsEarned: number,
	CoinsSpent: number,
	PlayTime: number, -- segundos acumulados
	Rebirths: number,
	HighestCombo: number,
	QuestsCompleted: number,
	ZonesUnlocked: number,
}

--------------------------------------------------------------------------------
-- Progresion
--------------------------------------------------------------------------------

export type PlayerLevel = {
	Level: number,
	Experience: number,
}

--------------------------------------------------------------------------------
-- Herramientas mejorables
--------------------------------------------------------------------------------

--[[
	Estado guardado de una herramienta que posee el jugador.
	`Upgrades` es un mapa UpgradeId -> nivel adquirido, de modo que se pueden
	anadir nuevas lineas de mejora sin migrar datos existentes.
--]]
export type OwnedTool = {
	Id: ToolId,
	Upgrades: { [UpgradeId]: number },
	AcquiredAt: number,
}

export type ToolInventory = {
	Equipped: ToolId?,
	Owned: { [ToolId]: OwnedTool },
}

--------------------------------------------------------------------------------
-- Multiplicadores activos (gamepass, mascota, pocion, evento...)
--------------------------------------------------------------------------------

export type MultiplierSource = {
	Id: string,
	Kind: string, -- "Coins" | "Experience" | "PopPower" ...
	Value: number,
	ExpiresAt: number?, -- os.time() de expiracion, nil = permanente
}

--------------------------------------------------------------------------------
-- Mascotas
--------------------------------------------------------------------------------

export type OwnedPet = {
	Uid: string,
	Id: PetId,
	Level: number,
	Equipped: boolean,
}

--------------------------------------------------------------------------------
-- Misiones
--------------------------------------------------------------------------------

export type QuestProgress = {
	Id: QuestId,
	Progress: number,
	Completed: boolean,
	ClaimedAt: number?,
}

--------------------------------------------------------------------------------
-- Ajustes del jugador (cliente)
--------------------------------------------------------------------------------

export type PlayerSettings = {
	Music: boolean,
	SoundEffects: boolean,
	ScreenShake: boolean,
	DamageNumbers: boolean,
}

--------------------------------------------------------------------------------
-- Perfil completo persistido en DataStore
--------------------------------------------------------------------------------

export type PlayerProfile = {
	SchemaVersion: number,
	Currencies: CurrencyWallet,
	Stats: PlayerStats,
	Progression: PlayerLevel,
	Tools: ToolInventory,
	Pets: { [string]: OwnedPet },
	Quests: { [QuestId]: QuestProgress },
	Multipliers: { [string]: MultiplierSource },
	UnlockedZones: { [ZoneId]: boolean },
	Settings: PlayerSettings,
	Meta: {
		FirstJoin: number,
		LastJoin: number,
		SessionCount: number,
	},
}

--------------------------------------------------------------------------------
-- Framework: contrato de Servicios (servidor) y Controladores (cliente)
--------------------------------------------------------------------------------

export type LifecycleModule = {
	Name: string?,
	Priority: number?,
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
	[any]: any,
}

--------------------------------------------------------------------------------
-- Red
--------------------------------------------------------------------------------

export type RemoteKind = "RemoteEvent" | "RemoteFunction"
export type RemoteDirection = "ServerToClient" | "ClientToServer" | "Bidirectional"

export type RemoteDefinition = {
	Name: string,
	Kind: RemoteKind,
	Direction: RemoteDirection,
	Description: string,
}

return Types
