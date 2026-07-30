--[[
	Minerals
	Sorteo del mineral que sale en cada picazo, segun las probabilidades de
	MiningConfig.MINERALS.

	El sorteo se hace SIEMPRE en el servidor: el cliente no elige nada.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local Format = require(ReplicatedStorage:WaitForChild("Format"))

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

-- luck multiplica el peso de los minerales marcados como RARE (gamepass Lucky Ores).
-- Los comunes mantienen su peso, asi que su porcentaje baja solo al crecer el total.
local function weightOf(mineral, luck: number): number
	if luck > 1 and mineral.RARE then
		return mineral.CHANCE * luck
	end
	return mineral.CHANCE
end

-- Devuelve la entrada de MiningConfig.MINERALS que ha salido
function Minerals.roll(luck: number?)
	local luckMultiplier = luck or 1

	local total = totalChance
	if luckMultiplier > 1 then
		total = 0
		for _, mineral in Config.MINERALS do
			total += weightOf(mineral, luckMultiplier)
		end
	end

	local roll = random:NextNumber(0, total)
	local accumulated = 0

	for _, mineral in Config.MINERALS do
		accumulated += weightOf(mineral, luckMultiplier)
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

-- "1000000" -> "1.000.000" (mismo formato que usa la barra de nivel)
function Minerals.format(value: number): string
	return Format.number(value)
end

return Minerals
