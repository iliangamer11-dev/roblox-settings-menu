--[[
	SaveService (Script en ServerScriptService)

	Guarda y restaura el progreso con DataStore:
		dinero, nivel y puntos, paredes compradas, tag equipado y skin equipada.

	Los gamepasses NO se guardan a proposito: Roblox ya sabe quien los tiene y Passes los
	consulta al entrar. Guardarlos seria duplicar el dato y podria desincronizarse si
	alguien pide un reembolso.

	Cuando guarda:
		- cada AUTOSAVE_INTERVAL segundos mira si el jugador ha cambiado algo, y si ha
		  cambiado, lo guarda al momento
		- al salir el jugador (PlayerRemoving)
		- al cerrarse el servidor (BindToClose), que es el caso que mas se olvida

	Solo guarda si hay algo distinto. Roblox limita las escrituras a una cada 6 segundos
	por clave y a 60 + 10*jugadores por minuto en total; guardar a lo loco cada 3 segundos
	hace que Roblox empiece a rechazarlas y entonces se pierde progreso de verdad. Por eso
	se compara el estado con el ultimo guardado y se respeta MIN_SAVE_INTERVAL.

	Proteccion importante: si el jugador se va ANTES de que termine de cargar, no se
	guarda nada. Si no, se le sobreescribiria su progreso con datos vacios.

	Ajustes en MiningConfig.SAVE.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local LevelService = require(script.Parent:WaitForChild("LevelService"))

local cfg = Config.SAVE

if not cfg.ENABLED then
	return
end

--------------------------------------------------------------------------------
-- DataStore
--------------------------------------------------------------------------------

-- GetDataStore falla si no hay acceso a la API (Studio con API Services desactivado)
local store
local storeOk, storeError = pcall(function()
	store = DataStoreService:GetDataStore(cfg.STORE_NAME)
end)

if not storeOk or not store then
	warn(
		"[SaveService] No hay DataStore disponible, el progreso NO se guardara. "
			.. "En Studio: Game Settings > Security > Enable Studio Access to API Services. "
			.. tostring(storeError)
	)
	return
end

local function keyFor(player: Player): string
	return cfg.KEY_PREFIX .. player.UserId
end

-- Reintenta unas cuantas veces: los DataStore fallan de vez en cuando y perder el
-- progreso por un fallo puntual no es aceptable
local function attempt(action: () -> any): (boolean, any)
	local lastError

	for tries = 1, cfg.RETRIES do
		local ok, result = pcall(action)
		if ok then
			return true, result
		end

		lastError = result
		if tries < cfg.RETRIES then
			task.wait(cfg.RETRY_DELAY)
		end
	end

	return false, lastError
end

--------------------------------------------------------------------------------
-- Estado
--------------------------------------------------------------------------------

-- loaded[player] = true cuando ya se le ha aplicado su progreso.
-- Hasta entonces no se guarda, para no machacar datos buenos con datos vacios.
local loaded = {}

-- Firma del ultimo estado guardado. Si la firma no ha cambiado, no hay nada que guardar.
local lastSignature = {}

-- Momento (os.clock) del ultimo guardado, para respetar el limite de Roblox
local lastSaveAt = {}

-- Para que dos guardados del mismo jugador no se pisen
local saving = {}

local function moneyValue(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local value = leaderstats and leaderstats:FindFirstChild(Config.MONEY_NAME)
	return (value and value:IsA("IntValue")) and value or nil
end

-- Lo que se guarda
local function collect(player: Player)
	local walls = {}
	for _, wall in Config.WALLS do
		if player:GetAttribute("owns" .. wall.NAME) == true then
			walls[wall.NAME] = true
		end
	end

	local money = moneyValue(player)

	return {
		money = money and money.Value or 0,
		level = player:GetAttribute("level") or 1,
		xp = player:GetAttribute("xp") or 0,
		walls = walls,
		tag = player:GetAttribute("tag"),
		skin = player:GetAttribute("skin"),
	}
end

-- Texto corto que representa el estado. Si sale igual que el del ultimo guardado,
-- el jugador no ha cambiado nada y no hace falta gastar una escritura.
local function signatureOf(data): string
	local wallNames = {}
	for wallName in data.walls do
		table.insert(wallNames, wallName)
	end
	table.sort(wallNames) -- el orden de una tabla no es fijo, hay que ordenarlo

	return table.concat({
		tostring(data.money),
		tostring(data.level),
		tostring(math.floor(tonumber(data.xp) or 0)),
		table.concat(wallNames, "+"),
		tostring(data.tag),
		tostring(data.skin),
	}, "|")
end

-- Y como se restaura
local function apply(player: Player, data)
	-- 1) Las paredes primero: de ellas dependen los tags y las skins desbloqueadas
	if type(data.walls) == "table" then
		for wallName, owns in data.walls do
			if owns == true then
				player:SetAttribute("owns" .. wallName, true)
			end
		end
	end

	-- 2) Dinero. La IntValue la crea MiningService, asi que puede tardar un instante
	local money = moneyValue(player)
	if not money then
		local leaderstats = player:WaitForChild("leaderstats", 10)
		money = leaderstats and leaderstats:WaitForChild(Config.MONEY_NAME, 10) or nil
	end

	if money and money:IsA("IntValue") then
		money.Value = tonumber(data.money) or 0
	end

	-- 3) Nivel y puntos
	LevelService.load(player, data.level, data.xp)

	-- 4) Tag y skin equipados. Tags y Skins validan que esten desbloqueados, y si no,
	-- los dejan en el de por defecto.
	if type(data.tag) == "string" then
		player:SetAttribute("tag", data.tag)
	end
	if type(data.skin) == "string" then
		player:SetAttribute("skin", data.skin)
	end
