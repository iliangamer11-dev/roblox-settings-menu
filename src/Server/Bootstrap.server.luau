--!nonstrict
--[[
	Bootstrap (Script - ServerScriptService.Server.Bootstrap)
	----------------------------------------------------------------------------
	UNICO Script del servidor. Todo lo demas son ModuleScripts cargados desde
	aqui, lo que garantiza un orden de arranque determinista:

		1. Crear los remotes (antes de que cualquier servicio los use).
		2. Cargar los servicios.
		3. Init() -> Start() de todos los servicios.

	No anadir logica de juego en este archivo: crear un servicio nuevo en
	Server/Services y el Loader lo recogera solo.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)

local RemoteBuilder = require(script.Parent.Network.RemoteBuilder)

local log = Logger.new("Bootstrap")
local startedAt = os.clock()

log:Info("Arrancando %s v%s", Config.Game.GameName, Config.Game.GameVersion)

-- 1. Red
RemoteBuilder.Build()

-- 2. Servicios
Loader.LoadFrom(script.Parent.Services)

-- 3. Ciclo de vida
Loader.Start()

log:Info("Servidor listo en %.3f s", os.clock() - startedAt)
