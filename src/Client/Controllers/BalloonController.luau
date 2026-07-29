--!nonstrict
--[[
	BalloonController
	----------------------------------------------------------------------------
	ESQUELETO. Lado cliente de los globos: escucha la aparicion y el pinchado
	para reproducir efectos locales.

	PREPARADO PARA: aparicion de globos + sistema de pinchar globos.

	Los globos los crea el servidor en Workspace.World.Balloons; este
	controlador solo se encarga de lo visual (particulas, sonido, numeros
	flotantes), nunca de la logica de recompensas.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)

local log = Logger.new("BalloonController")

local BalloonController = {}
BalloonController.Name = "BalloonController"
BalloonController.Priority = 400

function BalloonController:Init()
	self._container = nil
end

function BalloonController:Start()
	local world = Workspace:WaitForChild(Config.Game.Containers.World, 30)
	self._container = world and world:WaitForChild(Config.Game.Containers.Balloons, 30)

	if not self._container then
		log:Debug("El contenedor de globos aun no existe")
	end

	Net.OnClientEvent("BalloonSpawned", function(payload)
		self:_onSpawned(payload)
	end)

	Net.OnClientEvent("BalloonPopped", function(payload)
		self:_onPopped(payload)
	end)
end

--[[
	TODO: animacion de entrada / flotacion del globo.
--]]
function BalloonController:_onSpawned(payload: any) end

--[[
	TODO: particulas, sonido y numeros flotantes de recompensa.
--]]
function BalloonController:_onPopped(payload: any) end

return BalloonController
