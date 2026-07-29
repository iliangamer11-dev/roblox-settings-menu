--!strict
--[[
	ZoneConfig
	Definicion de zonas del mapa y sus requisitos de desbloqueo.

	PREPARADO PARA: nuevas zonas.
--]]

export type ZoneDefinition = {
	Id: string,
	DisplayName: string,
	Order: number,
	-- Nombre del modelo dentro de Workspace.World.Zones
	Model: string,
	UnlockPrice: number,
	UnlockCurrency: string,
	RequiredLevel: number,
	Unlocked: boolean, -- true = disponible desde el inicio
	-- Ids de globo que aparecen en esta zona (pesos en BalloonConfig)
	BalloonIds: { string },
	CoinMultiplier: number,
}

local Zones: { [string]: ZoneDefinition } = {
	Spawn = {
		Id = "Spawn",
		DisplayName = "Zona Inicial",
		Order = 1,
		Model = "Spawn",
		UnlockPrice = 0,
		UnlockCurrency = "Coins",
		RequiredLevel = 1,
		Unlocked = true,
		BalloonIds = {},
		CoinMultiplier = 1,
	},
	-- TODO: anadir mas zonas
}

return {
	Zones = Zones,
	DefaultZoneId = "Spawn",
}
