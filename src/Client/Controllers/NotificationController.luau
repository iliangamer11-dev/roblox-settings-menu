--!nonstrict
--[[
	NotificationController
	----------------------------------------------------------------------------
	Cola de avisos en pantalla. El servidor envia texto con Net "Notify" y
	cualquier controlador local puede llamar a Push directamente.

	PREPARADO PARA: feedback de compras, subidas de nivel, misiones y
	desbloqueo de zonas.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared.Util.Logger)
local Net = require(Shared.Network.Net)
local Signal = require(Shared.Util.Signal)

local log = Logger.new("NotificationController")

local NotificationController = {}
NotificationController.Name = "NotificationController"
NotificationController.Priority = 300

local MAX_QUEUE = 5

function NotificationController:Init()
	self._queue = {}
	self.NotificationAdded = Signal.new()
end

function NotificationController:Start()
	Net.OnClientEvent("Notify", function(message, kind)
		self:Push(message, kind)
	end)

	Net.OnClientEvent("PurchaseResult", function(shopId, itemId, success)
		self:Push(
			if success then "Compra realizada" else "No se pudo completar la compra",
			if success then "Success" else "Error"
		)
	end)

	Net.OnClientEvent("LevelChanged", function(newLevel)
		self:Push(string.format("Has subido al nivel %d", newLevel), "Success")
	end)
end

--[[
	kind: "Info" | "Success" | "Warning" | "Error"
	TODO: sustituir la traza por la animacion real de la interfaz.
--]]
function NotificationController:Push(message: string, kind: string?)
	if type(message) ~= "string" then
		return
	end

	local entry = { Message = message, Kind = kind or "Info", At = os.clock() }

	table.insert(self._queue, entry)
	if #self._queue > MAX_QUEUE then
		table.remove(self._queue, 1)
	end

	self.NotificationAdded:Fire(entry)
	log:Debug("[%s] %s", entry.Kind, entry.Message)
end

function NotificationController:GetQueue()
	return table.clone(self._queue)
end

return NotificationController
