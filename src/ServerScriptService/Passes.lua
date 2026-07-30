--[[
	Passes
	Quien tiene cada gamepass y que efecto le toca.

	Todo se comprueba en el SERVIDOR (UserOwnsGamePassAsync). El cliente nunca decide
	si tiene un pase, solo recibe el resultado en atributos para la interfaz.

	Ids en MiningConfig.PASSES y efectos en MiningConfig.PASS_EFFECTS.

	Atributos que publica en el jugador:
		swingCooldown -> el cooldown real, para que el cliente no frene los golpes
		vip           -> true si tiene VIP (lo usa la placa del personaje)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))

local Passes = {}

-- Avisa cuando cambia algo (al entrar o al comprar): lo escuchan MiningService y WallShop
Passes.Changed = Instance.new("BindableEvent")

local effects = Config.PASS_EFFECTS

-- owned[player] = { X2_MONEY = true, ... }
local owned = {}

--------------------------------------------------------------------------------
-- Consultas
--------------------------------------------------------------------------------

function Passes.has(player: Player, key: string): boolean
	local set = owned[player]
	if not set then
		return false
	end

	if set[key] then
		return true
	end

	-- VIP incluye otros pases
	if set.VIP then
		for _, included in effects.VIP_INCLUDES do
			if included == key then
				return true
			end
		end
	end

	return false
end

function Passes.moneyMultiplier(player: Player): number
	return Passes.has(player, "X2_MONEY") and effects.MONEY_MULTIPLIER or 1
end

-- Cooldown real entre picazos, ya con Fast Pickaxe aplicado
function Passes.cooldown(player: Player): number
	local multiplier = Passes.has(player, "FAST_PICKAXE") and effects.COOLDOWN_MULTIPLIER or 1
	return Config.SWING_COOLDOWN * multiplier
end

function Passes.luck(player: Player): number
	return Passes.has(player, "LUCKY_ORES") and effects.LUCK_MULTIPLIER or 1
end

function Passes.autoSwing(player: Player): boolean
	return effects.AUTO_SWING and Passes.has(player, "AUTO_SWING")
end

--------------------------------------------------------------------------------
-- Carga
--------------------------------------------------------------------------------

local function publish(player: Player)
	player:SetAttribute("swingCooldown", Passes.cooldown(player))
	player:SetAttribute("vip", Passes.has(player, "VIP"))
	-- Lo usa el boton de Auto Swing para saber si debe salir en pantalla
	player:SetAttribute("autoSwing", Passes.autoSwing(player))
	Passes.Changed:Fire(player)
end

function Passes.setup(player: Player)
	owned[player] = {}
	publish(player)

	-- Una consulta por pase, cada una en su hilo: son llamadas web y pueden tardar
	for key, id in Config.PASSES do
		if typeof(id) == "number" and id > 0 then
			task.spawn(function()
				local ok, result = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
				end)

				if not ok then
					warn(string.format("[Passes] No se pudo comprobar %s (%d) de %s", key, id, player.Name))
					return
				end

				local set = owned[player]
				if not set or not result then
					return
				end

				set[key] = true
				publish(player)

				if Config.DEBUG then
					print(string.format("[Passes] %s tiene %s", player.Name, key))
				end
			end)
		end
	end
end

function Passes.clear(player: Player)
	owned[player] = nil
end

-- Compra en caliente: se aplica al momento, sin tener que reconectarse
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased then
		return
	end

	local set = owned[player]
	if not set then
		return
	end

	for key, id in Config.PASSES do
		if id == passId then
			set[key] = true
			publish(player)

			if Config.DEBUG then
				print(string.format("[Passes] %s acaba de comprar %s", player.Name, key))
			end
		end
	end
end)

Players.PlayerRemoving:Connect(Passes.clear)

return Passes
