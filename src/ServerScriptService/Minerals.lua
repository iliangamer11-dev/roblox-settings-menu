--[[
	Minerals
	Sorteo del mineral que sale en cada picazo, segun las probabilidades de
	MiningConfig.MINERALS.

	El sorteo se hace SIEMPRE en el servidor: el cliente no elige nada.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))

local Minerals = {}

local random = Random.new()

-- Peso total real, asi las probabilidades no tienen que sumar 100 exacto
local totalChance = 0
for _, mineral in Config.MINERALS do
	totalChance += mineral.CHANCE
end

if totalChance <= 0 then
	error("[Minerals] Las probabilidades de MiningConfig.MINERALS suman 0")
end

-- Devuelve la entrada de MiningConfig.MINERALS que ha salido
function Minerals.roll()
	local roll = random:NextNumber(0, totalChance)
	local accumulated = 0

	for _, mineral in Config.MINERALS do
		accumulated += mineral.CHANCE
		if roll <= accumulated then
			return mineral
		end
	end

	-- Por si acaso (redondeos)
	return Config.MINERALS[#Config.MINERALS]
end

-- Dinero final = base del mineral * multiplicador de la zona
function Minerals.getReward(mineral, zoneName: string): number
	local multiplier = Config.ZONE_MULTIPLIERS[zoneName] or 1
	return math.floor(mineral.MONEY * multiplier)
end

-- "1000000" -> "1.000.000"
function Minerals.format(value: number): string
	local text = tostring(math.floor(value))
	local replacements

	repeat
		text, replacements = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1.%2")
	until replacements == 0

	return text
end

return Minerals
