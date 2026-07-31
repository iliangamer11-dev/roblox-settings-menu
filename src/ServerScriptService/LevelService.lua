--[[
	LevelService
	Nivel y experiencia de cada jugador. La experiencia son los puntos que se ganan
	al picar (por defecto 1 punto por cada moneda).

	El nivel y los puntos se publican como atributos del jugador:
		player:GetAttribute("level")
		player:GetAttribute("xp")        -- puntos dentro del nivel actual
		player:GetAttribute("xpNeeded")  -- puntos que pide el nivel actual

	Los atributos se replican solos al cliente, asi que la barra de nivel no necesita
	ningun RemoteEvent: solo escucha los cambios.

	Importante: los puntos se ganan al picar y no se gastan nunca, asi comprar paredes
	no baja el nivel. Con LEVEL.XP_FROM_BASE_VALUE los puntos salen del valor base del
	mineral, sin el multiplicador de zona, para que no se suba 50 veces mas rapido en
	Dulces que en Naturaleza.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))

local LevelService = {}

-- data[player] = { level = 1, xp = 0 }
local data = {}

-- restored[player] = true cuando SaveService ya le ha puesto su nivel guardado
local restored = {}

local function xpNeededFor(level: number): number
	local cfg = Config.LEVEL
	return math.max(1, math.floor(cfg.BASE_XP * cfg.GROWTH ^ (level - 1)))
end

-- Multiplicador de dinero que da el nivel actual
local function multiplierFor(level: number): number
	local cfg = Config.LEVEL
	local multiplier = 1 + (level - 1) * cfg.MULTIPLIER_PER_LEVEL

	if cfg.MAX_MULTIPLIER > 0 then
		multiplier = math.min(multiplier, cfg.MAX_MULTIPLIER)
	end

	-- Se redondea a dos decimales para que el texto de la barra quede limpio
	return math.floor(multiplier * 100 + 0.5) / 100
end

local function publish(player: Player)
	local entry = data[player]
	if not entry then
		return
	end

	player:SetAttribute("level", entry.level)
	player:SetAttribute("xp", math.floor(entry.xp))
	player:SetAttribute("xpNeeded", xpNeededFor(entry.level))
	-- Lo lee MiningService para el dinero y la barra de nivel para el texto verde
	player:SetAttribute("levelMultiplier", multiplierFor(entry.level))
end

function LevelService.setup(player: Player)
	-- Si SaveService ya restauro su nivel no se le pisa: el orden en que corren los
	-- scripts al entrar un jugador no esta garantizado
	if restored[player] then
		publish(player)
		return
	end

	data[player] = { level = 1, xp = 0 }
	publish(player)
end

-- Restaura el nivel guardado (lo llama SaveService al entrar el jugador)
function LevelService.load(player: Player, level: number?, xp: number?)
	local entry = data[player]
	if not entry then
		entry = { level = 1, xp = 0 }
		data[player] = entry
	end

	entry.level = math.max(1, math.floor(tonumber(level) or 1))
	entry.xp = math.max(0, tonumber(xp) or 0)
	restored[player] = true

	publish(player)
end

function LevelService.addXp(player: Player, value: number)
	local cfg = Config.LEVEL
	if not cfg.ENABLED then
		return
	end

	local entry = data[player]
	if not entry or value <= 0 then
		return
	end

	entry.xp += value * cfg.XP_PER_MONEY

	-- while, no if: un mineral bueno puede subir varios niveles de golpe
	local needed = xpNeededFor(entry.level)
	while entry.xp >= needed do
		if cfg.MAX_LEVEL > 0 and entry.level >= cfg.MAX_LEVEL then
			entry.xp = needed -- al maximo la barra se queda llena
			break
		end

		entry.xp -= needed
		entry.level += 1
		needed = xpNeededFor(entry.level)
	end

	publish(player)

	if Config.DEBUG then
		print(string.format("[Level] %s -> nivel %d (%d/%d)", player.Name, entry.level, math.floor(entry.xp), needed))
	end
end

function LevelService.clear(player: Player)
	data[player] = nil
	restored[player] = nil
end

return LevelService
