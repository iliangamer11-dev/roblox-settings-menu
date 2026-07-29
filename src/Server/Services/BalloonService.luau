--!nonstrict
--[[
	BalloonService
	----------------------------------------------------------------------------
	ESQUELETO. Sera el dueno de los globos del mundo: aparicion, registro de
	globos activos y validacion del pinchado.

	PREPARADO PARA: aparicion de globos + sistema de pinchar globos.

	Estado actual:
		* Crea el contenedor Workspace.World.Balloons si no existe.
		* Registra el handler de RequestPopBalloon (sin efecto todavia).
		* Deja el bucle de aparicion desactivado (BalloonConfig.Spawning.Enabled).

	Plan del siguiente paso:
		1. Modelos de globo en ServerStorage.Assets.Balloons.
		2. Spawner por zona leyendo ZoneConfig.BalloonIds y los pesos de rareza.
		3. Pop: validar distancia (BalloonConfig.Popping.MaxHitDistance),
		   cooldown segun ToolService:GetStats, aplicar dano y al morir dar
		   recompensa via CurrencyService/StatsService/LevelService.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("BalloonService")

local BalloonService = {}
BalloonService.Name = "BalloonService"
BalloonService.Priority = 400

function BalloonService:Init()
	self._tools = nil
	self._currency = nil
	self._stats = nil

	-- BalloonId de instancia -> datos del globo activo
	self._active = {} :: { [string]: any }
	self._nextId = 0

	self.BalloonSpawned = Signal.new() -- (balloonId, model)
	self.BalloonPopped = Signal.new() -- (player, balloonId, definition)
end

function BalloonService:Start()
	self._tools = Loader.Get("ToolService")
	self._currency = Loader.Get("CurrencyService")
	self._stats = Loader.Get("StatsService")

	self._container = self:_ensureContainer()

	Net.OnEvent("RequestPopBalloon", function(player, balloonId)
		self:_onPopRequest(player, balloonId)
	end)

	if Config.Balloons.Spawning.Enabled then
		task.spawn(function()
			self:_spawnLoop()
		end)
	else
		log:Debug("Aparicion de globos desactivada (BalloonConfig.Spawning.Enabled = false)")
	end
end

--[[
	Contenedor en tiempo de ejecucion de los globos activos.
--]]
function BalloonService:_ensureContainer(): Folder
	local world = Workspace:FindFirstChild(Config.Game.Containers.World)
	if not world then
		world = Instance.new("Folder")
		world.Name = Config.Game.Containers.World
		world.Parent = Workspace
	end

	local balloons = world:FindFirstChild(Config.Game.Containers.Balloons)
	if not balloons then
		balloons = Instance.new("Folder")
		balloons.Name = Config.Game.Containers.Balloons
		balloons.Parent = world
	end

	return balloons
end

function BalloonService:_nextBalloonId(): string
	self._nextId += 1
	return string.format("B%d", self._nextId)
end

--[[
	TODO: implementar la aparicion real.
--]]
function BalloonService:_spawnLoop()
	log:Warn("_spawnLoop todavia no esta implementado")
end

--[[
	TODO: validar y aplicar el pinchado.
	Pasos previstos:
		1. Comprobar que el globo existe en self._active.
		2. Comprobar cooldown del jugador (ToolService:GetStats().Cooldown).
		3. Comprobar distancia entre el personaje y el globo.
		4. Restar vida; si llega a 0 -> recompensa + BalloonPopped.
--]]
function BalloonService:_onPopRequest(player: Player, balloonId: any)
	if type(balloonId) ~= "string" then
		return
	end
	log:Debug("Peticion de pinchado de %s sobre %s (sin implementar)", player.Name, balloonId)
end

--[[
	Globos activos, para depuracion y para el sistema de zonas.
--]]
function BalloonService:GetActiveCount(): number
	local count = 0
	for _ in pairs(self._active) do
		count += 1
	end
	return count
end

return BalloonService