end

--------------------------------------------------------------------------------
-- Cargar y guardar
--------------------------------------------------------------------------------

local function load(player: Player)
	local ok, data = attempt(function()
		return store:GetAsync(keyFor(player))
	end)

	if not ok then
		-- No se marca como cargado: asi no se le guarda encima y no pierde nada
		warn(string.format("[SaveService] No se pudo cargar el progreso de %s: %s", player.Name, tostring(data)))
		return
	end

	if type(data) == "table" then
		apply(player, data)

		if Config.DEBUG then
			print(
				string.format(
					"[SaveService] %s cargado: %s money, nivel %s",
					player.Name,
					tostring(data.money),
					tostring(data.level)
				)
			)
		end
	elseif Config.DEBUG then
		print(string.format("[SaveService] %s es nuevo, empieza de cero", player.Name))
	end

	loaded[player] = true

	-- Se guarda la firma de lo que acaba de cargar: asi el autoguardado no reescribe
	-- lo mismo que ya estaba guardado
	lastSignature[player] = signatureOf(collect(player))
end

local function save(player: Player): boolean
	if not loaded[player] then
		return false -- todavia no habia cargado: no se toca lo que hay guardado
	end

	if saving[player] then
		return false -- ya hay un guardado suyo en marcha
	end

	local data = collect(player)
	local signature = signatureOf(data)

	if signature == lastSignature[player] then
		return false -- no ha cambiado nada, no se gasta escritura
	end

	saving[player] = true

	-- UpdateAsync en vez de SetAsync: respeta lo que haya si dos servidores coinciden
	local ok, err = attempt(function()
		return store:UpdateAsync(keyFor(player), function()
			return data
		end)
	end)

	saving[player] = false
	lastSaveAt[player] = os.clock()

	if not ok then
		warn(string.format("[SaveService] No se pudo guardar el progreso de %s: %s", player.Name, tostring(err)))
		return false
	end

	lastSignature[player] = signature

	if Config.DEBUG then
		print(string.format("[SaveService] %s guardado: %s money, nivel %s", player.Name, data.money, data.level))
	end

	return true
end

-- Guardado que no se puede perder (al salir y al cerrar el servidor). Si justo habia un
-- autoguardado suyo en marcha, se espera a que acabe y se vuelve a intentar, porque ese
-- que estaba en marcha no incluye lo ultimo que hizo el jugador.
local function saveNow(player: Player)
	local timeout = os.clock() + 5
	while saving[player] and os.clock() < timeout do
		task.wait(0.1)
	end

	save(player)
end

--------------------------------------------------------------------------------
-- Jugadores
--------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	task.spawn(load, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	saveNow(player)

	loaded[player] = nil
	lastSignature[player] = nil
	lastSaveAt[player] = nil
	saving[player] = nil
end)

-- Autoguardado: cada AUTOSAVE_INTERVAL segundos se mira quien ha cambiado algo y se le
-- guarda al momento. Si el servidor se cae de golpe, se pierde como mucho eso.
task.spawn(function()
	while true do
		task.wait(cfg.AUTOSAVE_INTERVAL)

		local now = os.clock()

		for _, player in Players:GetPlayers() do
			-- Roblox solo acepta una escritura cada 6 segundos por clave: si se le acaba
			-- de guardar, se espera al siguiente repaso
			local elapsed = now - (lastSaveAt[player] or 0)

			if not saving[player] and elapsed >= cfg.MIN_SAVE_INTERVAL then
				task.spawn(save, player)
			end
		end
	end
end)

-- Al cerrar el servidor. Roblox da unos segundos aqui, y hay que esperar a que terminen
-- todos los guardados o se pierden.
game:BindToClose(function()
	if RunService:IsStudio() then
		return -- en Studio no hace falta y ademas ralentiza el parar la prueba
	end

	local pending = 0

	for _, player in Players:GetPlayers() do
		pending += 1
		task.spawn(function()
			saveNow(player)
			pending -= 1
		end)
	end

	local timeout = os.clock() + 20
	while pending > 0 and os.clock() < timeout do
		task.wait(0.1)
	end
end)
