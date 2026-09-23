-- Bolt-on exterior parts: bumpers, skirts, spoilers, hood/roof add-ons,
-- widebody arches, headlights, taillights, mirrors and per-car extras.

local Util = require(script.Parent.Util)

local Kits = {}

local EXHAUST_INNER = Color3.fromRGB(12, 12, 12)

local function exhaustTip(ctx, x: number, y: number, radius: number)
	local z = ctx.zR + 0.3
	Util.disc(ctx, ctx.chassisCF * Util.facingRear(Vector3.new(x, y, z)), radius, 0.6, { Name = "ExhaustTip", Look = "Chrome" })
	Util.disc(
		ctx,
		ctx.chassisCF * Util.facingRear(Vector3.new(x, y, z + 0.31)),
		radius * 0.72,
		0.02,
		{ Name = "ExhaustHole", Color = EXHAUST_INNER }
	)
end

-- Front bumper ------------------------------------------------------------------

local function frontBumper(ctx)
	local W, c, zF = ctx.W, ctx.c, ctx.zF
	local hN = ctx.noseBoxHeight
	local style = ctx.build.FrontBumper

	if style == "BullBar" then
		local z = zF - 0.7
		for _, side in { -1, 1 } do
			Util.part(ctx, {
				Name = "BullBarPost",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(hN + 0.6, 0.3, 0.3),
				CFrame = CFrame.new(side * W * 0.28, c + (hN + 0.6) / 2, z) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(45, 45, 48),
				Material = Enum.Material.Metal,
			})
		end
		for _, y in { c + 0.3, c + hN + 0.3 } do
			Util.part(ctx, {
				Name = "BullBarRail",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(W * 0.7, 0.28, 0.28),
				CFrame = CFrame.new(0, y, z),
				Color = Color3.fromRGB(45, 45, 48),
				Material = Enum.Material.Metal,
			})
		end
		Util.part(ctx, {
			Name = "SkidPlate",
			Size = Vector3.new(W * 0.6, 0.12, 1.2),
			CFrame = CFrame.new(0, c - 0.05, zF - 0.1),
			Material = Enum.Material.DiamondPlate,
			Color = Color3.fromRGB(150, 150, 155),
		})
	end

	-- Every style keeps a body-coloured bumper bar.
	local bumperH = hN * 0.45
	Util.part(ctx, {
		Name = "FrontBumper",
		Size = Vector3.new(W * 0.97, bumperH, 0.5),
		CFrame = CFrame.new(0, c + bumperH / 2, zF - 0.2),
		Look = "Paint",
	})
	Util.part(ctx, {
		Name = "Grille",
		Size = Vector3.new(W * 0.34, hN * 0.32, 0.06),
		CFrame = CFrame.new(0, c + hN * 0.68, zF - 0.03),
		Look = "Trim",
	})

	if style == "Lip" then
		Util.part(ctx, {
			Name = "FrontLip",
			Size = Vector3.new(W, 0.1, 0.9),
			CFrame = CFrame.new(0, c + 0.05, zF - 0.35),
			Look = "Carbon",
		})
	elseif style == "Splitter" or style == "Canards" then
		Util.part(ctx, {
			Name = "Intake",
			Size = Vector3.new(W * 0.55, bumperH * 0.5, 0.05),
			CFrame = CFrame.new(0, c + bumperH * 0.45, zF - 0.46),
			Look = "Trim",
		})
		Util.part(ctx, {
			Name = "Splitter",
			Size = Vector3.new(W * 1.06, 0.1, 1.5),
			CFrame = CFrame.new(0, c + 0.02, zF - 0.5),
			Look = "Carbon",
		})
		for _, side in { -1, 1 } do
			Util.part(ctx, {
				Name = "SplitterStrut",
				Size = Vector3.new(0.06, 0.35, 0.06),
				CFrame = CFrame.new(side * W * 0.3, c + 0.2, zF - 1.1),
				Look = "Trim",
			})
		end
		if style == "Canards" then
			for _, side in { -1, 1 } do
				for i = 0, 1 do
					Util.part(ctx, {
						Name = "Canard",
						Size = Vector3.new(0.9, 0.06, 0.55),
						CFrame = CFrame.new(side * (W / 2 - 0.05), c + bumperH * 0.6 + i * 0.35, zF - 0.35)
							* CFrame.Angles(0, side * math.rad(-15), side * math.rad(-12)),
						Look = "Carbon",
					})
				end
				Util.part(ctx, {
					Name = "SideIntake",
					Size = Vector3.new(W * 0.14, bumperH * 0.55, 0.05),
					CFrame = CFrame.new(side * W * 0.36, c + bumperH * 0.45, zF - 0.46),
					Look = "Trim",
				})
			end
		end
	end
