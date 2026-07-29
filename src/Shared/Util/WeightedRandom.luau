--!nonstrict
--[[
	WeightedRandom
	----------------------------------------------------------------------------
	Seleccion aleatoria con pesos. La usa el sistema de globos para repartir
	rarezas, y servira igual para mascotas, cajas de botin o eventos.

	La tabla acumulada se construye UNA vez y se reutiliza, asi que elegir es
	O(log n) por busqueda binaria en lugar de recorrer la lista en cada tirada.
	Con cientos de globos por minuto la diferencia se nota.

		local picker = WeightedRandom.new({
			{ Value = "Red", Weight = 100 },
			{ Value = "Golden", Weight = 2 },
		})
		print(picker:Pick())
--]]

local WeightedRandom = {}
WeightedRandom.__index = WeightedRandom

export type Entry = {
	Value: any,
	Weight: number,
}

--[[
	`entries` es un array de { Value, Weight }. Los pesos <= 0 se descartan.
--]]
function WeightedRandom.new(entries: { Entry }, seed: number?)
	local values = {}
	local cumulative = {}
	local total = 0

	for _, entry in ipairs(entries) do
		local weight = tonumber(entry.Weight) or 0
		if weight <= 0 then
			continue
		end
		total += weight
		table.insert(values, entry.Value)
		table.insert(cumulative, total)
	end

	return setmetatable({
		_values = values,
		_cumulative = cumulative,
		_total = total,
		_random = if seed then Random.new(seed) else Random.new(),
	}, WeightedRandom)
end

function WeightedRandom:IsEmpty(): boolean
	return self._total <= 0
end

function WeightedRandom:Count(): number
	return #self._values
end

--[[
	Devuelve un valor al azar respetando los pesos, o nil si no hay entradas.
--]]
function WeightedRandom:Pick(): any
	if self._total <= 0 then
		return nil
	end

	local roll = self._random:NextNumber() * self._total
	local cumulative = self._cumulative

	-- Busqueda binaria del primer acumulado >= roll
	local low, high = 1, #cumulative
	while low < high do
		local mid = (low + high) // 2
		if cumulative[mid] < roll then
			low = mid + 1
		else
			high = mid
		end
	end

	return self._values[low]
end

--[[
	Probabilidad real de cada valor, util para mostrarla en la interfaz.
--]]
function WeightedRandom:GetChances(): { [any]: number }
	local chances = {}
	if self._total <= 0 then
		return chances
	end

	local previous = 0
	for index, value in ipairs(self._values) do
		local weight = self._cumulative[index] - previous
		previous = self._cumulative[index]
		chances[value] = weight / self._total
	end

	return chances
end

return WeightedRandom
