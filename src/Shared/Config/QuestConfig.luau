--!strict
--[[
	QuestConfig
	Definicion de misiones.

	PREPARADO PARA: misiones.
--]]

export type QuestDefinition = {
	Id: string,
	DisplayName: string,
	Description: string,
	-- Estadistica que hace avanzar la mision (ver Types.PlayerStats)
	TrackedStat: string,
	Goal: number,
	Reward: { Coins: number?, Gems: number?, Experience: number? },
	Repeatable: boolean,
	ResetPeriod: string?, -- "Daily" | "Weekly" | nil
	RequiredLevel: number?,
}

local Quests: { [string]: QuestDefinition } = {
	-- TODO: definir misiones reales
}

return {
	Quests = Quests,
	MaxActiveQuests = 5,
}