end

-- Rear bumper -----------------------------------------------------------------------

local function rearBumper(ctx)
	local W, c, h, zR = ctx.W, ctx.c, ctx.h, ctx.zR
	local style = ctx.build.RearBumper
	local barH = h * 0.32
	Util.part(ctx, {
		Name = "RearBumper",
		Size = Vector3.new(W * 0.97, barH, 0.4),
		CFrame = CFrame.new(0, c + barH / 2, zR + 0.15),
		Look = "Paint",
	})

	if style == "Stock" then
		for _, side in { -1, 1 } do
			exhaustTip(ctx, side * W * 0.3, c + 0.2, 0.2)
		end
	elseif style == "QuadExhaust" then
		for _, side in { -1, 1 } do
			exhaustTip(ctx, side * W * 0.26, c + 0.22, 0.24)
			exhaustTip(ctx, side * W * 0.36, c + 0.22, 0.24)
		end
	elseif style == "Diffuser" or style == "RaceDiffuser" then
		local big = style == "RaceDiffuser"
		local dW = if big then W * 0.85 else W * 0.62
		local dL = if big then 1.6 else 1.1
		Util.part(ctx, {
			Name = "Diffuser",
			Size = Vector3.new(dW, 0.1, dL),
			CFrame = CFrame.new(0, c - 0.02, zR + dL / 2 - 0.2),
			Look = "Carbon",
		})
		local fins = if big then 6 else 4
		for i = 1, fins do
			local x = -dW / 2 + dW * (i / (fins + 1))
			Util.part(ctx, {
				Name = "DiffuserFin",
				Class = "WedgePart",
				Size = Vector3.new(0.06, if big then 0.55 else 0.35, dL),
				CFrame = CFrame.new(x, c + (if big then 0.25 else 0.15), zR + dL / 2 - 0.2),
				Look = "Carbon",
			})
		end
		if big then
			Util.part(ctx, {
				Name = "RainLight",
				Size = Vector3.new(0.5, 0.25, 0.08),
				CFrame = CFrame.new(0, c + barH * 0.7, zR + 0.38),
				Color = Color3.fromRGB(255, 20, 20),
				Look = "Neon",
			})
			exhaustTip(ctx, -0.35, c + 0.25, 0.22)
			exhaustTip(ctx, 0.35, c + 0.25, 0.22)
		else
			for _, side in { -1, 1 } do
				exhaustTip(ctx, side * (dW / 2 + 0.4), c + 0.2, 0.22)
			end
		end
	end
end

-- Side skirts ---------------------------------------------------------------------------

