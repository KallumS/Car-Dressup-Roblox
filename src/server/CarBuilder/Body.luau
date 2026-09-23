-- Body shell: nose, engine bay, cabin section, trunk tub, glasshouse, roof,
-- opening hood / trunk / doors and a simple interior.
--
-- Registers the paintable side panels (for vinyls) and top panels (for racing
-- stripes) on ctx.sideSurfaces / ctx.topSurfaces.

local Util = require(script.Parent.Util)

local Body = {}

local function addSide(ctx, part: BasePart, side: number, z0: number, z1: number, y0: number, y1: number)
	table.insert(ctx.sideSurfaces, { Part = part, Side = side, Z0 = z0, Z1 = z1, Y0 = y0, Y1 = y1 })
end

local function addTop(ctx, cf: CFrame, length: number, width: number, anchor: BasePart)
	table.insert(ctx.topSurfaces, { CFrame = ctx.chassisCF * cf, Length = length, Width = width, Anchor = anchor })
end

-- Open-angle presets per door style: hinge position + rotation (degrees).
-- RX pitches (negative lifts the rear edge), RY swings, RZ rolls outward.
local function doorHinge(ctx, style: string, side: number): (CFrame, number, number, number)
	local W, c, h = ctx.W, ctx.c, ctx.h
	local x = side * (W / 2 + 0.12)
	local z0 = ctx.doorZ0
	if style == "Scissor" then
		return CFrame.new(x, c + h * 0.5, z0), -72, 0, 0
	elseif style == "Lambo" then
		return CFrame.new(x, c + h * 0.5, z0), -70, side * 22, 0
	elseif style == "Butterfly" then
		return CFrame.new(x, ctx.yT, z0), -55, 0, side * 40
	elseif style == "Gullwing" then
		return CFrame.new(side * ctx.cabinW * 0.3, ctx.yT + ctx.cabinH, z0 + ctx.doorLen / 2), 0, 0, side * 75
	end
	-- Stock: swings outward around a vertical hinge at the front edge.
	return CFrame.new(x, c + h * 0.5, z0), 0, side * 62, 0
end

local function tagHinge(motor: Motor6D, kind: string, rx: number, ry: number, rz: number)
	motor:SetAttribute("Kind", kind)
	motor:SetAttribute("RX", rx)
	motor:SetAttribute("RY", ry)
	motor:SetAttribute("RZ", rz)
end

