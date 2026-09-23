-- Things that live inside or under the car: engine, trunk audio build,
-- hydraulic pumps, underglow and interior neon.

local Util = require(script.Parent.Util)

local Extras = {}

local function engine(ctx)
	local W = ctx.W
	local floorY = ctx.bayFloorY
	local len = ctx.bayLen
	if len < 1.4 then
		return -- supercar frunk: engine lives behind the cabin, out of sight
	end
	local mid = ctx.bayMid
	local blockH = math.min(ctx.h * 0.55, ctx.yT - floorY - 0.1)
	Util.part(ctx, {
		Name = "EngineBlock",
		Size = Vector3.new(W * 0.42, blockH, len * 0.7),
		CFrame = CFrame.new(0, floorY + blockH / 2, mid),
		Color = Color3.fromRGB(55, 55, 60),
		Material = Enum.Material.Metal,
	})
	for _, side in { -1, 1 } do
		Util.part(ctx, {
			Name = "ValveCover",
			Size = Vector3.new(W * 0.12, 0.25, len * 0.62),
			CFrame = CFrame.new(side * W * 0.13, floorY + blockH + 0.05, mid),
			Color = ctx.colors.Engine,
			Material = Enum.Material.Metal,
			Reflectance = 0.2,
		})
	end
	if ctx.build.Hood ~= "Blower" then
		Util.disc(ctx, ctx.chassisCF * Util.facingUp(Vector3.new(0, floorY + blockH + 0.1, mid)), 0.55, 0.22, {
			Name = "AirFilter",
			Look = "Chrome",
		})
	end
	for _, side in { -1, 1 } do
		Util.part(ctx, {
			Name = "StrutBrace",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(W * 0.35, 0.12, 0.12),
			CFrame = CFrame.new(side * W * 0.25, ctx.yT - 0.12, mid + len * 0.35),
			Color = ctx.colors.Engine,
			Material = Enum.Material.Metal,
		})
	end
end

-- Lays out `count` subwoofers in one row facing up inside the trunk.
local function subwoofers(ctx, count: number, accent: Color3)
	local floorY = ctx.trunkFloorY
	local innerW = ctx.W - 0.7
	local innerL = ctx.trunkLen - 0.45
	local mid = ctx.trunkMid - 0.1
	local radius = math.min(0.62, (innerW - 0.25 * (count + 1)) / (2 * count), innerL / 2 - 0.1)
	local boxH = math.min(0.75, ctx.yT - floorY - 0.45)

	Util.part(ctx, {
		Name = "SubBox",
		Size = Vector3.new(math.min(innerW, count * (radius * 2 + 0.3) + 0.2), boxH, radius * 2 + 0.3),
		CFrame = CFrame.new(0, floorY + boxH / 2, mid),
		Color = Color3.fromRGB(28, 28, 32),
		Material = Enum.Material.Fabric,
	})
	local topY = floorY + boxH
	for i = 1, count do
		local x = (i - (count + 1) / 2) * (radius * 2 + 0.3)
		local base = ctx.chassisCF * Util.facingUp(Vector3.new(x, topY + 0.02, mid))
		Util.disc(ctx, base, radius, 0.04, { Name = "SubSurround", Color = Color3.fromRGB(15, 15, 16) })
		Util.ring(ctx, base * CFrame.new(0.03, 0, 0), radius * 0.98, 0.07, 0.04, 16, {
			Name = "SubTrim",
			Color = accent,
			Material = Enum.Material.Metal,
			Reflectance = 0.2,
		})
		-- The cone rides on its own motor so the client can pump it to the beat.
		local cone = Util.part(ctx, {
			Name = "SubCone",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.06, radius * 1.5, radius * 1.5),
			CFrame = base * CFrame.new(0.06, 0, 0),
			World = true,
			Color = Color3.fromRGB(50, 50, 55),
			NoWeld = true,
		})
		Util.motor("SubCone", ctx.chassis, cone)
		Util.disc(ctx, base * CFrame.new(0.1, 0, 0), radius * 0.3, 0.05, {
			Name = "DustCap",
			Color = accent,
			Material = Enum.Material.Metal,
			Reflectance = 0.25,
		}, cone)
	end
end

-- Amplifiers are mounted under the trunk lid and revealed when it opens.
local function amps(ctx, count: number, accent: Color3)
	local lidBottom = ctx.yT
	local len = ctx.trunkLen
	local mid = ctx.trunkMid
	local ampW = math.min(1.5, (ctx.W - 0.8) / count - 0.2)
	for i = 1, count do
		local x = (i - (count + 1) / 2) * (ampW + 0.2)
		local amp = Util.part(ctx, {
			Name = "Amp",
			Size = Vector3.new(ampW, 0.22, math.min(1.0, len * 0.6)),
			CFrame = CFrame.new(x, lidBottom - 0.11, mid),
			Color = accent,
			Material = Enum.Material.Metal,
			Reflectance = 0.2,
		}, ctx.trunkHinge)
		Util.part(ctx, {
			Name = "AmpGlow",
			Size = Vector3.new(ampW * 0.8, 0.03, 0.08),
			CFrame = CFrame.new(x, lidBottom - 0.235, mid - 0.25),
			Color = accent,
			Look = "Neon",
		}, amp)
		for f = -2, 2 do
			Util.part(ctx, {
				Name = "HeatSink",
				Size = Vector3.new(ampW * 0.9, 0.04, 0.04),
				CFrame = CFrame.new(x, lidBottom - 0.235, mid + f * 0.1 + 0.1),
				Look = "Trim",
			}, amp)
		end
	end
