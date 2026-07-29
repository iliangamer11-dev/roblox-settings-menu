--!nonstrict
--[[
	PetService
	----------------------------------------------------------------------------
	ESQUELETO. Inventario de mascotas, equipamiento y bonus asociados.

	PREPARADO PARA: mascotas.
	Los datos viven ya en Profile.Pets y los remotes existen. Falta el modelo
	que sigue al jugador y conectar el bonus con MultiplierService.

	API prevista
		PetService:Grant(player, petId)      -> uid?
		PetService:Toggle(player, uid)       -> boolean
		PetService:GetEquipped(player)       -> { OwnedPet }
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)

local log = Logger.new("PetService")

local PetService = {}
PetService.Name = "PetService"
PetService.Priority = 300

function PetService:Init()
	self._data = nil
	self._replication = nil
	self._multipliers = nil
	self._nextUid = 0
end

function PetService:Start()
	self._data = Loader.Get("DataService")
	self._replication = Loader.Get("ReplicationService")
	self._multipliers = Loader.Get("MultiplierService")

	Net.OnInvoke("RequestTogglePet", function(player, uid)
		if type(uid) ~= "string" then
			return false
		end
		return self:Toggle(player, uid)
	end)

	log:Debug("Sistema de mascotas preparado (%d en el catalogo)", self:_catalogSize())
end

function PetService:_catalogSize(): number
	local count = 0
	for _ in pairs(Config.Pets.Pets) do
		count += 1
	end
	return count
end

function PetService:_pets(player: Player)
	local profile = self._data:GetProfile(player)
	return profile and profile.Pets or nil
end

function PetService:_generateUid(): string
	self._nextUid += 1
	return string.format("%d-%d", os.time(), self._nextUid)
end

function PetService:Grant(player: Player, petId: string): string?
	local definition = Config.Pets.Pets[petId]
	if not definition then
		log:Warn("Mascota desconocida '%s'", petId)
		return nil
	end

	local pets = self:_pets(player)
	if not pets then
		return nil
	end

	local uid = self:_generateUid()
	pets[uid] = { Uid = uid, Id = petId, Level = 1, Equipped = false }

	self._data:MarkDirty(player)
	Net.FireClient("PetsUpdated", player, pets)

	return uid
end

function PetService:GetEquipped(player: Player)
	local pets = self:_pets(player)
	local equipped = {}
	if not pets then
		return equipped
	end
	for _, pet in pairs(pets) do
		if pet.Equipped then
			table.insert(equipped, pet)
		end
	end
	return equipped
end

--[[
	Equipa o desequipa una mascota respetando el maximo.
	TODO: crear/eliminar el modelo que sigue al jugador y refrescar los
	multiplicadores derivados.
--]]
function PetService:Toggle(player: Player, uid: string): boolean
	local pets = self:_pets(player)
	local pet = pets and pets[uid]
	if not pet then
		return false
	end

	if not pet.Equipped and #self:GetEquipped(player) >= Config.Pets.MaxEquipped then
		return false
	end

	pet.Equipped = not pet.Equipped

	self._data:MarkDirty(player)
	Net.FireClient("PetsUpdated", player, pets)

	return true
end

return PetService
