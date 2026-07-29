--!nonstrict
--[[
	Bootstrap (LocalScript - StarterPlayerScripts.Client.Bootstrap)
	----------------------------------------------------------------------------
	UNICO LocalScript del juego. Igual que en el servidor, todo lo demas son
	ModuleScripts (Controllers) cargados con el Loader compartido.

		1. Esperar la carpeta de remotes creada por el servidor.
		2. Cargar los controladores.
		3. Init() -> Start().

	No anadir logica de juego aqui.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Loader = require(Shared.Framework.Loader)
local Logger = require(Shared.Util.Logger)
local RemoteDefinitions = require(Shared.Network.RemoteDefinitions)

local log = Logger.new("Bootstrap")
local startedAt = os.clock()

local player = Players.LocalPlayer

-- 1. Sincronizacion con el servidor: sin remotes no se puede arrancar
if not ReplicatedStorage:WaitForChild(RemoteDefinitions.FolderName, 60) then
	log:Fatal("El servidor no creo la carpeta de remotes")
end

log:Info("Cliente de %s v%s iniciando para %s", Config.Game.GameName, Config.Game.GameVersion, player.Name)

-- 2. Controladores
Loader.LoadFrom(script.Parent.Controllers)

-- 3. Ciclo de vida
Loader.Start()

log:Info("Cliente listo en %.3f s", os.clock() - startedAt)
