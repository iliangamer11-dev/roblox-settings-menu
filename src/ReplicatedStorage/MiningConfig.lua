--[[
	MiningConfig
	Configuracion compartida (cliente + servidor) del sistema de mineria.
	Aqui se ajustan las recompensas, el alcance y la animacion del picazo.
]]

local MiningConfig = {}

-- Nombre de la variable de dinero (aparece en leaderstats como "money")
MiningConfig.MONEY_NAME = "money"
MiningConfig.STARTING_MONEY = 0

-- Nombre de la herramienta
MiningConfig.TOOL_NAME = "Pickaxe"

-- Nombre del RemoteEvent que crea el servidor en ReplicatedStorage
MiningConfig.REMOTE_NAME = "PickaxeSwing"

-- Dinero que suma cada picazo segun la zona (nombre exacto de la Part)
MiningConfig.REWARDS = {
	Naturaleza = 1,
	Desierto = 5,
	Mina = 10,
	Luna = 25,
	Dulces = 50,
}

-- Color de las chispas del picazo por zona (opcional)
MiningConfig.ZONE_COLORS = {
	Naturaleza = Color3.fromRGB(88, 200, 96),
	Desierto = Color3.fromRGB(235, 200, 120),
	Mina = Color3.fromRGB(170, 170, 175),
	Luna = Color3.fromRGB(150, 170, 230),
	Dulces = Color3.fromRGB(245, 120, 190),
}

-- Tiempo minimo entre picazos (segundos)
MiningConfig.SWING_COOLDOWN = 0.55

-- Distancia maxima a la que se puede picar una zona (studs)
MiningConfig.MAX_REACH = 18

-- Cuanto se busca hacia abajo para saber sobre que zona esta parado el jugador
MiningConfig.GROUND_CHECK_DISTANCE = 12

-- Duraciones de la animacion procedural del picazo (segundos)
MiningConfig.SWING_UP_TIME = 0.12
MiningConfig.SWING_DOWN_TIME = 0.07
MiningConfig.SWING_HOLD_TIME = 0.05
MiningConfig.SWING_RETURN_TIME = 0.16

-- Si subes tu propia animacion a Roblox, pon el id aqui (ej: "rbxassetid://123456789").
-- Si lo dejas vacio se usa la animacion procedural del mango (funciona sin subir nada).
MiningConfig.ANIMATION_ID = ""

-- Sonido opcional del golpe (ej: "rbxassetid://123456789"). Vacio = sin sonido.
MiningConfig.HIT_SOUND_ID = ""

return MiningConfig
