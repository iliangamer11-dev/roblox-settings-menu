--!strict
--[[
	EconomyConfig
	Definicion de monedas del juego.

	PREPARADO PARA: sistema de dinero.
--]]

export type CurrencyDefinition = {
	Id: string,
	DisplayName: string,
	Abbreviation: string,
	StartingAmount: number,
	Max: number,
	Persistent: boolean,
	Icon: string?, -- rbxassetid
}

local Currencies: { [string]: CurrencyDefinition } = {
	Coins = {
		Id = "Coins",
		DisplayName = "Monedas",
		Abbreviation = "$",
		StartingAmount = 0,
		Max = 1e15,
		Persistent = true,
	},
	Gems = {
		Id = "Gems",
		DisplayName = "Gemas",
		Abbreviation = "G",
		StartingAmount = 0,
		Max = 1e12,
		Persistent = true,
	},
}

return {
	Currencies = Currencies,
	Order = { "Coins", "Gems" },
}
