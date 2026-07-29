--!strict
--[[
	LevelConfig
	Curva de experiencia y recompensas por nivel.

	PREPARADO PARA: niveles.
--]]

local MAX_LEVEL = 100

--[[
	Experiencia necesaria para pasar del nivel `level` al siguiente.
--]]
local function experienceForLevel(level: number): number
	return math.floor(100 * (level ^ 1.35))
end

return {
	MaxLevel = MAX_LEVEL,
	StartingLevel = 1,
	ExperienceForLevel = experienceForLevel,

	-- Recompensas otorgadas al alcanzar niveles concretos
	-- TODO: rellenar cuando exista el sistema de dinero
	LevelRewards = {} :: { [number]: { Coins: number?, Gems: number?, ToolId: string? } },
}
