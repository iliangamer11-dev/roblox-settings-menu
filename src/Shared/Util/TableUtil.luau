--!nonstrict
--[[
	TableUtil
	Helpers de tablas usados sobre todo por el sistema de datos
	(clonado de plantillas, reconciliacion de perfiles antiguos, etc.).
--]]

local TableUtil = {}

--[[
	Copia profunda de una tabla.
--]]
function TableUtil.DeepCopy<T>(source: T): T
	if type(source) ~= "table" then
		return source
	end

	local copy = {}
	for key, value in pairs(source :: any) do
		copy[key] = TableUtil.DeepCopy(value)
	end
	return copy :: any
end

--[[
	Reconcilia `target` con `template`: anade las claves que falten (copiadas
	de la plantilla) sin sobrescribir los valores existentes. Es la base para
	anadir campos nuevos al perfil sin romper datos guardados.
--]]
function TableUtil.Reconcile(target: { [any]: any }, template: { [any]: any }): { [any]: any }
	for key, value in pairs(template) do
		if target[key] == nil then
			target[key] = TableUtil.DeepCopy(value)
		elseif type(value) == "table" and type(target[key]) == "table" then
			TableUtil.Reconcile(target[key], value)
		end
	end
	return target
end

--[[
	Numero de pares clave/valor (funciona con tablas asociativas).
--]]
function TableUtil.Count(source: { [any]: any }): number
	local count = 0
	for _ in pairs(source) do
		count += 1
	end
	return count
end

--[[
	Devuelve las claves de una tabla como array.
--]]
function TableUtil.Keys(source: { [any]: any }): { any }
	local keys = {}
	for key in pairs(source) do
		table.insert(keys, key)
	end
	return keys
end

--[[
	Devuelve los valores de una tabla como array.
--]]
function TableUtil.Values(source: { [any]: any }): { any }
	local values = {}
	for _, value in pairs(source) do
		table.insert(values, value)
	end
	return values
end

return TableUtil