local function sideSkirts(ctx)
	local style = ctx.build.SideSkirts
	if style == "None" then
		return
	end
	local W, c = ctx.W, ctx.c
	local z0 = ctx.frontAxle + ctx.frontR + 0.25
	local z1 = ctx.rearAxle - ctx.rearR - 0.25
	local len = z1 - z0
	local mid = (z0 + z1) / 2

	for _, side in { -1, 1 } do
		if style == "Slim" then
			Util.part(ctx, {
				Name = "SideSkirt",
				Size = Vector3.new(0.3, 0.22, len),
				CFrame = CFrame.new(side * (W / 2 + 0.1), c - 0.04, mid),
				Look = "Paint",
			})
		elseif style == "Aero" then
			Util.part(ctx, {
				Name = "SideSkirt",
				Size = Vector3.new(0.5, 0.26, len),
				CFrame = CFrame.new(side * (W / 2 + 0.18), c - 0.05, mid),
				Look = "Carbon",
			})
			Util.part(ctx, {
				Name = "SkirtWinglet",
				Size = Vector3.new(0.55, 0.3, 0.06),
				CFrame = CFrame.new(side * (W / 2 + 0.4), c + 0.05, z1 - 0.1) * CFrame.Angles(0, side * math.rad(20), 0),
				Look = "Carbon",
			})
		elseif style == "MudFlaps" then
			for _, z in { ctx.frontAxle + ctx.frontR + 0.15, ctx.rearAxle + ctx.rearR + 0.15 } do
				Util.part(ctx, {
					Name = "MudFlap",
					Size = Vector3.new(ctx.wheelW * 0.95, 1.1, 0.08),
					CFrame = CFrame.new(side * ctx.trackX, 0.62 - ctx.rideOffset, z),
					Color = Color3.fromRGB(30, 30, 34),
					Material = Enum.Material.Rubber,
				})
			end
		end
	end
end

-- Spoilers (mounted on the trunk lid so they rise with it) ---------------------------------

local function wing(ctx, anchor: BasePart, postH: number, wingW: number, chord: number, angle: number, look: string, swan: boolean)
	local W = ctx.W
	local baseY = ctx.yT + 0.2
	local z = ctx.zR - 0.7
	local wingY = baseY + postH
	for _, side in { -1, 1 } do
		if swan then
			Util.part(ctx, {
				Name = "SwanNeck",
				Size = Vector3.new(0.12, postH + 0.35, 0.28),
				CFrame = CFrame.new(side * W * 0.22, baseY + (postH + 0.35) / 2, z + chord * 0.1),
				Look = "Trim",
			}, anchor)
			Util.part(ctx, {
				Name = "SwanHook",
				Size = Vector3.new(0.12, 0.12, chord * 0.5),
				CFrame = CFrame.new(side * W * 0.22, wingY + 0.3, z),
				Look = "Trim",
			}, anchor)
		else
			Util.part(ctx, {
				Name = "WingPost",
				Size = Vector3.new(0.14, postH, 0.45),
				CFrame = CFrame.new(side * W * 0.3, baseY + postH / 2, z),
				Look = "Trim",
			}, anchor)
		end
		Util.part(ctx, {
			Name = "EndPlate",
			Size = Vector3.new(0.08, 0.75, chord + 0.3),
			CFrame = CFrame.new(side * wingW / 2, wingY + 0.1, z),
			Look = look,
		}, anchor)
	end
	Util.part(ctx, {
		Name = "Wing",
		Size = Vector3.new(wingW, 0.12, chord),
		CFrame = CFrame.new(0, wingY + 0.06, z) * CFrame.Angles(math.rad(angle), 0, 0),
		Look = look,
	}, anchor)
end

local function spoiler(ctx)
	local style = ctx.build.Spoiler
	local anchor = ctx.trunkHinge
	local W = ctx.W
	local topY = ctx.yT + 0.2
	if style == "Lip" then
		Util.part(ctx, {
			Name = "LipSpoiler",
			Class = "WedgePart",
			Size = Vector3.new(W * 0.9, 0.22, 0.6),
			CFrame = CFrame.new(0, topY + 0.11, ctx.zR - 0.3),
			Look = "Paint",
		}, anchor)
	elseif style == "Ducktail" then
		Util.part(ctx, {
			Name = "Ducktail",
			Class = "WedgePart",
			Size = Vector3.new(W * 0.94, 0.5, 1.3),
			CFrame = CFrame.new(0, topY + 0.25, ctx.zR - 0.65),
			Look = "Paint",
		}, anchor)
	elseif style == "GTWing" then
		wing(ctx, anchor, 0.9, W * 0.96, 1.1, -8, "Carbon", false)
	elseif style == "SwanNeck" then
		wing(ctx, anchor, 1.05, W * 1.0, 1.25, -12, "Carbon", true)
	elseif style == "DragWing" then
		wing(ctx, anchor, 1.7, W * 0.9, 1.3, -4, "Paint", false)
	end