end

local function trunkNeon(ctx, accent: Color3)
	local y = ctx.trunkFloorY + 0.05
	for _, side in { -1, 1 } do
		Util.part(ctx, {
			Name = "TrunkNeon",
			Size = Vector3.new(0.06, 0.06, ctx.trunkLen - 0.4),
			CFrame = CFrame.new(side * (ctx.W / 2 - 0.3), y, ctx.trunkMid),
			Color = accent,
			Look = "Neon",
		})
	end
	local glowHost = Util.part(ctx, {
		Name = "TrunkNeon",
		Size = Vector3.new(ctx.W - 0.8, 0.06, 0.06),
		CFrame = CFrame.new(0, y, ctx.zR - 0.35),
		Color = accent,
		Look = "Neon",
	})
	Util.light("PointLight", glowHost, { Color = accent, Brightness = 2, Range = 7, Shadows = false })
end

local function audio(ctx)
	local style = ctx.build.Trunk
	local accent = ctx.colors.Accent
	if style == "SingleSub" then
		subwoofers(ctx, 1, accent)
	elseif style == "DualSubs" then
		subwoofers(ctx, 2, accent)
		amps(ctx, 1, accent)
	elseif style == "AmpRack" then
		subwoofers(ctx, 2, accent)
		amps(ctx, 2, accent)
		trunkNeon(ctx, accent)
	elseif style == "SubWall" then
		subwoofers(ctx, 4, accent)
		amps(ctx, 3, accent)
		trunkNeon(ctx, accent)
	end
end

local function hydraulics(ctx)
	if ctx.build.Suspension ~= "Hydraulics" then
		return
	end
	-- Chrome pumps + battery bank tucked at the front of the trunk.
	local floorY = ctx.trunkFloorY
	local z = ctx.zr1 + 0.35
	for _, side in { -1, 1 } do
		Util.part(ctx, {
			Name = "HydraulicPump",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.9, 0.34, 0.34),
			CFrame = CFrame.new(side * (ctx.W / 2 - 0.55), floorY + 0.45, z) * CFrame.Angles(0, 0, math.rad(90)),
			Look = "Chrome",
		})
	end
	Util.part(ctx, {
		Name = "Batteries",
		Size = Vector3.new(ctx.W * 0.35, 0.35, 0.4),
		CFrame = CFrame.new(0, floorY + 0.18, z),
		Color = Color3.fromRGB(20, 20, 22),
	})
end

local function underglow(ctx)
	local mode = ctx.build.Underglow
	if mode == "Off" then
		return
	end
	local color = ctx.colors.Underglow
	local y = ctx.c - 0.06
	local W, L = ctx.W, ctx.L
	for _, side in { -1, 1 } do
		Util.part(ctx, {
			Name = "UnderglowStrip",
			Size = Vector3.new(0.12, 0.08, L * 0.62),
			CFrame = CFrame.new(side * (W / 2 - 0.35), y, 0),
			Color = color,
			Look = "Neon",
		})
	end
	for _, z in { ctx.zF + 1.2, ctx.zR - 1.2 } do
		Util.part(ctx, {
			Name = "UnderglowStrip",
			Size = Vector3.new(W * 0.7, 0.08, 0.12),
			CFrame = CFrame.new(0, y, z),
			Color = color,
			Look = "Neon",
		})
	end
	for _, z in { -L * 0.25, L * 0.25 } do
		local host = Util.part(ctx, {
			Name = "UnderglowLight",
			Size = Vector3.new(0.2, 0.2, 0.2),
			CFrame = CFrame.new(0, math.max(0.25 - ctx.rideOffset, y - 0.3), z),
			Transparency = 1,
		})
		local light = Util.light("PointLight", host, {
			Color = color,
			Brightness = 4,
			Range = 11,
			Shadows = false,
		})
		light:SetAttribute("PulseGroup", "Underglow")
	end
end

local function interiorNeon(ctx)
	local mode = ctx.build.InteriorNeon
	if mode == "Off" then
		return
	end
	local color = ctx.colors.Interior
	local yT = ctx.yT
	for _, side in { -1, 1 } do
		Util.part(ctx, {
			Name = "InteriorNeon",
			Size = Vector3.new(0.06, 0.06, ctx.zc1 - ctx.zc0 - 0.4),
			CFrame = CFrame.new(side * (ctx.cabinW / 2 - 0.15), yT + 0.05, (ctx.zc0 + ctx.zc1) / 2),
			Color = color,
			Look = "Neon",
		})
	end
	Util.part(ctx, {
		Name = "InteriorNeon",
		Size = Vector3.new(ctx.cabinW - 0.3, 0.05, 0.05),
		CFrame = CFrame.new(0, yT + 0.16, ctx.zc0 + 0.46),
		Color = color,
		Look = "Neon",
	})
	local host = Util.part(ctx, {
		Name = "InteriorLight",
		Size = Vector3.new(0.2, 0.2, 0.2),
		CFrame = CFrame.new(0, yT + ctx.cabinH * 0.6, ctx.seatZ),
		Transparency = 1,
	})
	local light = Util.light("PointLight", host, { Color = color, Brightness = 3, Range = 6, Shadows = false })
	light:SetAttribute("PulseGroup", "Interior")
end

function Extras.build(ctx)
	engine(ctx)
	audio(ctx)
	hydraulics(ctx)
	underglow(ctx)
	interiorNeon(ctx)
end

return Extras
