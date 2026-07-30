--[[
	WallShopClient (LocalScript en StarterPlayer > StarterPlayerScripts)

	Cuando el servidor confirma la compra, esconde la pared SOLO en este cliente:
	se pone invisible y sin colision, asi este jugador la atraviesa y los demas
	siguen viendo la suya.

	Tambien muestra el aviso en ingles si no llega el dinero.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local wallRemote = ReplicatedStorage:WaitForChild(Config.WALL_REMOTE_NAME)

local promptSettings = Config.WALL_PROMPT

local wallByName = {}
for _, wall in Config.WALLS do
	wallByName[wall.NAME] = wall
end

-- Paredes ya compradas en esta sesion, para volver a esconderlas si el servidor
-- las vuelve a enviar (respawn o streaming)
local unlocked = {}

local function hideInstance(instance: Instance)
	if instance:IsA("BasePart") then
		instance.Transparency = 1
		instance.CanCollide = false
		instance.CanQuery = false
		instance.CanTouch = false
	end

	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		elseif descendant:IsA("ProximityPrompt") or descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Enabled = false
		end
	end

	local prompt = instance:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.Enabled = false
	end
end

local function hideWall(wallName: string)
	unlocked[wallName] = true

	for _, descendant in workspace:GetDescendants() do
		if descendant.Name == wallName then
			hideInstance(descendant)
		end
	end
end

-- Aviso cuando no llega el dinero: se cambia el texto del boton un momento.
-- Es un cambio local, no afecta a los demas jugadores.
local function showFailed(wallName: string, missing: string)
	local wall = wallByName[wallName]
	if not wall then
		return
	end

	for _, descendant in workspace:GetDescendants() do
		if descendant.Name == wallName then
			local prompt = descendant:IsA("ProximityPrompt") and descendant
				or descendant:FindFirstChildWhichIsA("ProximityPrompt", true)

			if prompt then
				local original = prompt.ActionText
				prompt.ActionText = string.format(promptSettings.FAILED_TEXT, missing)

				task.delay(promptSettings.FEEDBACK_TIME, function()
					if prompt.Parent then
						prompt.ActionText = original
					end
				end)
			end
		end
	end
end

wallRemote.OnClientEvent:Connect(function(action: string, wallName: string, extra: any)
	if action == "unlocked" then
		hideWall(wallName)
	elseif action == "failed" then
		showFailed(wallName, tostring(extra))
	end
end)

-- Si la pared se vuelve a cargar (streaming), se esconde otra vez
workspace.DescendantAdded:Connect(function(descendant)
	if unlocked[descendant.Name] then
		task.defer(hideInstance, descendant)
	end
end)
