--!nonstrict
--[[
	DataController
	----------------------------------------------------------------------------
	Puente entre los remotes de datos y ClientState. Es el unico controlador
	que escribe en ClientState.

	Si por cualquier motivo no llega ProfileLoaded (por ejemplo el cliente
	arranco despues que el servidor enviara el evento), pide el perfil con la
	RemoteFunction GetProfile.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)

local ClientState = require(script.Parent.Parent.State.ClientState)

local log = Logger.new("DataController")

local DataController = {}
DataController.Name = "DataController"
-- Debe estar listo antes que cualquier controlador de interfaz.
DataController.Priority = 1000

function DataController:Init()
	self.State = ClientState
end

function DataController:Start()
	Net.OnClientEvent("ProfileLoaded", function(profile)
		log:Debug("Perfil recibido del servidor")
		ClientState:SetProfile(profile)
	end)

	Net.OnClientEvent("ProfileUpdated", function(path, value)
		ClientState:Merge(path, value)
	end)

	-- Fallback si el perfil no llego en los primeros segundos
	task.delay(5, function()
		if ClientState.IsReady then
			return
		end

		log:Warn("Sin perfil tras 5 s, solicitandolo al servidor")
		local ok, profile = pcall(function()
			return Net.Invoke("GetProfile")
		end)

		if ok and profile then
			ClientState:SetProfile(profile)
		else
			log:Error("No se pudo obtener el perfil del servidor")
		end
	end)
end

return DataController
