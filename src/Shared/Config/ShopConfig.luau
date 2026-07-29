--!strict
--[[
	ShopConfig
	Catalogo de tiendas y sus articulos.

	PREPARADO PARA: tiendas.
--]]

export type ShopItem = {
	Id: string,
	Kind: string, -- "Tool" | "Pet" | "Multiplier" | "ZoneKey"
	TargetId: string, -- id del elemento entregado (ej. "Cuchillo")
	Price: number,
	Currency: string,
	Order: number,
	RequiredLevel: number?,
}

export type ShopDefinition = {
	Id: string,
	DisplayName: string,
	ZoneId: string?, -- tienda fisica ligada a una zona
	Items: { ShopItem },
}

local Shops: { [string]: ShopDefinition } = {
	-- TODO: definir tiendas (herramientas, mascotas, mejoras)
}

return {
	Shops = Shops,
}
