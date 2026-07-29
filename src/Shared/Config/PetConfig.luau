--!strict
--[[
	PetConfig
	Catalogo de mascotas.

	PREPARADO PARA: mascotas.
--]]

export type PetDefinition = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	Model: string, -- nombre del modelo en ServerStorage.Assets.Pets
	Multiplier: { Kind: string, Value: number },
	Price: number?,
	Currency: string?,
}

local Pets: { [string]: PetDefinition } = {
	-- TODO: definir el catalogo real de mascotas
}

return {
	Pets = Pets,
	MaxEquipped = 3,
	FollowDistance = 4,
}