function Body.build(ctx)
	local W, c, h = ctx.W, ctx.c, ctx.h
	local yT = ctx.yT
	local zF, zN, zw0, zc0, zc1, zr1, zR = ctx.zF, ctx.zN, ctx.zw0, ctx.zc0, ctx.zc1, ctx.zr1, ctx.zR
	local spec = ctx.spec
	local cabinW, cabinH = ctx.cabinW, ctx.cabinH

	-- Nose: lower box + sloped wedge on top ------------------------------------
	local noseLen = zN - zF
	local hN = h * spec.NoseBoxRatio
	local noseBox = Util.part(ctx, {
		Name = "NoseBox",
		Size = Vector3.new(W, hN, noseLen),
		CFrame = CFrame.new(0, c + hN / 2, zF + noseLen / 2),
		Look = "Paint",
	})
	addSide(ctx, noseBox, -1, zF, zN, c, c + hN)
	addSide(ctx, noseBox, 1, zF, zN, c, c + hN)

	local slopeH = h - hN
	Util.part(ctx, {
		Name = "NoseSlope",
		Class = "WedgePart",
		Size = Vector3.new(W, slopeH, noseLen),
		CFrame = CFrame.new(0, c + hN + slopeH / 2, zF + noseLen / 2),
		Look = "Paint",
	})
	local slopeAngle = math.atan2(slopeH, noseLen)
	local slopeLen = math.sqrt(slopeH * slopeH + noseLen * noseLen)
	addTop(
		ctx,
		CFrame.new(0, c + hN + slopeH / 2, zF + noseLen / 2) * CFrame.Angles(-slopeAngle, 0, 0),
		slopeLen,
		W,
		ctx.chassis
	)
	ctx.noseTopY = c + hN
	ctx.noseBoxHeight = hN

	-- Engine bay tub -------------------------------------------------------------
	local bayLen = zw0 - zN
	local bayMid = (zN + zw0) / 2
	Util.part(ctx, {
		Name = "BayFloor",
		Size = Vector3.new(W, h * 0.3, bayLen),
		CFrame = CFrame.new(0, c + h * 0.15, bayMid),
		Look = "Trim",
	})
	for _, side in { -1, 1 } do
		local wall = Util.part(ctx, {
			Name = "BayWall",
			Size = Vector3.new(0.25, h, bayLen),
			CFrame = CFrame.new(side * (W / 2 - 0.125), c + h / 2, bayMid),
			Look = "Paint",
		})
		addSide(ctx, wall, side, zN, zw0, c, yT)
	end
	ctx.bayFloorY = c + h * 0.3
	ctx.bayLen = bayLen
	ctx.bayMid = bayMid

	-- Hood (hinged at the windshield end)
	local hoodHinge = Util.pivot(ctx, "HoodHinge", CFrame.new(0, yT + 0.1, zw0))
	local hoodMotor = Util.motor("Hinge", ctx.chassis, hoodHinge)
	local hoodOpen = if ctx.build.Hood == "Blower" then 0 else 55
	tagHinge(hoodMotor, "Hood", hoodOpen, 0, 0)
	local hood = Util.part(ctx, {
		Name = "Hood",
		Size = Vector3.new(W - 0.04, 0.2, bayLen),
		CFrame = CFrame.new(0, yT + 0.1, bayMid),
		Look = if ctx.build.Hood == "Carbon" then "Carbon" else "Paint",
	}, hoodHinge)
	ctx.hoodHinge = hoodHinge
	ctx.hood = hood
	if ctx.build.Hood ~= "Carbon" then
		addTop(ctx, CFrame.new(0, yT + 0.2, bayMid), bayLen, W, hoodHinge)
	end

	-- Cabin section (solid lower body under the glasshouse) --------------------
	local secLen = zr1 - zw0
	local section = Util.part(ctx, {
		Name = "CabinSection",
		Size = Vector3.new(W, h, secLen),
		CFrame = CFrame.new(0, c + h / 2, (zw0 + zr1) / 2),
		Look = "Paint",
	})
	addSide(ctx, section, -1, zw0, zr1, c, yT)
	addSide(ctx, section, 1, zw0, zr1, c, yT)

	-- Trunk tub ------------------------------------------------------------------
	local trunkLen = zR - zr1
	local trunkMid = (zr1 + zR) / 2
	Util.part(ctx, {
		Name = "TrunkFloor",
		Size = Vector3.new(W, h * 0.35, trunkLen),
		CFrame = CFrame.new(0, c + h * 0.175, trunkMid),
		Color = Color3.fromRGB(30, 30, 34),
		Material = Enum.Material.Fabric,
	})
	for _, side in { -1, 1 } do
		local wall = Util.part(ctx, {
			Name = "TrunkWall",
			Size = Vector3.new(0.25, h, trunkLen),
			CFrame = CFrame.new(side * (W / 2 - 0.125), c + h / 2, trunkMid),
			Look = "Paint",
		})
		addSide(ctx, wall, side, zr1, zR, c, yT)
	end
	Util.part(ctx, {
		Name = "TrunkBackWall",
		Size = Vector3.new(W - 0.5, h, 0.25),
		CFrame = CFrame.new(0, c + h / 2, zR - 0.125),
		Look = "Paint",
	})
	ctx.trunkFloorY = c + h * 0.35
	ctx.trunkLen = trunkLen
	ctx.trunkMid = trunkMid

	local trunkHinge = Util.pivot(ctx, "TrunkHinge", CFrame.new(0, yT + 0.1, zr1))
	local trunkMotor = Util.motor("Hinge", ctx.chassis, trunkHinge)
	tagHinge(trunkMotor, "Trunk", -70, 0, 0)
	Util.part(ctx, {
		Name = "TrunkLid",
		Size = Vector3.new(W - 0.04, 0.2, trunkLen),
		CFrame = CFrame.new(0, yT + 0.1, trunkMid),
		Look = "Paint",
	}, trunkHinge)
	addTop(ctx, CFrame.new(0, yT + 0.2, trunkMid), trunkLen, W, trunkHinge)
	ctx.trunkHinge = trunkHinge

	-- Glasshouse -------------------------------------------------------------------
	local cabinLen = zc1 - zc0
	local cabinMidY = yT + cabinH / 2
	Util.part(ctx, {
		Name = "CabinGlass",
		Size = Vector3.new(cabinW, cabinH, cabinLen),
		CFrame = CFrame.new(0, cabinMidY, (zc0 + zc1) / 2),
		Look = "Glass",
	})
	Util.part(ctx, {
		Name = "Windshield",
		Class = "WedgePart",
		Size = Vector3.new(cabinW, cabinH, zc0 - zw0),
		CFrame = CFrame.new(0, cabinMidY, (zw0 + zc0) / 2),
		Look = "Glass",
	})
	Util.part(ctx, {
		Name = "RearWindow",
		Class = "WedgePart",
		Size = Vector3.new(cabinW, cabinH, zr1 - zc1),
		CFrame = CFrame.new(0, cabinMidY, (zc1 + zr1) / 2) * CFrame.Angles(0, math.pi, 0),
		Look = "Glass",
	})
	local roofY = yT + cabinH + 0.1
	Util.part(ctx, {
		Name = "Roof",
		Size = Vector3.new(cabinW + 0.1, 0.2, cabinLen + 0.1),
		CFrame = CFrame.new(0, roofY, (zc0 + zc1) / 2),
		Look = "Paint",
	})
	addTop(ctx, CFrame.new(0, roofY + 0.1, (zc0 + zc1) / 2), cabinLen, cabinW, ctx.chassis)
	ctx.roofTopY = roofY + 0.1
	-- B-pillars
	for _, side in { -1, 1 } do
		Util.part(ctx, {
			Name = "Pillar",
			Size = Vector3.new(0.14, cabinH, 0.3),
			CFrame = CFrame.new(side * (cabinW / 2 + 0.01), cabinMidY, zc1 - 0.2),
			Look = "Paint",
		})
	end

	-- Interior -----------------------------------------------------------------------
	local seatZ = (zc0 + zc1) / 2 + 0.2
	for _, side in { -1, 1 } do
		local x = side * cabinW * 0.23
		Util.part(ctx, {
			Name = "SeatBase",
			Size = Vector3.new(1.1, 0.35, 1.2),
			CFrame = CFrame.new(x, yT + 0.18, seatZ),
			Color = Color3.fromRGB(35, 35, 38),
			Material = Enum.Material.Fabric,
		})
		Util.part(ctx, {
			Name = "SeatBack",
			Size = Vector3.new(1.1, math.min(1.4, cabinH * 0.75), 0.3),
			CFrame = CFrame.new(x, yT + 0.35 + math.min(1.4, cabinH * 0.75) / 2, seatZ + 0.7) * CFrame.Angles(
				math.rad(-10),
				0,
				0
			),
			Color = Color3.fromRGB(35, 35, 38),
			Material = Enum.Material.Fabric,
		})
	end
	Util.part(ctx, {
		Name = "Dash",
		Size = Vector3.new(cabinW - 0.1, 0.5, 0.7),
		CFrame = CFrame.new(0, yT + 0.4, zc0 + 0.1),
		Look = "Trim",
	})
	Util.disc(ctx, ctx.chassisCF * CFrame.new(-cabinW * 0.23, yT + 0.75, zc0 + 0.7) * CFrame.Angles(
		0,
		math.rad(-90),
		0
	) * CFrame.Angles(0, 0, math.rad(20)), 0.4, 0.1, { Name = "SteeringWheel", Look = "Trim" })
	ctx.seatZ = seatZ

	-- Doors ----------------------------------------------------------------------------
	local style = ctx.build.Doors
	for _, side in { -1, 1 } do
		local hingeCF, rx, ry, rz = doorHinge(ctx, style, side)
		local hinge = Util.pivot(ctx, if side < 0 then "DoorHingeL" else "DoorHingeR", hingeCF)
		local motor = Util.motor("Hinge", ctx.chassis, hinge)
		tagHinge(motor, "Door", rx, ry, rz)

		local z0, dl = ctx.doorZ0, ctx.doorLen
		local panel = Util.part(ctx, {
			Name = "DoorPanel",
			Size = Vector3.new(0.22, h * 0.9, dl),
			CFrame = CFrame.new(side * (W / 2 + 0.12), c + h * 0.5, z0 + dl / 2),
			Look = "Paint",
		}, hinge)
		addSide(ctx, panel, side, z0, z0 + dl, c + h * 0.05, c + h * 0.95)

		Util.part(ctx, {
			Name = "DoorWindow",
			Size = Vector3.new(0.12, cabinH * 0.85, dl * 0.8),
			CFrame = CFrame.new(side * (cabinW / 2 + 0.08), yT + cabinH * 0.45, z0 + dl * 0.55),
			Look = "Glass",
		}, hinge)
		Util.part(ctx, {
			Name = "DoorHandle",
			Size = Vector3.new(0.08, 0.14, 0.55),
			CFrame = CFrame.new(side * (W / 2 + 0.26), c + h * 0.72, z0 + dl * 0.78),
			Look = "Chrome",
		}, hinge)
		if side < 0 then
			ctx.doorHingeL = hinge
		else
			ctx.doorHingeR = hinge
		end
	end
end

return Body