end

-- Hood add-ons --------------------------------------------------------------------------------

local function hoodExtras(ctx)
	local style = ctx.build.Hood
	local W = ctx.W
	local hoodY = ctx.yT + 0.2
	local anchor = ctx.hoodHinge
	local mid, len = ctx.bayMid, ctx.bayLen

	if table.find(ctx.spec.Extras, "HoodBulge") and style ~= "Blower" and style ~= "Scoop" then
		Util.part(ctx, {
			Name = "PowerBulge",
			Size = Vector3.new(W * 0.35, 0.22, len * 0.8),
			CFrame = CFrame.new(0, hoodY + 0.11, mid),
			Look = "Paint",
		}, anchor)
	end

	if style == "Vented" then
		for _, side in { -1, 1 } do
			for i = 0, 3 do
				Util.part(ctx, {
					Name = "HoodVent",
					Size = Vector3.new(W * 0.22, 0.03, 0.12),
					CFrame = CFrame.new(side * W * 0.22, hoodY + 0.015, mid - len * 0.1 + i * 0.3),
					Look = "Trim",
				}, anchor)
			end
		end
	elseif style == "Scoop" then
		-- Tall end faces forward so the opening points into the wind.
		Util.part(ctx, {
			Name = "HoodScoop",
			Class = "WedgePart",
			Size = Vector3.new(W * 0.3, 0.55, len * 0.55),
			CFrame = CFrame.new(0, hoodY + 0.275, mid + len * 0.05) * CFrame.Angles(0, math.pi, 0),
			Look = "Paint",
		}, anchor)
		Util.part(ctx, {
			Name = "ScoopMouth",
			Size = Vector3.new(W * 0.26, 0.42, 0.04),
			CFrame = CFrame.new(0, hoodY + 0.26, mid + len * 0.05 - len * 0.275 - 0.01),
			Look = "Trim",
		}, anchor)
	elseif style == "Blower" then
		local engineColor = ctx.colors.Engine
		Util.part(ctx, {
			Name = "Blower",
			Size = Vector3.new(W * 0.28, 0.9, len * 0.45),
			CFrame = CFrame.new(0, hoodY + 0.25, mid),
			Color = engineColor,
			Material = Enum.Material.Metal,
			Reflectance = 0.15,
		})
		for i = 0, 5 do
			Util.part(ctx, {
				Name = "BlowerRib",
				Size = Vector3.new(W * 0.29, 0.06, 0.08),
				CFrame = CFrame.new(0, hoodY + 0.1 + i * 0.12, mid - len * 0.2),
				Look = "Chrome",
			})
		end
		Util.part(ctx, {
			Name = "BlowerHat",
			Size = Vector3.new(W * 0.2, 0.35, len * 0.3),
			CFrame = CFrame.new(0, hoodY + 0.88, mid),
			Look = "Chrome",
		})
		for _, x in { -0.35, 0.35 } do
			Util.part(ctx, {
				Name = "Butterfly",
				Size = Vector3.new(0.5, 0.04, 0.3),
				CFrame = CFrame.new(x, hoodY + 1.07, mid - len * 0.05) * CFrame.Angles(math.rad(30), 0, 0),
				Look = "Trim",
			})
		end
	end
end

-- Roof add-ons ------------------------------------------------------------------------------

