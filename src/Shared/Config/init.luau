--!strict
--[[
	Config
	----------------------------------------------------------------------------
	Punto de acceso unico a toda la configuracion del juego.

		local Config = require(ReplicatedStorage.Shared.Config)
		print(Config.Game.GameName)
		print(Config.Tools.Tools.Cuchillo.Base.Power)

	Las tablas se congelan (table.freeze recursivo) para que ningun script
	pueda modificar la configuracion en tiempo de ejecucion por accidente.
--]]

local function deepFreeze(value: any, seen: { [any]: boolean }?): any
	if type(value) ~= "table" then
		return value
	end

	local visited = seen or {}
	if visited[value] then
		return value
	end
	visited[value] = true

	for _, child in pairs(value) do
		deepFreeze(child, visited)
	end

	if not table.isfrozen(value) then
		table.freeze(value)
	end

	return value
end

local Config = {
	Game = require(script.GameConfig),
	Data = require(script.DataConfig),
	Economy = require(script.EconomyConfig),
	Balloons = require(script.BalloonConfig),
	Tools = require(script.ToolConfig),
	Shops = require(script.ShopConfig),
	Levels = require(script.LevelConfig),
	Multipliers = require(script.MultiplierConfig),
	Pets = require(script.PetConfig),
	Quests = require(script.QuestConfig),
	Zones = require(script.ZoneConfig),
}

return deepFreeze(Config) :: typeof(Config)
