--[[
	Format
	Formateo de numeros compartido entre servidor y cliente.
	Esta en ReplicatedStorage para que la barra de nivel (cliente) use el mismo
	formato que los carteles de dinero (servidor).
]]

local Format = {}

-- 1000000 -> "1.000.000"
function Format.number(value: number): string
	local text = tostring(math.floor(value))
	local replacements

	repeat
		text, replacements = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1.%2")
	until replacements == 0

	return text
end

return Format
