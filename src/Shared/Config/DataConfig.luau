--!strict
--[[
	DataConfig
	Configuracion de persistencia (DataStore). Cambiar `StoreName` o
	`SchemaVersion` implica empezar con datos nuevos: usar Migrations en su lugar.
--]]

return {
	-- Nombre del DataStore. El sufijo permite tener datos de test aislados.
	StoreName = "PlayerProfiles",
	StoreScope = "v1",

	-- Version del esquema del perfil. Incrementar al cambiar la forma de los
	-- datos y anadir la migracion correspondiente en Shared/Data/Migrations.
	SchemaVersion = 1,

	-- Guardado
	AutoSaveInterval = 120, -- segundos
	SaveRetryAttempts = 5,
	SaveRetryBaseDelay = 1, -- segundos, con backoff exponencial

	-- Bloqueo de sesion: evita que dos servidores escriban el mismo perfil
	SessionLock = {
		Enabled = true,
		Duration = 60, -- segundos de validez del lock
		RefreshInterval = 30,
		StealAfter = 180, -- si el lock es mas viejo que esto, se considera muerto
	},

	-- En Studio se puede desactivar la persistencia real para iterar rapido
	UseMockStoreInStudio = true,
}
