--!strict
--[[
	MultiplierConfig
	Tipos de multiplicador y como se combinan.

	PREPARADO PARA: multiplicadores (gamepass, mascotas, pociones, eventos).
--]]

export type MultiplierKind = "Coins" | "Experience" | "PopPower" | "Luck"

return {
	-- Multiplicador base cuando no hay ninguna fuente activa
	BaseValue = 1,

	-- Los multiplicadores del mismo tipo se combinan de esta forma:
	-- "Additive"  -> 1 + (a-1) + (b-1)
	-- "Multiplicative" -> a * b
	StackMode = "Additive",

	MaxValuePerKind = {
		Coins = 100,
		Experience = 100,
		PopPower = 100,
		Luck = 50,
	} :: { [string]: number },

	-- Fuentes permanentes conocidas (gamepasses, etc.)
	-- TODO: anadir ids reales de gamepass
	Sources = {} :: { [string]: { Kind: string, Value: number, GamePassId: number? } },
}
