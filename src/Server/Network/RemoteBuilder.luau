--!nonstrict
--[[
	RemoteBuilder
	----------------------------------------------------------------------------
	Crea en ReplicatedStorage la estructura de remotes descrita en
	Shared/Network/RemoteDefinitions:

		ReplicatedStorage
		└── Remotes
			├── Events      (RemoteEvent)
			└── Functions   (RemoteFunction)

	Se ejecuta una sola vez desde Bootstrap, antes de cargar los servicios.
	Crear los remotes por codigo evita remotes huerfanos en el archivo .rbxl y
	mantiene RemoteDefinitions como unica fuente de verdad.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = require(Shared.Network.RemoteDefinitions)
local Logger = require(Shared.Util.Logger)

local log = Logger.new("RemoteBuilder")

local RemoteBuilder = {}

local built = false

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function RemoteBuilder.Build(): Folder
	local root = ensureFolder(ReplicatedStorage, Definitions.FolderName)

	if built then
		return root
	end

	local events = ensureFolder(root, Definitions.EventsFolderName)
	local functions = ensureFolder(root, Definitions.FunctionsFolderName)

	local eventCount, functionCount = 0, 0

	for name, definition in pairs(Definitions.Definitions) do
		local parent = if definition.Kind == "RemoteEvent" then events else functions

		if parent:FindFirstChild(name) then
			log:Warn("El remote '%s' ya existia, se reutiliza", name)
			continue
		end

		local remote = Instance.new(definition.Kind)
		remote.Name = name
		remote.Parent = parent

		if definition.Kind == "RemoteEvent" then
			eventCount += 1
		else
			functionCount += 1
		end
	end

	built = true
	log:Info("%d RemoteEvents y %d RemoteFunctions creados", eventCount, functionCount)

	return root
end

return RemoteBuilder
