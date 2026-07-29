--!nonstrict
--[[
	BalloonService
	----------------------------------------------------------------------------
	Servicio que conecta el BalloonManager con el resto del juego. Es
	deliberadamente fino: prepara los contenedores, arranca el manager y expone
	su API. Toda la logica de aparicion vive en Server/Balloons/BalloonManager,
	que no depende de ningun otro servicio.

	Arbol que garantiza al arrancar:

		Workspace.World
		├── Balloons     globos activos (replicado a los clientes)
		└── Spawners     areas de aparicion (Parts)

		ServerStorage
		└── BalloonReserve   instancias recicladas (NO replicadas)

	Poner la reserva en ServerStorage es intencionado: las instancias dormidas
	no se replican al cliente, asi que reciclar no cuesta ancho de banda.

	PREPARADO PARA (siguiente paso: pinchar globos)
		Net.OnEvent("RequestPopBalloon", ...) ya esta enganchado y valida la
		forma del mensaje. Lo unico que falta es la validacion de distancia y
		cooldown, y llamar a Manager:ApplyDamage con la potencia de la Tool.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)

local BalloonManager = require(script.Parent.Parent.Balloons.BalloonManager)

local log = Logger.new("BalloonService")

local RESERVE_NAME = "BalloonReserve"

local BalloonService = {}
BalloonService.Name = "BalloonService"
BalloonService.Priority = 400

--------------------------------------------------------------------------------
-- Ciclo de vida
--------------------------------------------------------------------------------

function BalloonService:Init()
	self.Manager = nil
	self._containers = nil
end

function BalloonService:Start()
	self._containers = self:_ensureContainers()

	self.Manager = BalloonManager.new({
		Container = self._containers.Balloons,
		Reserve = self._containers.Reserve,
		Assets = self._containers.Assets,
		SpawnersFolder = self._containers.Spawners,
	})

	-- Handler ya registrado: el sistema de pinchado solo tendra que rellenar
	-- _onPopRequest, sin tocar la capa de red.
	Net.OnEvent("RequestPopBalloon", function(player, balloonId)
		self:_onPopRequest(player, balloonId)
	end)

	if Config.Balloons.Spawning.Enabled then
		self.Manager:Start()
	else
		log:Warn("Aparicion desactivada (BalloonConfig.Spawning.Enabled = false)")
	end

	if Config.Game.Debug then
		task.spawn(function()
			self:_statsLoop()
		end)
	end
end

--------------------------------------------------------------------------------
-- Contenedores
--------------------------------------------------------------------------------

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function BalloonService:_ensureContainers()
	local names = Config.Game.Containers

	local world = ensureFolder(Workspace, names.World)
	local balloons = ensureFolder(world, names.Balloons)
	local spawners = ensureFolder(world, names.Spawners)
	local reserve = ensureFolder(ServerStorage, RESERVE_NAME)

	local assets = ServerStorage:FindFirstChild("Assets")
	local balloonAssets = assets and assets:FindFirstChild(names.Balloons)

	if not balloonAssets then
		log:Debug("Sin modelos en ServerStorage.Assets.Balloons: se generaran por codigo")
	end

	return {
		World = world,
		Balloons = balloons,
		Spawners = spawners,
		Reserve = reserve,
		Assets = balloonAssets,
	}
end

--------------------------------------------------------------------------------
-- Red
--------------------------------------------------------------------------------

--[[
	TODO (sistema de pinchado):
		1. entry = self.Manager:GetFromInstance(...) o :Get(balloonId)
		2. Validar distancia: (character.Position - entry.Position).Magnitude
		   <= Config.Balloons.Popping.MaxHitDistance
		3. Validar cooldown segun ToolService:GetStats(player).Cooldown
		4. self.Manager:ApplyDamage(balloonId, stats.Power, player)
		5. Si devuelve destruido, pagar con CurrencyService y sumar StatsService
--]]
function BalloonService:_onPopRequest(player: Player, balloonId: any)
	if type(balloonId) ~= "string" then
		return
	end

	local entry = self.Manager and self.Manager:Get(balloonId)
	if not entry then
		return
	end

	log:Debug("%s intento pinchar '%s' (%s) - pinchado sin implementar", player.Name, balloonId, entry.DefinitionId)
end

--------------------------------------------------------------------------------
-- API para otros servicios
--------------------------------------------------------------------------------

function BalloonService:GetStats()
	return if self.Manager then self.Manager:GetStats() else nil
end

function BalloonService:GetActiveCount(): number
	return if self.Manager then self.Manager:GetActiveCount() else 0
end

--[[
	Fuerza la aparicion de un globo. Util para pruebas y para futuros eventos.
--]]
function BalloonService:SpawnOne(zoneId: string?)
	return if self.Manager then self.Manager:SpawnOne(zoneId) else nil
end

--------------------------------------------------------------------------------
-- Diagnostico
--------------------------------------------------------------------------------

function BalloonService:_statsLoop()
	while true do
		task.wait(30)

		local stats = self:GetStats()
		if stats then
			log:Debug(
				"activos %d/%d | puntos %d | instancias creadas %d | en reserva %d",
				stats.Active,
				stats.MaxActive,
				stats.SpawnPoints,
				stats.InstancesCreated,
				stats.InstancesPooled
			)
		end
	end
end

return BalloonService
