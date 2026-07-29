--!nonstrict
--[[
	UIController
	----------------------------------------------------------------------------
	ESQUELETO. Dueno de la interfaz: registra las pantallas, abre y cierra
	ventanas y garantiza que solo haya una abierta a la vez.

	PREPARADO PARA: tiendas, mejoras, mascotas, misiones y zonas. Cada sistema
	registrara su ventana aqui en lugar de manipular ScreenGuis por su cuenta.

	API
		UIController:Register("Shop", screenGui)
		UIController:Open("Shop")
		UIController:Close("Shop")
		UIController:Toggle("Shop")
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared.Util.Logger)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("UIController")

local UIController = {}
UIController.Name = "UIController"
UIController.Priority = 900

function UIController:Init()
	self._screens = {} :: { [string]: any }
	self._openScreen = nil

	self.ScreenOpened = Signal.new()
	self.ScreenClosed = Signal.new()
end

function UIController:Start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Contenedor sincronizado desde StarterGui.Interface
	self.Interface = playerGui:WaitForChild("Interface", 10)
	if not self.Interface then
		log:Debug("StarterGui.Interface todavia no tiene pantallas")
	end
end

function UIController:Register(name: string, container: Instance)
	if self._screens[name] then
		log:Warn("La pantalla '%s' ya estaba registrada", name)
	end
	self._screens[name] = container
	if container:IsA("ScreenGui") then
		container.Enabled = false
	end
end

function UIController:Open(name: string)
	local screen = self._screens[name]
	if not screen then
		log:Warn("Pantalla desconocida '%s'", name)
		return
	end

	if self._openScreen and self._openScreen ~= name then
		self:Close(self._openScreen)
	end

	screen.Enabled = true
	self._openScreen = name
	self.ScreenOpened:Fire(name)
end

function UIController:Close(name: string)
	local screen = self._screens[name]
	if not screen then
		return
	end

	screen.Enabled = false
	if self._openScreen == name then
		self._openScreen = nil
	end
	self.ScreenClosed:Fire(name)
end

function UIController:Toggle(name: string)
	if self._openScreen == name then
		self:Close(name)
	else
		self:Open(name)
	end
end

function UIController:GetOpen(): string?
	return self._openScreen
end

return UIController
