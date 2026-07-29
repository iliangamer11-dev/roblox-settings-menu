--!strict
--[[
	GameConfig
	Ajustes globales del juego. Valores generales que no pertenecen a un
	sistema concreto.
--]]

return {
	GameName = "Balloon Popping Simulator",
	GameVersion = "0.1.0",

	-- Poner en false antes de publicar a produccion
	Debug = true,
	VerboseLogs = true,

	-- Moneda por defecto mostrada en la interfaz
	PrimaryCurrency = "Coins",

	-- Limites de seguridad usados por los servicios (anti-exploit)
	Limits = {
		MaxRemoteCallsPerSecond = 20,
		MaxEquippedPets = 3,
		MaxOwnedPets = 100,
	},

	-- Nombres de contenedores en el arbol de Roblox
	Containers = {
		World = "World",
		Balloons = "Balloons",
		Zones = "Zones",
		Spawners = "Spawners",
		Effects = "Effects",
	},
}