local function roofExtras(ctx)
	local style = ctx.build.Roof
	local y = ctx.roofTopY
	local zc0, zc1, cabinW = ctx.zc0, ctx.zc1, ctx.cabinW
	if style == "Scoop" then
		Util.part(ctx, {
			Name = "RoofScoop",
			Class = "WedgePart",
			Size = Vector3.new(1.3, 0.45, 1.5),
			CFrame = CFrame.new(0, y + 0.225, zc0 + 0.9) * CFrame.Angles(0, math.pi, 0),
			Look = "Paint",
		})
		Util.part(ctx, {
			Name = "RoofScoopMouth",
			Size = Vector3.new(1.1, 0.34, 0.04),
			CFrame = CFrame.new(0, y + 0.2, zc0 + 0.14),
			Look = "Trim",
		})
	elseif style == "Vortex" then
		for i = -3, 3 do
			Util.part(ctx, {
				Name = "VortexFin",
				Class = "WedgePart",
				Size = Vector3.new(0.06, 0.28, 0.5),
				CFrame = CFrame.new(i * cabinW * 0.12, y + 0.14, zc1 - 0.35),
				Look = "Carbon",
			})
		end
	elseif style == "RoofWing" then
		for _, side in { -1, 1 } do
			Util.part(ctx, {
				Name = "RoofWingPost",
				Size = Vector3.new(0.1, 0.3, 0.3),
				CFrame = CFrame.new(side * cabinW * 0.3, y + 0.15, zc1 - 0.1),
				Look = "Trim",
			})
		end
		Util.part(ctx, {
			Name = "RoofWing",
			Size = Vector3.new(cabinW + 0.2, 0.1, 0.8),
			CFrame = CFrame.new(0, y + 0.35, zc1 + 0.05) * CFrame.Angles(math.rad(-10), 0, 0),
			Look = "Paint",
		})
	elseif style == "LightBar" then
		Util.part(ctx, {
			Name = "LightBarFrame",
			Size = Vector3.new(cabinW * 0.9, 0.12, 0.25),
			CFrame = CFrame.new(0, y + 0.2, zc0 + 0.3),
			Look = "Trim",
		})
		for i = -3, 3 do
			local lamp = Util.part(ctx, {
				Name = "RoofLamp",
				Size = Vector3.new(0.5, 0.4, 0.2),
				CFrame = CFrame.new(i * cabinW * 0.12, y + 0.46, zc0 + 0.3),
				Look = "Trim",
			})
			Util.part(ctx, {
				Name = "RoofLampLens",
				Size = Vector3.new(0.4, 0.3, 0.05),
				CFrame = CFrame.new(i * cabinW * 0.12, y + 0.46, zc0 + 0.18),
				Color = ctx.colors.Headlight,
				Look = "Neon",
			}, lamp)
		end
	end
end

-- Widebody arches / flares --------------------------------------------------------------------

local function arches(ctx)
	local style = ctx.build.Widebody
	if style == "Off" then
		return
	end
	local full = style == "Full"
	for _, wheel in ctx.wheelLayout do
		local r = wheel.Radius + 0.2
		local x = wheel.Side * (ctx.W / 2 + (if full then 0.05 else 0.2))
		-- Arch centred on the axle, in chassis space.
		local base = CFrame.new(x, wheel.Radius - ctx.rideOffset, wheel.Z)
		Util.ring(ctx, ctx.chassisCF * base, r, 0.35, if full then 0.6 else 0.4, 7, {
			Name = "Arch",
			Look = if full then "Paint" else "Trim",
		}, nil, math.rad(-75), math.rad(75))
		if not full then
			for i = 0, 4 do
				local a = math.rad(-60 + i * 30)
				Util.part(ctx, {
					Name = "Rivet",
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(0.1, 0.1, 0.1),
					CFrame = base * CFrame.Angles(a, 0, 0) * CFrame.new(wheel.Side * 0.2, r, 0),
					Look = "Chrome",
				})
			end
		end
	end
end

-- Headlights -----------------------------------------------------------------------------------

