--[[
	ClientSettings
	Ajustes personales de cada jugador (volumen, que se ve en pantalla...).

	Es un ModuleScript, asi que todos los LocalScripts del mismo cliente comparten el
	mismo estado sin necesidad de RemoteEvents. Son preferencias locales: no se mandan
	al servidor ni afectan a los demas jugadores.

	Uso:
		local Settings = require(ReplicatedStorage.ClientSettings)
		Settings.get("showLevelBar")
		Settings.set("showLevelBar", false)
		Settings.Changed.Event:Connect(function(key, value) ... end)

	Aviso: no se guardan al salir. Para eso haria falta DataStore en el servidor.
]]

local ClientSettings = {}

ClientSettings.Defaults = {
	musicVolume = 0.5, -- 0 a 1
	musicMuted = false,
	showLevelBar = true,
	showMoneyPopups = true, -- los carteles de "+20 Diamond"
	showHoles = true, -- las marcas del picazo en el suelo
	showNameplates = true, -- nombre y nivel sobre los personajes
}

local values = table.clone(ClientSettings.Defaults)

ClientSettings.Changed = Instance.new("BindableEvent")

function ClientSettings.get(key: string): any
	return values[key]
end

function ClientSettings.set(key: string, value: any)
	if values[key] == value then
		return
	end

	values[key] = value
	ClientSettings.Changed:Fire(key, value)
end

function ClientSettings.toggle(key: string): boolean
	ClientSettings.set(key, not values[key])
	return values[key]
end

return ClientSettings
