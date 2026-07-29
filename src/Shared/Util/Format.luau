--!strict
--[[
	Format
	Formateo de numeros y tiempos para la interfaz. Compartido para que
	servidor y cliente muestren siempre los mismos valores.
--]]

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

--[[
	1250 -> "1.25K"
--]]
function Format.Abbreviate(value: number, decimals: number?): string
	local places = decimals or 2
	local negative = value < 0
	local absolute = math.abs(value)

	if absolute < 1000 then
		local text = string.format("%d", absolute)
		return if negative then "-" .. text else text
	end

	local index = math.floor(math.log(absolute, 1000))
	index = math.clamp(index, 1, #SUFFIXES - 1)

	local scaled = absolute / (1000 ^ index)
	local text = string.format("%." .. places .. "f", scaled)

	-- Quita ceros y punto sobrantes: "1.50" -> "1.5", "2.00" -> "2"
	text = string.gsub(text, "%.?0+$", "")

	local result = text .. SUFFIXES[index + 1]
	return if negative then "-" .. result else result
end

--[[
	1250000 -> "1,250,000"
--]]
function Format.Comma(value: number): string
	local text = string.format("%d", math.floor(value))
	local formatted = text
	while true do
		local replaced: number
		formatted, replaced = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then
			break
		end
	end
	return formatted
end

--[[
	3725 -> "01:02:05"
--]]
function Format.Time(seconds: number): string
	local total = math.max(math.floor(seconds), 0)
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	local secs = total % 60

	if hours > 0 then
		return string.format("%02d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%02d:%02d", minutes, secs)
end

--[[
	2.5 -> "x2.5"
--]]
function Format.Multiplier(value: number): string
	local text = string.format("%.2f", value)
	text = string.gsub(text, "%.?0+$", "")
	return "x" .. text
end

return Format
