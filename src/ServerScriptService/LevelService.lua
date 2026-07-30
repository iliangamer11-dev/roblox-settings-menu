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

local function xpNeededFor(level: number): number
	local cfg = Config.LEVEL
	return math.max(1, math.floor(cfg.BASE_XP * cfg.GROWTH ^ (level - 1)))
end

local function publish(player: Player)
	local entry = data[player]
	if not entry then
		return
	end

	player:SetAttribute("level", entry.level)
	player:SetAttribute("xp", math.floor(entry.xp))
	player:SetAttribute("xpNeeded", xpNeededFor(entry.level))
end

function LevelService.setup(player: Player)
	data[player] = { level = 1, xp = 0 }
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
end

return LevelService
