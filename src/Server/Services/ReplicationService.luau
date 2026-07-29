--!nonstrict
--[[
	ReplicationService
	----------------------------------------------------------------------------
	Unico responsable de enviar el estado del perfil al cliente. Los demas
	servicios modifican el perfil y llaman aqui para replicar el cambio, de
	forma que solo existe un camino servidor -> cliente para los datos.

	API
		ReplicationService:SendFullProfile(player)
		ReplicationService:PushPath(player, "Currencies", { Coins = 100 })
		ReplicationService:Notify(player, "Mensaje", "Info")
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local Loader = require(Shared.Framework.Loader)

local log = Logger.new("ReplicationService")

local ReplicationService = {}
ReplicationService.Name = "ReplicationService"
ReplicationService.Priority = 900

function ReplicationService:Init()
	self._data = nil
end

function ReplicationService:Start()
	self._data = Loader.Get("DataService")

	-- Envio automatico en cuanto el perfil termina de cargar
	self._data.ProfileLoaded:Connect(function(player, profile)
		self:_send(player, profile)
	end)

	-- Fallback: el cliente puede pedir su perfil explicitamente
	Net.OnInvoke("GetProfile", function(player)
		return self._data:GetProfile(player)
	end)

	log:Debug("Replicacion de perfiles activa")
end

function ReplicationService:_send(player: Player, profile: any)
	Net.FireClient("ProfileLoaded", player, profile)
end

function ReplicationService:SendFullProfile(player: Player)
	local profile = self._data:GetProfile(player)
	if profile then
		self:_send(player, profile)
	end
end

--[[
	Replica un fragmento del perfil.
		PushPath(player, "Currencies", { Coins = 250 })
	El cliente hace merge del fragmento en su copia local (ClientState).
--]]
function ReplicationService:PushPath(player: Player, path: string, value: any)
	Net.FireClient("ProfileUpdated", player, path, value)
end

--[[
	Aviso generico para la interfaz.
	kind: "Info" | "Success" | "Warning" | "Error"
--]]
function ReplicationService:Notify(player: Player, message: string, kind: string?)
	Net.FireClient("Notify", player, message, kind or "Info")
end

return ReplicationService
