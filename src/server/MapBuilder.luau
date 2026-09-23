-- Generates the whole world from code so the place needs no hand-built assets:
-- lobby, a row of garage bays, the showcase stage and the winners' podium.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local MapBuilder = {}

export type Bay = {
	Index: number,
	CarCFrame: CFrame,
	NameLabel: TextLabel,
	Model: Model,
}

export type MapInfo = {
	Bays: { Bay },
	StageCFrame: CFrame,
	StageEntryCFrame: CFrame,
	PodiumCFrames: { CFrame },
	Confetti: { ParticleEmitter },
}

local ACCENT = Color3.fromRGB(255, 106, 0)

local function part(parent: Instance, props: { [string]: any }): BasePart
	local p: BasePart = if props.Wedge then Instance.new("WedgePart") else Instance.new("Part")
	props.Wedge = nil
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = parent
	return p
end

local function sign(host: BasePart, face: Enum.NormalId, text: string, color: Color3?, font: Enum.Font?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = host
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = font or Enum.Font.GothamBlack
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.08, 0)
	padding.PaddingBottom = UDim.new(0.08, 0)
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.Parent = label
	return label
end

local function setupLighting()
	Lighting.ClockTime = 19.4
	Lighting.Brightness = 1.6
	Lighting.Ambient = Color3.fromRGB(46, 46, 58)
	Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 104)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true

	local function ensure(className: string, name: string): Instance
		local existing = Lighting:FindFirstChild(name)
		if existing then
			return existing
		end
		local inst = Instance.new(className)
		inst.Name = name
		inst.Parent = Lighting
		return inst
	end
	local bloom = ensure("BloomEffect", "CarBloom") :: BloomEffect
	bloom.Intensity = 0.9
	bloom.Size = 28
	bloom.Threshold = 1.3
	local grade = ensure("ColorCorrectionEffect", "CarGrade") :: ColorCorrectionEffect
	grade.Contrast = 0.12
	grade.Saturation = 0.12
	local atmosphere = ensure("Atmosphere", "CarAtmosphere") :: Atmosphere
	atmosphere.Density = 0.32
	atmosphere.Haze = 1.2
	atmosphere.Color = Color3.fromRGB(120, 110, 160)
	atmosphere.Decay = Color3.fromRGB(60, 50, 90)
end

