--!nonstrict
--[[
	Net
	----------------------------------------------------------------------------
	Capa unica de acceso a los remotes. Ventajas frente a usar
	ReplicatedStorage.Remotes.X directamente:

		* Valida contra RemoteDefinitions -> un typo es un error inmediato.
		* Aplica rate limit automatico a lo que llega del cliente.
		* Envuelve los handlers en pcall para que un error del cliente no
		  rompa el servicio.
		* Misma API en cliente y servidor.

	SERVIDOR
		Net.OnEvent("RequestPopBalloon", function(player, balloonId) end)
		Net.OnInvoke("RequestUpgradeTool", function(player, toolId, upgradeId)
			return true
		end)
		Net.FireClient("Notify", player, "Hola")
		Net.FireAllClients("BalloonSpawned", data)

	CLIENTE
		Net.Fire("RequestPopBalloon", balloonId)
		local ok = Net.Invoke("RequestUpgradeTool", "Cuchillo", "Power")
		Net.OnClientEvent("BalloonPopped", function(data) end)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Definitions = require(script.Parent.RemoteDefinitions)
local Logger = require(script.Parent.Parent.Util.Logger)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)

local IS_SERVER = RunService:IsServer()
local log = Logger.new("Net")

local Net = {}

local cache: { [string]: Instance } = {}
local limiters: { [string]: any } = {}

--------------------------------------------------------------------------------
-- Interno
--------------------------------------------------------------------------------

local function getDefinition(name: string)
	local definition = Definitions.Definitions[name]
	if not definition then
		error(string.format("[Net] Remote '%s' no existe en RemoteDefinitions", name), 3)
	end
	return definition
end

local function getRemotesFolder(): Instance
	local folder = cache["__root"]
	if folder then
		return folder
	end

	if IS_SERVER then
		folder = ReplicatedStorage:FindFirstChild(Definitions.FolderName)
		if not folder then
			error("[Net] La carpeta de remotes no existe. RemoteBuilder.Build() debe ejecutarse primero.", 3)
		end
	else
		folder = ReplicatedStorage:WaitForChild(Definitions.FolderName, 30)
		if not folder then
			error("[Net] Timeout esperando la carpeta de remotes del servidor", 3)
		end
	end

	cache["__root"] = folder
	return folder
end

local function getRemote(name: string, expectedKind: string): any
	local cached = cache[name]
	if cached then
		return cached
	end

	local definition = getDefinition(name)
	if definition.Kind ~= expectedKind then
		error(string.format("[Net] '%s' es %s, no %s", name, definition.Kind, expectedKind), 3)
	end

	local root = getRemotesFolder()
	local subFolderName = if definition.Kind == "RemoteEvent"
		then Definitions.EventsFolderName
		else Definitions.FunctionsFolderName

	local subFolder = if IS_SERVER
		then root:FindFirstChild(subFolderName)
		else root:WaitForChild(subFolderName, 30)
	assert(subFolder, string.format("[Net] Carpeta '%s' no encontrada", subFolderName))

	local remote = if IS_SERVER then subFolder:FindFirstChild(name) else subFolder:WaitForChild(name, 30)
	assert(remote, string.format("[Net] Remote '%s' no encontrado", name))

	cache[name] = remote
	return remote
end

local function getLimiter(name: string, definition: any)
	if not definition.RateLimit then
		return nil
	end
	local limiter = limiters[name]
	if not limiter then
		limiter = RateLimiter.new(definition.RateLimit, 1)
		limiters[name] = limiter
	end
	return limiter
end

--------------------------------------------------------------------------------
-- API comun
--------------------------------------------------------------------------------

function Net.GetEvent(name: string): RemoteEvent
	return getRemote(name, "RemoteEvent")
end

function Net.GetFunction(name: string): RemoteFunction
	return getRemote(name, "RemoteFunction")
end

--------------------------------------------------------------------------------
-- API del servidor
--------------------------------------------------------------------------------

--[[
	Escucha un evento enviado por el cliente. El callback recibe (player, ...).
--]]
function Net.OnEvent(name: string, callback: (Player, ...any) -> ())
	assert(IS_SERVER, "Net.OnEvent solo se puede usar en el servidor")
	local definition = getDefinition(name)
	local limiter = getLimiter(name, definition)

	return Net.GetEvent(name).OnServerEvent:Connect(function(player: Player, ...)
		if limiter and not limiter:Check(player) then
			log:Warn("Rate limit superado en '%s' por %s", name, player.Name)
			return
		end

		local ok, err = pcall(callback, player, ...)
		if not ok then
			log:Error("Handler de '%s' fallo: %s", name, tostring(err))
		end
	end)
end

--[[
	Define el handler de un RemoteFunction. Si el callback falla, se devuelve
	nil al cliente en lugar de propagar el error.
--]]
function Net.OnInvoke(name: string, callback: (Player, ...any) -> ...any)
	assert(IS_SERVER, "Net.OnInvoke solo se puede usar en el servidor")
	local definition = getDefinition(name)
	local limiter = getLimiter(name, definition)
	local remote = Net.GetFunction(name)

	remote.OnServerInvoke = function(player: Player, ...)
		if limiter and not limiter:Check(player) then
			log:Warn("Rate limit superado en '%s' por %s", name, player.Name)
			return nil
		end

		local results = table.pack(pcall(callback, player, ...))
		if not results[1] then
			log:Error("Handler de '%s' fallo: %s", name, tostring(results[2]))
			return nil
		end
		return table.unpack(results, 2, results.n)
	end
end

function Net.FireClient(name: string, player: Player, ...)
	assert(IS_SERVER, "Net.FireClient solo se puede usar en el servidor")
	Net.GetEvent(name):FireClient(player, ...)
end

function Net.FireAllClients(name: string, ...)
	assert(IS_SERVER, "Net.FireAllClients solo se puede usar en el servidor")
	Net.GetEvent(name):FireAllClients(...)
end

function Net.FireClients(name: string, players: { Player }, ...)
	assert(IS_SERVER, "Net.FireClients solo se puede usar en el servidor")
	local remote = Net.GetEvent(name)
	for _, player in ipairs(players) do
		remote:FireClient(player, ...)
	end
end

--[[
	Libera el estado de rate limit de un jugador que se desconecta.
--]]
function Net.ClearPlayer(player: Player)
	for _, limiter in pairs(limiters) do
		limiter:Reset(player)
	end
end

--------------------------------------------------------------------------------
-- API del cliente
--------------------------------------------------------------------------------

function Net.Fire(name: string, ...)
	assert(not IS_SERVER, "Net.Fire solo se puede usar en el cliente")
	Net.GetEvent(name):FireServer(...)
end

function Net.Invoke(name: string, ...): ...any
	assert(not IS_SERVER, "Net.Invoke solo se puede usar en el cliente")
	return Net.GetFunction(name):InvokeServer(...)
end

function Net.OnClientEvent(name: string, callback: (...any) -> ())
	assert(not IS_SERVER, "Net.OnClientEvent solo se puede usar en el cliente")
	return Net.GetEvent(name).OnClientEvent:Connect(function(...)
		local ok, err = pcall(callback, ...)
		if not ok then
			log:Error("Handler de '%s' fallo: %s", name, tostring(err))
		end
	end)
end

return Net
