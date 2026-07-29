--!nonstrict
--[[
	ToolController
	----------------------------------------------------------------------------
	ESQUELETO. Lado cliente de la Tool "Cuchillo".

	PREPARADO PARA: Tool Cuchillo + sistema de pinchar globos.

	Responsabilidades previstas:
		* Detectar la activacion de la Tool (clic / toque).
		* Reproducir la animacion y el sonido del golpe de forma inmediata
		  (feedback local, sin esperar al servidor).
		* Enviar RequestPopBalloon con el globo apuntado.
		* Respetar el cooldown local para no hacer spam de remotes; el
		  servidor vuelve a validarlo de todos modos.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)

local ClientState = require(script.Parent.Parent.State.ClientState)

local log = Logger.new("ToolController")

local ToolController = {}
ToolController.Name = "ToolController"
ToolController.Priority = 400

function ToolController:Init()
	self._player = Players.LocalPlayer
	self._equipped = nil
	self._lastUse = 0
end

function ToolController:Start()
	self._player.CharacterAdded:Connect(function(character)
		self:_watchCharacter(character)
	end)

	if self._player.Character then
		self:_watchCharacter(self._player.Character)
	end

	Net.OnClientEvent("ToolUpdated", function(toolId, ownedTool)
		log:Debug("Herramienta actualizada: %s", tostring(toolId))
	end)

	Net.OnClientEvent("BalloonPopped", function(payload)
		self:_onBalloonPopped(payload)
	end)
end

--[[
	Detecta cuando el jugador equipa una herramienta del catalogo.
--]]
function ToolController:_watchCharacter(character: Model)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and Config.Tools.Tools[child.Name] then
			self:_bindTool(child)
		end
	end)

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and Config.Tools.Tools[child.Name] then
			self:_bindTool(child)
		end
	end
end

function ToolController:_bindTool(tool: Tool)
	self._equipped = tool

	tool.Activated:Connect(function()
		self:_onActivated(tool)
	end)

	tool.Unequipped:Connect(function()
		if self._equipped == tool then
			self._equipped = nil
		end
	end)

	log:Debug("Tool '%s' enlazada", tool.Name)
end

--[[
	TODO: apuntar al globo (raycast desde la camara o deteccion por contacto)
	y enviar la peticion al servidor.
--]]
function ToolController:_onActivated(tool: Tool)
	local definition = Config.Tools.Tools[tool.Name]
	if not definition then
		return
	end

	-- Cooldown local basado en la configuracion base de la herramienta.
	-- Cuando exista el sistema de mejoras se leera del perfil replicado.
	local now = os.clock()
	if now - self._lastUse < definition.Base.Cooldown then
		return
	end
	self._lastUse = now

	log:Debug("Uso de '%s' (pinchado sin implementar)", tool.Name)
	-- Net.Fire("RequestPopBalloon", balloonId)
end

--[[
	TODO: efectos de particulas, sonido y numeros flotantes.
--]]
function ToolController:_onBalloonPopped(payload: any)
	if not ClientState.IsReady then
		return
	end
end

return ToolController