local function buildLobby(map: Instance)
	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	lobby.Parent = map
	local c = Config.LobbyCenter
	part(lobby, {
		Name = "LobbyFloor",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 70, 70),
		CFrame = CFrame.new(c + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(34, 34, 40),
		Material = Enum.Material.Concrete,
	})
	part(lobby, {
		Name = "LobbyRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.62, 71, 71),
		CFrame = CFrame.new(c + Vector3.new(0, 0.29, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = ACCENT,
		Material = Enum.Material.Neon,
	})
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 0.4, 12)
	spawn.CFrame = CFrame.new(c + Vector3.new(0, 0.8, 0))
	spawn.Color = Color3.fromRGB(40, 40, 46)
	spawn.Material = Enum.Material.Metal
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = lobby

	local board = part(lobby, {
		Name = "TitleBoard",
		Size = Vector3.new(44, 14, 1),
		CFrame = CFrame.new(c + Vector3.new(0, 12, -32)),
		Color = Color3.fromRGB(18, 18, 22),
	})
	sign(board, Enum.NormalId.Back, "CAR DRESS UP", ACCENT)
	local rules = part(lobby, {
		Name = "RulesBoard",
		Size = Vector3.new(30, 12, 1),
		CFrame = CFrame.new(c + Vector3.new(30, 7, -18)) * CFrame.Angles(0, math.rad(-40), 0),
		Color = Color3.fromRGB(18, 18, 22),
	})
	sign(
		rules,
		Enum.NormalId.Back,
		"1. Pick a car\n2. Customise it in 5 minutes\n3. Show it off on stage\n4. Rate everyone's rides\n5. Top 3 take the podium",
		Color3.new(1, 1, 1),
		Enum.Font.GothamBold
	)
end

local function buildGarage(map: Instance): { Bay }
	local garage = Instance.new("Model")
	garage.Name = "Garage"
	garage.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	garage.Parent = map

	local bays: { Bay } = {}
	local count = Config.MaxParticipants
	local origin = Config.GarageOrigin
	for i = 1, count do
		local x = (i - (count + 1) / 2) * Config.BaySpacing
		local center = origin + Vector3.new(x, 0, 0)
		local bay = Instance.new("Model")
		bay.Name = "Bay" .. i
		bay.Parent = garage

		part(bay, {
			Name = "Floor",
			Size = Vector3.new(Config.BaySpacing - 2, 0.4, 30),
			CFrame = CFrame.new(center + Vector3.new(0, 0.2, 0)),
			Color = Color3.fromRGB(70, 72, 78),
			Material = Enum.Material.Concrete,
		})
		part(bay, {
			Name = "Turntable",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 24, 24),
			CFrame = CFrame.new(center + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(28, 28, 32),
			Material = Enum.Material.DiamondPlate,
		})
		part(bay, {
			Name = "TurntableRing",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.28, 24.6, 24.6),
			CFrame = CFrame.new(center + Vector3.new(0, 0.54, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = ACCENT,
			Material = Enum.Material.Neon,
		})
		part(bay, {
			Name = "BackWall",
			Size = Vector3.new(Config.BaySpacing - 2, 16, 1),
			CFrame = CFrame.new(center + Vector3.new(0, 8, -15)),
			Color = Color3.fromRGB(40, 42, 48),
			Material = Enum.Material.Brick,
		})
		local header = part(bay, {
			Name = "Header",
			Size = Vector3.new(Config.BaySpacing - 6, 3.4, 0.4),
			CFrame = CFrame.new(center + Vector3.new(0, 13, -14.3)),
			Color = Color3.fromRGB(15, 15, 18),
		})
		sign(header, Enum.NormalId.Back, "BAY " .. i, ACCENT)
		local nameplate = part(bay, {
			Name = "Nameplate",
			Size = Vector3.new(Config.BaySpacing - 6, 2.6, 0.4),
			CFrame = CFrame.new(center + Vector3.new(0, 10, -14.3)),
			Color = Color3.fromRGB(15, 15, 18),
		})
		local nameLabel = sign(nameplate, Enum.NormalId.Back, "OPEN", Color3.new(1, 1, 1), Enum.Font.GothamBold)
		for _, side in { -1, 1 } do
			part(bay, {
				Name = "Divider",
				Size = Vector3.new(0.6, 1.2, 30),
				CFrame = CFrame.new(center + Vector3.new(side * (Config.BaySpacing / 2 - 1), 0.6, 0)),
				Color = Color3.fromRGB(230, 190, 20),
			})
		end
		local lamp = part(bay, {
			Name = "Lamp",
			Size = Vector3.new(10, 0.4, 2),
			CFrame = CFrame.new(center + Vector3.new(0, 15.5, -8)),
			Color = Color3.fromRGB(255, 250, 240),
			Material = Enum.Material.Neon,
		})
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Range = 30
		light.Angle = 110
		light.Brightness = 2.2
		light.Shadows = true
		light.Parent = lamp

		table.insert(bays, {
			Index = i,
			-- Cars face out of the bay, toward the lobby (+Z).
			CarCFrame = CFrame.new(center + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, math.pi, 0),
			NameLabel = nameLabel,
			Model = bay,
		})
	end
	return bays
end

local function buildStage(map: Instance): (CFrame, CFrame)
	local stage = Instance.new("Model")
	stage.Name = "Stage"
	stage.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	stage.Parent = map
	local c = Config.StageCenter
	local hgt = Config.StageHeight

	part(stage, {
		Name = "StageDisc",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(hgt, 34, 34),
		CFrame = CFrame.new(c + Vector3.new(0, hgt / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(20, 20, 24),
		Material = Enum.Material.Marble,
		Reflectance = 0.1,
	})
	part(stage, {
		Name = "StageRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(hgt - 0.05, 34.8, 34.8),
		CFrame = CFrame.new(c + Vector3.new(0, hgt / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = ACCENT,
		Material = Enum.Material.Neon,
	})
	part(stage, {
		Name = "Runway",
		Size = Vector3.new(16, hgt, 60),
		CFrame = CFrame.new(c + Vector3.new(0, hgt / 2, 42)),
		Color = Color3.fromRGB(24, 24, 28),
		Material = Enum.Material.Marble,
	})
	for _, side in { -1, 1 } do
		part(stage, {
			Name = "RunwayLight",
			Size = Vector3.new(0.4, 0.2, 60),
			CFrame = CFrame.new(c + Vector3.new(side * 7.6, hgt + 0.1, 42)),
			Color = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Neon,
		})
		-- Light towers
		local tower = part(stage, {
			Name = "LightTower",
			Size = Vector3.new(1.5, 24, 1.5),
			CFrame = CFrame.new(c + Vector3.new(side * 26, 12, -6)),
			Color = Color3.fromRGB(30, 30, 34),
			Material = Enum.Material.Metal,
		})
		local head = part(stage, {
			Name = "Spot",
			Size = Vector3.new(3, 2, 3),
			CFrame = CFrame.lookAt(c + Vector3.new(side * 24, 22, -5), c + Vector3.new(0, hgt, 0)),
			Color = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Neon,
		})
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Front
		spot.Range = 45
		spot.Angle = 40
		spot.Brightness = 5
		spot.Shadows = true
		spot.Parent = head
		tower.Name = "LightTower"
	end
	local backdrop = part(stage, {
		Name = "Backdrop",
		Size = Vector3.new(80, 30, 2),
		CFrame = CFrame.new(c + Vector3.new(0, 15, 74)),
		Color = Color3.fromRGB(14, 14, 18),
	})
	sign(backdrop, Enum.NormalId.Front, "SHOWROOM", ACCENT)
	local front = part(stage, {
		Name = "FrontGlow",
		Size = Vector3.new(34, 0.3, 0.3),
		CFrame = CFrame.new(c + Vector3.new(0, 0.15, -17.5)),
		Color = ACCENT,
		Material = Enum.Material.Neon,
	})
	front.Name = "FrontGlow"

	-- Cars end facing the camera side (-Z), driving in from the runway.
	local stageCF = CFrame.new(c + Vector3.new(0, hgt, 0))
	local entryCF = CFrame.new(c + Vector3.new(0, hgt, 60))
	return stageCF, entryCF
end

local function buildPodium(map: Instance): ({ CFrame }, { ParticleEmitter })
	local podium = Instance.new("Model")
	podium.Name = "Podium"
	podium.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	podium.Parent = map
	local c = Config.PodiumCenter
	local blocks = {
		{ Place = 1, X = 0, H = 4, Color = Color3.fromRGB(212, 172, 58) },
		{ Place = 2, X = -24, H = 2.6, Color = Color3.fromRGB(190, 194, 202) },
		{ Place = 3, X = 24, H = 1.4, Color = Color3.fromRGB(176, 110, 60) },
	}
	local cfs = {}
	for _, b in blocks do
		local block = part(podium, {
			Name = "Place" .. b.Place,
			Size = Vector3.new(22, b.H, 22),
			CFrame = CFrame.new(c + Vector3.new(b.X, b.H / 2, 0)),
			Color = b.Color,
			Material = Enum.Material.Metal,
			Reflectance = 0.15,
		})
		sign(block, Enum.NormalId.Front, tostring(b.Place), Color3.fromRGB(20, 20, 20))
		cfs[b.Place] = CFrame.new(c + Vector3.new(b.X, b.H, 0)) * CFrame.Angles(0, math.rad(b.X), 0)
	end
	local backdrop = part(podium, {
		Name = "Backdrop",
		Size = Vector3.new(90, 26, 2),
		CFrame = CFrame.new(c + Vector3.new(0, 13, 22)),
		Color = Color3.fromRGB(14, 14, 18),
	})
	sign(backdrop, Enum.NormalId.Front, "WINNERS", Color3.fromRGB(255, 210, 60))

	local confetti = {}
	for _, x in { -24, 0, 24 } do
		local emitterHost = part(podium, {
			Name = "ConfettiHost",
			Size = Vector3.new(20, 0.2, 10),
			CFrame = CFrame.new(c + Vector3.new(x, 24, 0)),
			Transparency = 1,
			CanCollide = false,
		})
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 220, 60)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(60, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 80, 255)),
		})
		emitter.Size = NumberSequence.new(0.35)
		emitter.Lifetime = NumberRange.new(3, 5)
		emitter.Rate = 60
		emitter.Speed = NumberRange.new(2, 5)
		emitter.SpreadAngle = Vector2.new(60, 60)
		emitter.Acceleration = Vector3.new(0, -6, 0)
		emitter.RotSpeed = NumberRange.new(-200, 200)
		emitter.EmissionDirection = Enum.NormalId.Bottom
		emitter.LightEmission = 0.4
		emitter.Enabled = false
		emitter.Parent = emitterHost
		table.insert(confetti, emitter)
	end
	return cfs, confetti
end

function MapBuilder.build(): MapInfo
	setupLighting()

	local existing = workspace:FindFirstChild("Map")
	if existing then
		existing:Destroy()
	end
	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace

	part(map, {
		Name = "Ground",
		Size = Vector3.new(900, 1, 900),
		CFrame = CFrame.new(0, -0.5, 0),
		Color = Color3.fromRGB(30, 31, 35),
		Material = Enum.Material.Asphalt,
	})

	buildLobby(map)
	local bays = buildGarage(map)
	local stageCF, entryCF = buildStage(map)
	local podiumCFs, confetti = buildPodium(map)

	local cars = workspace:FindFirstChild("Cars")
	if not cars then
		cars = Instance.new("Folder")
		cars.Name = "Cars"
		cars.Parent = workspace
	end

	return {
		Bays = bays,
		StageCFrame = stageCF,
		StageEntryCFrame = entryCF,
		PodiumCFrames = podiumCFs,
		Confetti = confetti,
	}
end

return MapBuilder
