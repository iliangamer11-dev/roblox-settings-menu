--!strict
--[[
	ToolConfig
	Catalogo de herramientas y sus lineas de mejora.

	PREPARADO PARA: Tool "Cuchillo" y mejoras de herramientas.
	La estructura de mejoras usa una formula por nivel para no tener que
	escribir cada nivel a mano.
--]]

export type UpgradeDefinition = {
	Id: string,
	DisplayName: string,
	MaxLevel: number,
	-- Coste del siguiente nivel
	Cost: (level: number) -> number,
	-- Valor efectivo de la mejora en un nivel dado
	Value: (level: number) -> number,
	Currency: string,
}

export type ToolDefinition = {
	Id: string,
	DisplayName: string,
	Description: string,
	Model: string, -- nombre del modelo en ServerStorage.Assets.Tools
	Price: number,
	Currency: string,
	Default: boolean, -- se otorga al entrar por primera vez
	Order: number, -- orden en la tienda
	Base: {
		Power: number, -- dano por pinchazo
		Range: number, -- alcance en studs
		Cooldown: number, -- segundos entre pinchazos
	},
	Upgrades: { [string]: UpgradeDefinition },
}

local Tools: { [string]: ToolDefinition } = {
	Cuchillo = {
		Id = "Cuchillo",
		DisplayName = "Cuchillo",
		Description = "La herramienta basica para pinchar globos.",
		Model = "Cuchillo",
		Price = 0,
		Currency = "Coins",
		Default = true,
		Order = 1,
		Base = {
			Power = 1,
			Range = 12,
			Cooldown = 0.35,
		},
		Upgrades = {
			-- TODO: balancear cuando exista el sistema de dinero
			Power = {
				Id = "Power",
				DisplayName = "Potencia",
				MaxLevel = 10,
				Currency = "Coins",
				Cost = function(level: number): number
					return math.floor(100 * (1.6 ^ level))
				end,
				Value = function(level: number): number
					return 1 + level
				end,
			},
			Speed = {
				Id = "Speed",
				DisplayName = "Velocidad",
				MaxLevel = 10,
				Currency = "Coins",
				Cost = function(level: number): number
					return math.floor(150 * (1.7 ^ level))
				end,
				Value = function(level: number): number
					return 0.35 * (0.95 ^ level)
				end,
			},
		},
	},
}

return {
	Tools = Tools,
	DefaultToolId = "Cuchillo",
}
