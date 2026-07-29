--!nonstrict
--[[
	Migrations
	----------------------------------------------------------------------------
	Transformaciones de perfiles antiguos hacia el esquema actual.

	Cada entrada migra de la version `index` a `index + 1`. DataService las
	aplica en cadena hasta llegar a DataConfig.SchemaVersion.

	Ejemplo de migracion (de la version 1 a la 2):

		[1] = function(profile)
			profile.Currencies.Gems = profile.Currencies.Gems or 0
			profile.OldField = nil
		end,

	Las migraciones deben ser idempotentes y no fallar nunca: si algo va mal,
	es mejor dejar el campo con su valor por defecto que perder el perfil.
--]]

local Migrations = {}

Migrations.Steps = {} :: { [number]: (profile: { [any]: any }) -> () }

--[[
	Aplica todas las migraciones necesarias. Devuelve la version final y si
	hubo cambios.
--]]
function Migrations.Apply(profile: { [any]: any }, targetVersion: number): (number, boolean)
	local version = tonumber(profile.SchemaVersion) or 1
	local migrated = false

	while version < targetVersion do
		local step = Migrations.Steps[version]
		if step then
			local ok, err = pcall(step, profile)
			if not ok then
				warn(string.format("[Migrations] Fallo migrando v%d -> v%d: %s", version, version + 1, tostring(err)))
			end
			migrated = true
		end
		version += 1
	end

	profile.SchemaVersion = version
	return version, migrated
end

return Migrations