local function headlights(ctx)
	local style = ctx.build.Headlights
	local W, c, zF = ctx.W, ctx.c, ctx.zF
	local hN = ctx.noseBoxHeight
	local color = ctx.colors.Headlight
	local y = c + hN * 0.72
	local z = zF - 0.03

	local beamHost: BasePart? = nil
	for _, side in { -1, 1 } do
		local x = side * W * 0.33
		if style == "Stock" then
			Util.part(ctx, {
				Name = "HeadlightHousing",
				Size = Vector3.new(1.4, 0.5, 0.08),
				CFrame = CFrame.new(x, y, z),
				Look = "Trim",
			})
			beamHost = Util.part(ctx, {
				Name = "Headlight",
				Size = Vector3.new(1.2, 0.34, 0.06),
				CFrame = CFrame.new(x, y, z - 0.05),
				Color = color,
				Look = "Neon",
				Transparency = 0.15,
			})
		elseif style == "AngelEyes" then
			for _, dx in { -0.35, 0.35 } do
				local cf = ctx.chassisCF * Util.facingFront(Vector3.new(x + dx, y, z - 0.05))
				Util.disc(ctx, cf, 0.28, 0.05, { Name = "AngelLens", Look = "Trim" })
				Util.ring(ctx, cf * CFrame.new(0.03, 0, 0), 0.26, 0.06, 0.04, 12, {
					Name = "AngelRing",
					Color = color,
					Look = "Neon",
				})
				beamHost = Util.disc(ctx, cf * CFrame.new(0.04, 0, 0), 0.1, 0.02, {
					Name = "Headlight",
					Color = color,
					Look = "Neon",
				})
			end
		elseif style == "LEDStrip" then
			Util.part(ctx, {
				Name = "ProjectorHousing",
				Size = Vector3.new(1.3, 0.3, 0.08),
				CFrame = CFrame.new(x, y - 0.12, z),
				Look = "Trim",
			})
			Util.disc(
				ctx,
				ctx.chassisCF * Util.facingFront(Vector3.new(x, y - 0.12, z - 0.05)),
				0.12,
				0.03,
				{ Name = "Projector", Color = color, Look = "Neon" }
			)
		elseif style == "QuadRound" then
			for _, dx in { -0.36, 0.36 } do
				local cf = ctx.chassisCF * Util.facingFront(Vector3.new(x + dx, y, z - 0.04))
				Util.disc(ctx, cf, 0.3, 0.06, { Name = "HeadlightBezel", Look = "Chrome" })
				beamHost = Util.disc(ctx, cf * CFrame.new(0.03, 0, 0), 0.24, 0.04, {
					Name = "Headlight",
					Color = color,
					Look = "Neon",
					Transparency = 0.1,
				})
			end
		elseif style == "PopUp" then
			local popY = ctx.noseTopY + 0.35
			local popZ = zF + 0.7
			Util.part(ctx, {
				Name = "PopUpPod",
				Size = Vector3.new(1.3, 0.55, 0.9),
				CFrame = CFrame.new(x, popY, popZ),
				Look = "Paint",
			})
			beamHost = Util.part(ctx, {
				Name = "Headlight",
				Size = Vector3.new(1.1, 0.4, 0.05),
				CFrame = CFrame.new(x, popY, popZ - 0.46),
				Color = color,
				Look = "Neon",
			})
			-- Slim signal where the fixed light would be.
			Util.part(ctx, {
				Name = "Signal",
				Size = Vector3.new(1.0, 0.12, 0.05),
				CFrame = CFrame.new(x, y, z),
				Color = Color3.fromRGB(255, 160, 40),
				Look = "Neon",
			})
		end
	end

	if style == "LEDStrip" then
		beamHost = Util.part(ctx, {
			Name = "Headlight",
			Size = Vector3.new(W * 0.86, 0.1, 0.06),
			CFrame = CFrame.new(0, y + 0.12, z - 0.05),
			Color = color,
			Look = "Neon",
		})
	end

	if beamHost then
		Util.light("SpotLight", beamHost, {
			Face = Enum.NormalId.Front,
			Color = color,
			Brightness = 3,
			Range = 26,
			Angle = 70,
			Shadows = false,
		})
		-- Discs are rotated so their local X points forward; retarget the light.
		if beamHost:IsA("Part") and beamHost.Shape == Enum.PartType.Cylinder then
			(beamHost:FindFirstChildOfClass("SpotLight") :: SpotLight).Face = Enum.NormalId.Right
		end
	end
