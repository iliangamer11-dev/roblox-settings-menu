--!nonstrict
--[[
	ClientState
	----------------------------------------------------------------------------
	Copia local (solo lectura) del perfil del jugador. Es la unica fuente de
	datos para la interfaz: ningun controlador debe pedir datos al servidor por
	su cuenta.

	Lo rellena DataController a partir de los remotes ProfileLoaded y
	ProfileUpdated.

		ClientState:Get()                     -> perfil completo o nil
		ClientState:GetCurrency("Coins")      -> number
		ClientState.Changed                   Signal(path, value)
		ClientState.Ready                     Signal(profile)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)
local TableUtil = require(Shared.Util.TableUtil)

-- Vive fuera de Controllers a proposito: el Loader solo carga Controllers, asi
-- que este modulo es un singleton que se requiere directamente.
local ClientState = {}

ClientState._profile = nil
ClientState.Changed = Signal.new()
ClientState.Ready = Signal.new()
ClientState.IsReady = false

--[[
	Sustituye el perfil completo (ProfileLoaded).
--]]
function ClientState:SetProfile(profile: any)
	self._profile = profile
	self.IsReady = profile ~= nil

	if self.IsReady then
		self.Ready:Fire(profile)
		self.Changed:Fire("*", profile)
	end
end

--[[
	Aplica un cambio parcial (ProfileUpdated).
	`path` es una clave de primer nivel del perfil: "Currencies", "Stats"...
--]]
function ClientState:Merge(path: string, value: any)
	if not self._profile then
		return
	end

	if type(value) == "table" and type(self._profile[path]) == "table" then
		for key, entry in pairs(value) do
			self._profile[path][key] = entry
		end
	else
		self._profile[path] = value
	end

	self.Changed:Fire(path, self._profile[path])
end

function ClientState:Get()
	return self._profile
end

--[[
	Copia profunda: usar cuando algo necesite mutar los datos sin afectar al
	estado compartido.
--]]
function ClientState:Clone()
	return if self._profile then TableUtil.DeepCopy(self._profile) else nil
end

function ClientState:GetCurrency(currencyId: string): number
	local profile = self._profile
	return if profile then (tonumber(profile.Currencies[currencyId]) or 0) else 0
end

function ClientState:GetStat(stat: string): number
	local profile = self._profile
	return if profile then (tonumber(profile.Stats[stat]) or 0) else 0
end

function ClientState:GetLevel(): number
	local profile = self._profile
	return if profile then profile.Progression.Level else 1
end

function ClientState:GetEquippedTool(): string?
	local profile = self._profile
	return if profile then profile.Tools.Equipped else nil
end

return ClientState
