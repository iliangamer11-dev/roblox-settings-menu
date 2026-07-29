--!nonstrict
--[[
	InputController
	----------------------------------------------------------------------------
	ESQUELETO. Centraliza los atajos de teclado y gamepad, y expone acciones
	con nombre para que ningun otro controlador conecte UserInputService
	directamente (evita conflictos entre sistemas).

		InputController:BindAction("ToggleShop", Enum.KeyCode.F, function() end)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared.Util.Logger)

local log = Logger.new("InputController")

local InputController = {}
InputController.Name = "InputController"
InputController.Priority = 600

function InputController:Init()
	-- KeyCode.Name -> { name, callback }
	self._bindings = {}
end

function InputController:Start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		local binding = self._bindings[input.KeyCode.Name]
		if not binding then
			return
		end

		local ok, err = pcall(binding.callback)
		if not ok then
			log:Error("Accion '%s' fallo: %s", binding.name, tostring(err))
		end
	end)
end

function InputController:BindAction(name: string, keyCode: Enum.KeyCode, callback: () -> ())
	self._bindings[keyCode.Name] = { name = name, callback = callback }
end

function InputController:UnbindAction(keyCode: Enum.KeyCode)
	self._bindings[keyCode.Name] = nil
end

function InputController:IsTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

return InputController
