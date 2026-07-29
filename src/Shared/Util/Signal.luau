--!nonstrict
--[[
	Signal
	----------------------------------------------------------------------------
	Evento ligero en Luau puro (sin BindableEvent) para comunicacion interna
	entre modulos del mismo entorno. No cruza la frontera cliente/servidor:
	para eso se usa Shared/Network/Net.

		local signal = Signal.new()
		local conn = signal:Connect(function(a, b) end)
		signal:Fire(1, 2)
		conn:Disconnect()
--]]

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, callback)
	return setmetatable({
		_signal = signal,
		_callback = callback,
		Connected = true,
	}, Connection)
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false

	local connections = self._signal._connections
	local index = table.find(connections, self)
	if index then
		table.remove(connections, index)
	end
end

Connection.Destroy = Connection.Disconnect

local Signal = {}
Signal.__index = Signal

export type Signal = typeof(setmetatable({} :: {
	_connections: { any },
}, Signal))

function Signal.new(): Signal
	return setmetatable({
		_connections = {},
	}, Signal)
end

function Signal:Connect(callback: (...any) -> ())
	assert(type(callback) == "function", "Signal:Connect espera una funcion")
	local connection = Connection.new(self, callback)
	table.insert(self._connections, connection)
	return connection
end

function Signal:Once(callback: (...any) -> ())
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal:Fire(...)
	-- Se itera sobre una copia para tolerar desconexiones durante el disparo
	local snapshot = table.clone(self._connections)
	for _, connection in ipairs(snapshot) do
		if connection.Connected then
			task.spawn(connection._callback, ...)
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	for _, connection in ipairs(table.clone(self._connections)) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

function Signal:Destroy()
	self:DisconnectAll()
end

return Signal
