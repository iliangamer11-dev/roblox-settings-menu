--!nonstrict
--[[
	ProfileTemplate
	----------------------------------------------------------------------------
	Forma canonica del perfil que se guarda en el DataStore.

	Reglas de oro:
		* Anadir campos nuevos SIEMPRE aqui. Al cargar, DataService reconcilia
		  el perfil guardado con esta plantilla, asi que los jugadores antiguos
		  reciben los campos nuevos automaticamente.
		* Renombrar o cambiar el significado de un campo requiere subir
		  DataConfig.SchemaVersion y anadir una migracion en Migrations.luau.
		* Solo tipos serializables: numeros, strings, booleanos y tablas.
		  Nunca Instances, Vector3, Color3 ni funciones.
--]]

local Config = require(script.Parent.Parent.Config)
local TableUtil = require(script.Parent.Parent.Util.TableUtil)
local Types = require(script.Parent.Parent.Types)

local ProfileTemplate = {}

local function buildStartingCurrencies(): { [string]: number }
	local wallet = {}
	for id, currency in pairs(Config.Economy.Currencies) do
		wallet[id] = currency.StartingAmount
	end
	return wallet
end

local function buildStartingTools()
	local owned = {}
	local equipped = nil

	for id, tool in pairs(Config.Tools.Tools) do
		if tool.Default then
			owned[id] = {
				Id = id,
				Upgrades = {},
				AcquiredAt = 0,
			}
			equipped = equipped or id
		end
	end

	return {
		Equipped = equipped or Config.Tools.DefaultToolId,
		Owned = owned,
	}
end

local function buildStartingZones(): { [string]: boolean }
	local zones = {}
	for id, zone in pairs(Config.Zones.Zones) do
		if zone.Unlocked then
			zones[id] = true
		end
	end
	return zones
end

--[[
	Plantilla base. No se devuelve directamente: usar `ProfileTemplate.new()`
	para obtener una copia limpia.
--]]
local TEMPLATE = {
	SchemaVersion = Config.Data.SchemaVersion,

	Currencies = buildStartingCurrencies(),

	Stats = {
		BalloonsPopped = 0,
		CoinsEarned = 0,
		GemsEarned = 0,
		CoinsSpent = 0,
		PlayTime = 0,
		Rebirths = 0,
		HighestCombo = 0,
		QuestsCompleted = 0,
		ZonesUnlocked = 0,
	},

	Progression = {
		Level = Config.Levels.StartingLevel,
		Experience = 0,
	},

	Tools = buildStartingTools(),

	-- Uid -> OwnedPet
	Pets = {},

	-- QuestId -> QuestProgress
	Quests = {},

	-- SourceId -> MultiplierSource
	Multipliers = {},

	-- ZoneId -> true
	UnlockedZones = buildStartingZones(),

	Settings = {
		Music = true,
		SoundEffects = true,
		ScreenShake = true,
		DamageNumbers = true,
	},

	Meta = {
		FirstJoin = 0,
		LastJoin = 0,
		SessionCount = 0,
	},
}

--[[
	Copia nueva de la plantilla para un jugador que entra por primera vez.
--]]
function ProfileTemplate.new(): Types.PlayerProfile
	return TableUtil.DeepCopy(TEMPLATE)
end

--[[
	Completa un perfil cargado del DataStore con los campos que le falten.
--]]
function ProfileTemplate.Reconcile(profile: { [any]: any }): Types.PlayerProfile
	return TableUtil.Reconcile(profile, TEMPLATE)
end

ProfileTemplate.Raw = TEMPLATE

return ProfileTemplate
