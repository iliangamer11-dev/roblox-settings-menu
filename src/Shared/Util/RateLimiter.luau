--!nonstrict
--[[
	RateLimiter
	Limitador de llamadas por jugador. Se usa en Net para proteger los
	RemoteEvents/RemoteFunctions de spam del cliente.

		local limiter = RateLimiter.new(10, 1) -- 10 llamadas por segundo
		if not limiter:Check(player) then return end
--]]

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(maxCalls: number, window: number?)
	return setmetatable({
		_max = maxCalls,
		_window = window or 1,
		_buckets = {},
	}, RateLimiter)
end

--[[
	Devuelve true si la llamada esta permitida y la contabiliza.
--]]
function RateLimiter:Check(key: any): boolean
	local now = os.clock()
	local bucket = self._buckets[key]

	if not bucket or now - bucket.startedAt >= self._window then
		self._buckets[key] = { startedAt = now, count = 1 }
		return true
	end

	if bucket.count >= self._max then
		return false
	end

	bucket.count += 1
	return true
end

--[[
	Limpia el registro de una clave (llamar cuando el jugador se va).
--]]
function RateLimiter:Reset(key: any)
	self._buckets[key] = nil
end

function RateLimiter:Destroy()
	table.clear(self._buckets)
end

return RateLimiter
