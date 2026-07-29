--!nonstrict
--[[
	Logger
	Log con prefijo y niveles. Los mensajes de debug solo se imprimen si
	GameConfig.Debug esta activo, asi que se pueden dejar en el codigo.

		local log = Logger.new("DataService")
		log:Info("Perfil cargado para %s", player.Name)
--]]

local Config = require(script.Parent.Parent.Config)

local Logger = {}
Logger.__index = Logger

local function compose(scope: string, level: string, message: string, ...): string
	local text = if select("#", ...) > 0 then string.format(message, ...) else message
	return string.format("[%s][%s] %s", scope, level, text)
end

function Logger.new(scope: string)
	return setmetatable({ _scope = scope }, Logger)
end

function Logger:Debug(message: string, ...)
	if Config.Game.Debug and Config.Game.VerboseLogs then
		print(compose(self._scope, "DEBUG", message, ...))
	end
end

function Logger:Info(message: string, ...)
	print(compose(self._scope, "INFO", message, ...))
end

function Logger:Warn(message: string, ...)
	warn(compose(self._scope, "WARN", message, ...))
end

--[[
	Registra el error sin detener la ejecucion del llamante.
--]]
function Logger:Error(message: string, ...)
	local text = compose(self._scope, "ERROR", message, ...)
	warn(text .. "\n" .. debug.traceback())
end

--[[
	Error fatal: detiene el hilo actual.
--]]
function Logger:Fatal(message: string, ...)
	error(compose(self._scope, "FATAL", message, ...), 2)
end

return Logger
