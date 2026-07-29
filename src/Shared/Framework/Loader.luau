--!nonstrict
--[[
	Loader
	----------------------------------------------------------------------------
	Cargador de modulos con ciclo de vida en dos fases. Lo usan tanto el
	Bootstrap del servidor (Services) como el del cliente (Controllers).

	Contrato de cada modulo:

		local MyService = {}
		MyService.Name = "MyService"   -- opcional, por defecto el nombre del script
		MyService.Priority = 0         -- mayor = se inicializa antes
		function MyService:Init() end  -- crear estado, NO depender de otros
		function MyService:Start() end -- ya se puede usar Loader.Get("Otro")
		return MyService

	Fases:
		1. Require de todos los modulos del contenedor.
		2. Init() en orden de prioridad descendente.
		3. Start() en orden de prioridad descendente.

	Un error en un modulo se registra pero no impide arrancar los demas.
--]]

local Logger = require(script.Parent.Parent.Util.Logger)

local log = Logger.new("Loader")

local Loader = {}

local registry: { [string]: any } = {}
local ordered: { any } = {}
local started = false

--[[
	Requiere todos los ModuleScript hijos (recursivamente) del contenedor.
	Los modulos cuyo nombre empieza por "_" se ignoran (helpers privados).
--]]
function Loader.LoadFrom(container: Instance): { any }
	local loaded = {}

	for _, descendant in ipairs(container:GetDescendants()) do
		if not descendant:IsA("ModuleScript") then
			continue
		end
		if string.sub(descendant.Name, 1, 1) == "_" then
			continue
		end

		local ok, result = pcall(require, descendant)
		if not ok then
			log:Error("No se pudo requerir %s: %s", descendant:GetFullName(), tostring(result))
			continue
		end
		if type(result) ~= "table" then
			log:Warn("%s no devuelve una tabla, se ignora", descendant:GetFullName())
			continue
		end

		result.Name = result.Name or descendant.Name

		if registry[result.Name] then
			log:Warn("Modulo duplicado '%s', se ignora %s", result.Name, descendant:GetFullName())
			continue
		end

		registry[result.Name] = result
		table.insert(ordered, result)
		table.insert(loaded, result)
	end

	table.sort(ordered, function(a, b)
		return (a.Priority or 0) > (b.Priority or 0)
	end)

	return loaded
end

--[[
	Ejecuta Init() y despues Start() en todos los modulos cargados.
--]]
function Loader.Start()
	if started then
		log:Warn("Loader.Start llamado dos veces")
		return
	end
	started = true

	for _, module in ipairs(ordered) do
		if type(module.Init) == "function" then
			local ok, err = pcall(module.Init, module)
			if not ok then
				log:Error("Init fallo en '%s': %s", module.Name, tostring(err))
			end
		end
	end

	for _, module in ipairs(ordered) do
		if type(module.Start) == "function" then
			-- Start puede hacer yield (esperar assets, datos...), asi que se
			-- lanza en su propio hilo para no bloquear el arranque.
			task.spawn(function()
				local ok, err = pcall(module.Start, module)
				if not ok then
					log:Error("Start fallo en '%s': %s", module.Name, tostring(err))
				end
			end)
		end
	end

	log:Info("%d modulos iniciados", #ordered)
end

--[[
	Acceso a un modulo ya cargado. Usar dentro de Start(), nunca en Init().
--]]
function Loader.Get(name: string): any
	local module = registry[name]
	if not module then
		error(string.format("[Loader] El modulo '%s' no esta registrado", name), 2)
	end
	return module
end

--[[
	Igual que Get pero devuelve nil en lugar de lanzar error.
--]]
function Loader.Find(name: string): any?
	return registry[name]
end

function Loader.GetAll(): { [string]: any }
	return table.clone(registry)
end

return Loader
