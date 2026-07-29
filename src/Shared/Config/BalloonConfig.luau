--!strict
--[[
	BalloonConfig
	Definicion de tipos de globo y reglas de aparicion.

	PREPARADO PARA: aparicion de globos y sistema de pinchado.
	Por ahora solo son datos: ningun sistema los consume todavia.
--]]

export type BalloonDefinition = {
	Id: string,
	DisplayName: string,
	Health: number, -- golpes/dano necesario para reventarlo
	Reward: { Coins: number, Experience: number },
	Rarity: number, -- peso relativo de aparicion
	Color: Color3,
	Size: number,
	Model: string?, -- nombre del modelo en ServerStorage.Assets.Balloons
}

local Balloons: { [string]: BalloonDefinition } = {
	-- TODO: definir el catalogo real de globos
}

return {
	Balloons = Balloons,

	Spawning = {
		Enabled = false, -- se activara al implementar la aparicion
		MaxActivePerZone = 40,
		SpawnInterval = 1.5,
		RespawnDelay = 3,
		FloatHeight = 6,
	},

	Popping = {
		DefaultCooldown = 0.2,
		MaxHitDistance = 18, -- validacion servidor
	},
}
