--!nonstrict
--[[
	DataStoreWrapper
	----------------------------------------------------------------------------
	Capa fina sobre DataStoreService con:

		* Reintentos con backoff exponencial.
		* Store simulado en Studio (DataConfig.UseMockStoreInStudio) para poder
		  iterar sin depender de la API real ni de "Enable Studio Access to
		  API Services".
		* Misma API en ambos modos, de modo que DataService no sabe cual usa.

	IMPORTANTE: este modulo solo lee y escribe. Toda la logica de perfiles
	(plantilla, bloqueo de sesion, autosave) vive en DataService.
--]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)

local log = Logger.new("DataStoreWrapper")

local DataStoreWrapper = {}
DataStoreWrapper.__index = DataStoreWrapper

local USE_MOCK = RunService:IsStudio() and Config.Data.UseMockStoreInStudio

--------------------------------------------------------------------------------
-- Store simulado (solo Studio)
--------------------------------------------------------------------------------

local MockStore = {}
MockStore.__index = MockStore

function MockStore.new()
	return setmetatable({ _data = {} }, MockStore)
end

function MockStore:GetAsync(key: string)
	return self._data[key]
end

function MockStore:SetAsync(key: string, value: any)
	self._data[key] = value
end

function MockStore:UpdateAsync(key: string, transform: (any) -> any)
	local newValue = transform(self._data[key])
	if newValue ~= nil then
		self._data[key] = newValue
	end
	return self._data[key]
end

function MockStore:RemoveAsync(key: string)
	local previous = self._data[key]
	self._data[key] = nil
	return previous
end

--------------------------------------------------------------------------------
-- Wrapper
--------------------------------------------------------------------------------

--[[
	Ejecuta una operacion de DataStore con reintentos.
	Devuelve (success: boolean, resultOrError: any).
--]]
local function retry(label: string, operation: () -> any): (boolean, any)
	local attempts = Config.Data.SaveRetryAttempts
	local delay = Config.Data.SaveRetryBaseDelay

	for attempt = 1, attempts do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end

		log:Warn("%s fallo (intento %d/%d): %s", label, attempt, attempts, tostring(result))

		if attempt < attempts then
			task.wait(delay)
			delay *= 2
		else
			return false, result
		end
	end

	return false, "unreachable"
end

function DataStoreWrapper.new(name: string, scope: string?)
	local store
	if USE_MOCK then
		log:Warn("Usando DataStore SIMULADO en Studio (los datos no persisten)")
		store = MockStore.new()
	else
		store = DataStoreService:GetDataStore(name, scope)
	end

	return setmetatable({
		_store = store,
		_name = name,
		IsMock = USE_MOCK,
	}, DataStoreWrapper)
end

function DataStoreWrapper:Get(key: string): (boolean, any)
	return retry("GetAsync:" .. key, function()
		return self._store:GetAsync(key)
	end)
end

function DataStoreWrapper:Set(key: string, value: any): (boolean, any)
	return retry("SetAsync:" .. key, function()
		return self._store:SetAsync(key, value)
	end)
end

--[[
	Actualizacion transaccional. `transform(current)` debe devolver el valor
	nuevo o nil para abortar.
--]]
function DataStoreWrapper:Update(key: string, transform: (any) -> any): (boolean, any)
	return retry("UpdateAsync:" .. key, function()
		return self._store:UpdateAsync(key, transform)
	end)
end

function DataStoreWrapper:Remove(key: string): (boolean, any)
	return retry("RemoveAsync:" .. key, function()
		return self._store:RemoveAsync(key)
	end)
end

return DataStoreWrapper
