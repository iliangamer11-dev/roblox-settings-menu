--[[
	HoleClient (LocalScript en StarterPlayer > StarterPlayerScripts)

	Dibuja el agujero de cada picazo. Se hace en el cliente a proposito: asi cada
	jugador ve SOLO sus propios agujeros, y no los de los demas.

	El servidor manda posicion, normal de la superficie y color del mineral.
	Los ajustes (tamano, duracion, fundido) estan en MiningConfig.HOLE.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local Settings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local holeRemote = ReplicatedStorage:WaitForChild(Config.HOLE_REMOTE_NAME)

local function spawnHole(position: Vector3, normal: Vector3, color: Color3, rainbow: boolean)
	local cfg = Config.HOLE
	if not cfg.ENABLED then
		return
	end

	local hole = Instance.new("Part")
	hole.Name = "PickaxeHole"
	hole.Shape = Enum.PartType.Cylinder
	hole.Size = Vector3.new(cfg.DEPTH, cfg.SIZE, cfg.SIZE)
	hole.Color = color
	-- Con color de mineral queda mejor liso que con textura de piedra
	hole.Material = cfg.USE_MINERAL_COLOR and Enum.Material.SmoothPlastic or cfg.MATERIAL
	hole.Anchored = true
	hole.CanCollide = false
	hole.CanQuery = false
	hole.CanTouch = false
	hole.CastShadow = false

	-- El cilindro tiene el eje en X, se gira 90 grados para alinearlo con la normal
	hole.CFrame = CFrame.lookAt(position + normal * (cfg.DEPTH * 0.4), position + normal)
		* CFrame.fromEulerAnglesXYZ(0, math.rad(90), 0)
	hole.Parent = workspace

	-- Se desvanece poco a poco en vez de desaparecer de golpe
	local fadeTime = math.clamp(cfg.FADE_TIME, 0, cfg.LIFETIME)
	if fadeTime > 0 then
		local fadeInfo = TweenInfo.new(
			fadeTime,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out,
			0,
			false,
			cfg.LIFETIME - fadeTime -- espera antes de empezar a desvanecerse
		)
		TweenService:Create(hole, fadeInfo, { Transparency = 1 }):Play()
	end

	-- Mineral legendario: el agujero cicla colores mientras dura
	if rainbow then
		task.spawn(function()
			local startClock = os.clock()
			while hole.Parent do
				local hue = ((os.clock() - startClock) * cfg.RAINBOW_SPEED) % 1
				hole.Color = Color3.fromHSV(hue, 1, 1)
				task.wait(0.05)
			end
		end)
	end

	Debris:AddItem(hole, cfg.LIFETIME)
end

holeRemote.OnClientEvent:Connect(function(position, normal, color, rainbow)
	-- El jugador puede desactivarlos desde el menu de ajustes
	if not Settings.get("showHoles") then
		return
	end

	if typeof(position) ~= "Vector3" or typeof(normal) ~= "Vector3" or typeof(color) ~= "Color3" then
		return
	end

	spawnHole(position, normal, color, rainbow == true)
end)