end

-- Taillights --------------------------------------------------------------------------------------

local TAIL_RED = Color3.fromRGB(255, 24, 24)

local function taillights(ctx)
	local style = ctx.build.Taillights
	local W, c, h, zR = ctx.W, ctx.c, ctx.h, ctx.zR
	local y = c + h * 0.7
	local z = zR + 0.03

	if style == "LightBar" then
		Util.part(ctx, {
			Name = "TailBar",
			Size = Vector3.new(W * 0.92, 0.2, 0.06),
			CFrame = CFrame.new(0, y, z),
			Color = TAIL_RED,
			Look = "Neon",
		})
		return
	end

	for _, side in { -1, 1 } do
		local x = side * W * 0.33
		if style == "Stock" then
			Util.part(ctx, {
				Name = "Taillight",
				Size = Vector3.new(1.3, 0.42, 0.06),
				CFrame = CFrame.new(x, y, z),
				Color = TAIL_RED,
				Look = "Neon",
				Transparency = 0.1,
			})
		elseif style == "Smoked" then
			Util.part(ctx, {
				Name = "Taillight",
				Size = Vector3.new(1.3, 0.42, 0.06),
				CFrame = CFrame.new(x, y, z),
				Color = Color3.fromRGB(90, 4, 8),
				Look = "Neon",
			})
			Util.part(ctx, {
				Name = "SmokedLens",
				Size = Vector3.new(1.34, 0.46, 0.04),
				CFrame = CFrame.new(x, y, z + 0.05),
				Color = Color3.fromRGB(10, 10, 12),
				Material = Enum.Material.Glass,
				Transparency = 0.35,
			})
		elseif style == "RoundQuad" then
			for _, dx in { -0.35, 0.35 } do
				local cf = ctx.chassisCF * Util.facingRear(Vector3.new(x + dx, y, z))
				Util.disc(ctx, cf, 0.28, 0.05, { Name = "TailBezel", Look = "Chrome" })
				Util.disc(ctx, cf * CFrame.new(0.03, 0, 0), 0.22, 0.03, {
					Name = "Taillight",
					Color = TAIL_RED,
					Look = "Neon",
				})
			end
		elseif style == "TriBar" then
			for i = -1, 1 do
				Util.part(ctx, {
					Name = "Taillight",
					Size = Vector3.new(0.22, 0.55, 0.06),
					CFrame = CFrame.new(x + i * 0.38, y, z),
					Color = TAIL_RED,
					Look = "Neon",
				})
			end
		end
	end
end

-- Mirrors -------------------------------------------------------------------------------------------

