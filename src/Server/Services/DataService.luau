--!nonstrict
--[[
	DataService
	----------------------------------------------------------------------------
	Dueno de la persistencia. Ningun otro servicio toca el DataStore: todos
	piden el perfil aqui y lo modifican en memoria.

	Incluye:
		* Carga con reconciliacion contra ProfileTemplate y migraciones.
		* Bloqueo de sesion (evita perdidas de datos entre servidores).
		* Autoguardado periodico y guardado al salir / al cerrar el servidor.
		* Senales para que otros servicios reaccionen a la carga/descarga.

	API
		DataService:GetProfile(player)          -> perfil o nil
		DataService:WaitForProfile(player, t?)  -> perfil o nil
		DataService:IsLoaded(player)            -> boolean
		DataService:MarkDirty(player)           marca cambios pendientes
		DataService:Save(player)                guardado inmediato
		DataService.ProfileLoaded               Signal(player, profile)
		DataService.ProfileReleased             Signal(player, profile)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Util.Logger)
local Signal = require(Shared.Util.Signal)
local Migrations = require(Shared.Data.Migrations)
local ProfileTemplate = require(Shared.Data.ProfileTemplate)

local DataStoreWrapper = require(script.Parent.Parent.Data.DataStoreWrapper)

local log = Logger.new("DataService")

local DataService = {}
DataService.Name = "DataService"
-- Prioridad maxima: el resto de servicios dependen de los perfiles.
DataService.Priority = 1000

local LOCK = Config.Data.SessionLock

--------------------------------------------------------------------------------
-- Ciclo de vida
--------------------------------------------------------------------------------

function DataService:Init()
	self._store = DataStoreWrapper.new(Config.Data.StoreName, Config.Data.StoreScope)
	self._sessions = {} :: { [Player]: any }
	self._jobId = if game.JobId ~= "" then game.JobId else "studio-" .. tostring(os.time())
	self._closing = false

	self.ProfileLoaded = Signal.new()
	self.ProfileReleased = Signal.new()
end

function DataService:Start()
	Players.PlayerAdded:Connect(function(player)
		self:_load(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_release(player)
	end)

	-- Jugadores que entraron antes de que este servicio estuviera listo
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_load(player)
		end)
	end

	task.spawn(function()
		self:_autoSaveLoop()
	end)

	game:BindToClose(function()
		self:_onClose()
	end)
end

--------------------------------------------------------------------------------
-- API publica
--------------------------------------------------------------------------------

function DataService:GetProfile(player: Player)
	local session = self._sessions[player]
	return if session and session.Loaded then session.Data else nil
end

function DataService:IsLoaded(player: Player): boolean
	local session = self._sessions[player]
	return session ~= nil and session.Loaded == true
end

--[[
	Espera a que el perfil este disponible. Devuelve nil si el jugador se va
	o si se agota el tiempo.
--]]
function DataService:WaitForProfile(player: Player, timeout: number?)
	local deadline = os.clock() + (timeout or 20)

	while os.clock() < deadline do
		if not player:IsDescendantOf(Players) then
			return nil
		end
		local profile = self:GetProfile(player)
		if profile then
			return profile
		end
		task.wait(0.1)
	end

	log:Warn("Timeout esperando el perfil de %s", player.Name)
	return nil
end

--[[
	Marca el perfil como modificado para que el autoguardado lo persista.
--]]
function DataService:MarkDirty(player: Player)
	local session = self._sessions[player]
	if session then
		session.Dirty = true
	end
end

--[[
	Guardado inmediato. Devuelve true si se persistio correctamente.
--]]
function DataService:Save(player: Player): boolean
	return self:_save(player, false)
end

--------------------------------------------------------------------------------
-- Interno
--------------------------------------------------------------------------------

function DataService:_key(player: Player): string
	return string.format("Player_%d", player.UserId)
end

--[[
	Intenta adquirir el bloqueo de sesion y devolver los datos guardados.
--]]
function DataService:_acquire(player: Player): (boolean, any)
	local key = self:_key(player)
	local jobId = self._jobId

	if not LOCK.Enabled then
		local ok, data = self._store:Get(key)
		return ok, data
	end

	local acquired = false

	local ok, data = self._store:Update(key, function(current)
		current = current or { Profile = nil, Lock = nil }

		local lock = current.Lock
		if lock and lock.JobId ~= jobId then
			local age = os.time() - (lock.Timestamp or 0)
			if age < LOCK.StealAfter then
				-- Otro servidor tiene la sesion activa: abortar la escritura
				return nil
			end
			log:Warn("Se libera un lock muerto de %s (%ds)", player.Name, age)
		end

		current.Lock = { JobId = jobId, Timestamp = os.time() }
		acquired = true
		return current
	end)

	if not ok then
		return false, data
	end
	if not acquired then
		return false, "session-locked"
	end

	return true, data
end

function DataService:_load(player: Player)
	if self._sessions[player] then
		return
	end

	-- Reserva la sesion inmediatamente para evitar cargas duplicadas
	self._sessions[player] = { Loaded = false, Dirty = false, CanSave = false }

	local ok, data = self:_acquire(player)

	if not player:IsDescendantOf(Players) then
		self._sessions[player] = nil
		return
	end

	local profile
	local canSave = true

	if ok then
		profile = data and data.Profile
	else
		canSave = false
		log:Error("No se pudo cargar el perfil de %s (%s)", player.Name, tostring(data))
	end

	if profile then
		Migrations.Apply(profile, Config.Data.SchemaVersion)
		ProfileTemplate.Reconcile(profile)
		log:Debug("Perfil cargado para %s", player.Name)
	else
		profile = ProfileTemplate.new()
		if ok then
			profile.Meta.FirstJoin = os.time()
			log:Info("Perfil nuevo creado para %s", player.Name)
		else
			-- Perfil temporal: NO se guarda para no sobrescribir datos reales
			log:Warn("Perfil temporal (sin guardado) para %s", player.Name)
		end
	end

	profile.Meta.LastJoin = os.time()
	profile.Meta.SessionCount += 1

	local session = self._sessions[player]
	if not session then
		return
	end

	session.Data = profile
	session.Loaded = true
	session.CanSave = canSave
	session.Dirty = canSave
	session.LockRefreshedAt = os.clock()

	self.ProfileLoaded:Fire(player, profile)
end

function DataService:_save(player: Player, releasing: boolean): boolean
	local session = self._sessions[player]
	if not session or not session.Loaded or not session.CanSave then
		return false
	end

	local profile = session.Data
	local key = self:_key(player)
	local jobId = self._jobId

	local ok = self._store:Update(key, function(current)
		current = current or {}

		if LOCK.Enabled then
			local lock = current.Lock
			if lock and lock.JobId ~= jobId then
				local age = os.time() - (lock.Timestamp or 0)
				if age < LOCK.StealAfter then
					-- Otro servidor se ha quedado la sesion: no escribir
					return nil
				end
			end
			current.Lock = if releasing then nil else { JobId = jobId, Timestamp = os.time() }
		end

		current.Profile = profile
		return current
	end)

	if ok then
		session.Dirty = false
		session.LockRefreshedAt = os.clock()
		log:Debug("Perfil guardado para %s%s", player.Name, if releasing then " (release)" else "")
	else
		log:Error("No se pudo guardar el perfil de %s", player.Name)
	end

	return ok
end

function DataService:_release(player: Player)
	local session = self._sessions[player]
	if not session then
		return
	end

	if session.Loaded then
		self.ProfileReleased:Fire(player, session.Data)
		self:_save(player, true)
	end

	self._sessions[player] = nil
end

function DataService:_autoSaveLoop()
	local interval = Config.Data.AutoSaveInterval

	while not self._closing do
		task.wait(interval)

		for player, session in pairs(self._sessions) do
			if not session.Loaded or not session.CanSave then
				continue
			end

			local needsLockRefresh = LOCK.Enabled
				and (os.clock() - (session.LockRefreshedAt or 0)) >= LOCK.RefreshInterval

			if session.Dirty or needsLockRefresh then
				self:_save(player, false)
			end
		end
	end
end

function DataService:_onClose()
	self._closing = true
	log:Info("Cierre del servidor: guardando %d perfiles", #Players:GetPlayers())

	local pending = 0
	local done = 0

	for player in pairs(self._sessions) do
		pending += 1
		task.spawn(function()
			self:_release(player)
			done += 1
		end)
	end

	local deadline = os.clock() + 20
	while done < pending and os.clock() < deadline do
		task.wait(0.1)
	end
end

return DataService
