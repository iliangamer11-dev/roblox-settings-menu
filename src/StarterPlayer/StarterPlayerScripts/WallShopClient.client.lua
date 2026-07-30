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

-- Oculta una pieza de la pared en ESTE cliente. Hay que tratar cada clase por separado
-- porque no comparten la misma propiedad:
--   BasePart      -> Transparency y sin colision
--   SurfaceGui /
--   BillboardGui  -> Enabled (asi desaparecen los TextLabel de dentro, el precio y demas)
--   Decal/Texture -> Transparency (NO tienen Enabled)
--   ProximityPrompt -> Enabled
local function hidePiece(piece: Instance)
	if piece:IsA("BasePart") then
		piece.Transparency = 1
		piece.CanCollide = false
		piece.CanQuery = false
		piece.CanTouch = false
	elseif piece:IsA("SurfaceGui") or piece:IsA("BillboardGui") then
		piece.Enabled = false
	elseif piece:IsA("Decal") or piece:IsA("Texture") then
		piece.Transparency = 1
	elseif piece:IsA("ProximityPrompt") then
		piece.Enabled = false
	elseif piece:IsA("GuiObject") then
		-- Por si el texto cuelga directamente y no de un SurfaceGui/BillboardGui
		piece.Visible = false
	elseif piece:IsA("Light") or piece:IsA("ParticleEmitter") or piece:IsA("Beam") then
		piece.Enabled = false
	end
end

local function hideInstance(instance: Instance)
	hidePiece(instance)

	for _, descendant in instance:GetDescendants() do
		hidePiece(descendant)
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