local function mirrors(ctx)
	local style = ctx.build.Mirrors
	local W, yT = ctx.W, ctx.yT
	for _, side in { -1, 1 } do
		local hinge = if side < 0 then ctx.doorHingeL else ctx.doorHingeR
		local z = ctx.doorZ0 + 0.35
		local x = side * (W / 2 + 0.2)
		if style == "Stock" then
			Util.part(ctx, {
				Name = "MirrorStalk",
				Size = Vector3.new(0.4, 0.1, 0.18),
				CFrame = CFrame.new(x, yT + 0.2, z),
				Look = "Trim",
			}, hinge)
			Util.part(ctx, {
				Name = "Mirror",
				Size = Vector3.new(0.3, 0.38, 0.6),
				CFrame = CFrame.new(x + side * 0.3, yT + 0.3, z),
				Look = "Paint",
			}, hinge)
		elseif style == "Aero" then
			Util.part(ctx, {
				Name = "MirrorStalk",
				Size = Vector3.new(0.5, 0.06, 0.1),
				CFrame = CFrame.new(x + side * 0.05, yT + 0.25, z) * CFrame.Angles(0, 0, side * math.rad(15)),
				Look = "Carbon",
			}, hinge)
			Util.part(ctx, {
				Name = "Mirror",
				Class = "WedgePart",
				Size = Vector3.new(0.5, 0.28, 0.6),
				CFrame = CFrame.new(x + side * 0.35, yT + 0.38, z + 0.05),
				Look = "Paint",
			}, hinge)
		elseif style == "CarbonStalk" then
			for _, dz in { -0.12, 0.12 } do
				Util.part(ctx, {
					Name = "MirrorStalk",
					Size = Vector3.new(0.6, 0.05, 0.05),
					CFrame = CFrame.new(x + side * 0.1, yT + 0.22, z + dz) * CFrame.Angles(0, 0, side * math.rad(25)),
					Look = "Carbon",
				}, hinge)
			end
			Util.part(ctx, {
				Name = "Mirror",
				Size = Vector3.new(0.18, 0.28, 0.45),
				CFrame = CFrame.new(x + side * 0.4, yT + 0.36, z),
				Look = "Carbon",
			}, hinge)
		elseif style == "Fender" then
			local fz = ctx.zN + 0.9
			local fx = side * (W / 2 - 0.35)
			Util.part(ctx, {
				Name = "FenderMirrorPost",
				Size = Vector3.new(0.06, 0.5, 0.06),
				CFrame = CFrame.new(fx, yT + 0.45, fz),
				Look = "Chrome",
			})
			Util.part(ctx, {
				Name = "Mirror",
				Size = Vector3.new(0.3, 0.26, 0.2),
				CFrame = CFrame.new(fx, yT + 0.75, fz),
				Look = "Chrome",
			})
		elseif style == "Bullet" then
			Util.part(ctx, {
				Name = "MirrorStalk",
				Size = Vector3.new(0.35, 0.07, 0.07),
				CFrame = CFrame.new(x, yT + 0.22, z),
				Look = "Chrome",
			}, hinge)
			Util.part(ctx, {
				Name = "Mirror",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.42, 0.42, 0.42),
				CFrame = CFrame.new(x + side * 0.28, yT + 0.3, z),
				Look = "Chrome",
			}, hinge)
		end
	end
end

-- Per-car details -------------------------------------------------------------------------------------

local function carExtras(ctx)
	local extras = ctx.spec.Extras
	local W, c, h = ctx.W, ctx.c, ctx.h
	if table.find(extras, "SideIntakes") then
		for _, side in { -1, 1 } do
			local z = ctx.doorZ0 + ctx.doorLen + 0.6
			Util.part(ctx, {
				Name = "SideIntake",
				Size = Vector3.new(0.06, h * 0.45, 1.0),
				CFrame = CFrame.new(side * (W / 2 + 0.02), c + h * 0.55, z),
				Look = "Trim",
			})
		end
	end
	if table.find(extras, "ChromeTrim") then
		for _, side in { -1, 1 } do
			Util.part(ctx, {
				Name = "ChromeTrim",
				Size = Vector3.new(0.05, 0.08, ctx.L * 0.9),
				CFrame = CFrame.new(side * (W / 2 + 0.26), c + h * 0.62, 0),
				Look = "Chrome",
			})
		end
	end
end

function Kits.build(ctx)
	frontBumper(ctx)
	rearBumper(ctx)
	sideSkirts(ctx)
	spoiler(ctx)
	hoodExtras(ctx)
	roofExtras(ctx)
	arches(ctx)
	headlights(ctx)
	taillights(ctx)
	mirrors(ctx)
	carExtras(ctx)
end

return Kits
