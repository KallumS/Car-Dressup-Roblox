-- Low-level helpers used by every CarBuilder module: part creation, joints,
-- materials and a few primitive shapes (rings, spokes).
--
-- Coordinate conventions (the car is built at the origin, then moved):
--   * The Root part sits at CFrame.identity (ground level, car centre).
--   * The car faces -Z. +X is the car's right-hand side. y = 0 is the ground.
--   * "Chassis space" = Root space shifted up by the ride-height offset. Body
--     parts are specified in chassis space and welded to the Chassis part, which
--     hangs off Root via the "Suspension" Motor6D (animated for hydraulics).

local Util = {}

export type Ctx = { [string]: any }

Util.Carbon = Color3.fromRGB(26, 26, 30)
Util.Trim = Color3.fromRGB(22, 22, 25)
Util.ChromeColor = Color3.fromRGB(205, 208, 214)
Util.Rubber = Color3.fromRGB(28, 28, 30)

local FINISHES = {
	Gloss = { Material = Enum.Material.SmoothPlastic, Reflectance = 0.12 },
	Matte = { Material = Enum.Material.Plastic, Reflectance = 0 },
	Satin = { Material = Enum.Material.SmoothPlastic, Reflectance = 0.04 },
	Metallic = { Material = Enum.Material.Metal, Reflectance = 0.08 },
	Pearl = { Material = Enum.Material.SmoothPlastic, Reflectance = 0.28 },
	Chrome = { Material = Enum.Material.Foil, Reflectance = 0.45 },
}

local TINTS = {
	Clear = { Color = Color3.fromRGB(175, 195, 205), Transparency = 0.55 },
	Light = { Color = Color3.fromRGB(90, 100, 112), Transparency = 0.42 },
	Dark = { Color = Color3.fromRGB(36, 40, 46), Transparency = 0.28 },
	Limo = { Color = Color3.fromRGB(10, 10, 12), Transparency = 0.12 },
}

export type PartProps = {
	Name: string?,
	Class: string?, -- "Part" (default) or "WedgePart"
	Shape: Enum.PartType?,
	Size: Vector3,
	CFrame: CFrame, -- chassis space unless World = true
	World: boolean?, -- CFrame is already in root/world build space
	Color: Color3?,
	Material: Enum.Material?,
	Reflectance: number?,
	Transparency: number?,
	Look: string?, -- "Paint" | "Carbon" | "Chrome" | "Glass" | "Trim" | "Rubber" | "Neon"
	NoWeld: boolean?, -- caller will attach it with a Motor6D instead
}

-- Creates a part, positions it and welds it to `anchor` (defaults to Chassis).
function Util.part(ctx: Ctx, props: PartProps, anchor: BasePart?, parent: Instance?): BasePart
	local part: BasePart
	if props.Class == "WedgePart" then
		part = Instance.new("WedgePart")
	else
		local p = Instance.new("Part")
		if props.Shape then
			p.Shape = props.Shape
		end
		part = p
	end

	part.Name = props.Name or "Part"
	part.Size = props.Size
	part.CFrame = if props.World then props.CFrame else ctx.chassisCF * props.CFrame
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic

	local look = props.Look
	if look == "Paint" then
		Util.paint(ctx, part)
	elseif look == "Carbon" then
		part.Color = Util.Carbon
		part.Material = Enum.Material.Fabric
	elseif look == "Chrome" then
		part.Color = Util.ChromeColor
		part.Material = Enum.Material.Metal
		part.Reflectance = 0.45
	elseif look == "Glass" then
		local tint = TINTS[ctx.build.WindowTint] or TINTS.Light
		part.Color = tint.Color
		part.Material = Enum.Material.Glass
		part.Transparency = tint.Transparency
	elseif look == "Trim" then
		part.Color = Util.Trim
	elseif look == "Rubber" then
		part.Color = Util.Rubber
		part.Material = Enum.Material.Rubber
	elseif look == "Neon" then
		part.Material = Enum.Material.Neon
	end

	if props.Color then
		part.Color = props.Color
	end
	if props.Material then
		part.Material = props.Material
	end
	if props.Reflectance then
		part.Reflectance = props.Reflectance
	end
	if props.Transparency then
		part.Transparency = props.Transparency
	end

	local anchorPart = anchor or ctx.chassis
	if anchorPart and not props.NoWeld then
		Util.weld(anchorPart, part)
	end
	part.Parent = parent or ctx.currentParent or ctx.model
	return part
end

-- Applies the player's base coat + finish.
function Util.paint(ctx: Ctx, part: BasePart)
	local finish = FINISHES[ctx.build.Finish] or FINISHES.Gloss
	part.Color = ctx.colors.Body
	part.Material = finish.Material
	part.Reflectance = finish.Reflectance
end

-- Rigid weld that keeps the two parts' current relative offset.
function Util.weld(part0: BasePart, part1: BasePart): Weld
	local weld = Instance.new("Weld")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = part0.CFrame:Inverse() * part1.CFrame
	weld.C1 = CFrame.identity
	weld.Parent = part1
	return weld
end

-- Animatable joint. Transform rotates/moves Part1 about its own origin.
function Util.motor(name: string, part0: BasePart, part1: BasePart): Motor6D
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = part0.CFrame:Inverse() * part1.CFrame
	motor.C1 = CFrame.identity
	motor.Parent = part1
	return motor
end

-- Invisible helper part used as a hinge / hub pivot.
function Util.pivot(ctx: Ctx, name: string, cf: CFrame, world: boolean?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = if world then cf else ctx.chassisCF * cf
	p.Transparency = 1
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.Parent = ctx.currentParent or ctx.model
	return p
end

-- A ring of `count` block segments around the X axis of `baseCF` (world space).
-- Used for rim lips, whitewalls, angel eyes and wheel arches.
function Util.ring(
	ctx: Ctx,
	baseCF: CFrame,
	radius: number,
	radialWidth: number,
	thickness: number,
	count: number,
	props: { [string]: any },
	anchor: BasePart?,
	fromAngle: number?,
	toAngle: number?
): { BasePart }
	local parts = {}
	local a0 = fromAngle or 0
	local a1 = toAngle or math.pi * 2
	local full = (fromAngle == nil and toAngle == nil)
	local steps = if full then count else count - 1
	local segLen = (a1 - a0) * radius / math.max(steps, 1) * 1.08
	for i = 0, count - 1 do
		local angle = a0 + (a1 - a0) * (i / math.max(steps, 1))
		local cf = baseCF * CFrame.Angles(angle, 0, 0) * CFrame.new(0, radius, 0)
		local segProps = table.clone(props)
		segProps.Size = Vector3.new(thickness, radialWidth, math.max(segLen, 0.05))
		segProps.CFrame = cf
		segProps.World = true
		table.insert(parts, Util.part(ctx, segProps :: any, anchor))
	end
	return parts
end

-- A radial bar from `inner` to `outer` radius at `angle` around baseCF's X axis.
function Util.spoke(
	ctx: Ctx,
	baseCF: CFrame,
	angle: number,
	inner: number,
	outer: number,
	width: number,
	thickness: number,
	props: { [string]: any },
	anchor: BasePart?
): BasePart
	local len = outer - inner
	local cf = baseCF * CFrame.Angles(angle, 0, 0) * CFrame.new(0, inner + len / 2, 0)
	local spokeProps = table.clone(props)
	spokeProps.Size = Vector3.new(thickness, len, width)
	spokeProps.CFrame = cf
	spokeProps.World = true
	return Util.part(ctx, spokeProps :: any, anchor)
end

-- A disc whose flat faces point along baseCF's X axis.
function Util.disc(
	ctx: Ctx,
	baseCF: CFrame,
	radius: number,
	thickness: number,
	props: { [string]: any },
	anchor: BasePart?
): BasePart
	local discProps = table.clone(props)
	discProps.Shape = Enum.PartType.Cylinder
	discProps.Size = Vector3.new(thickness, radius * 2, radius * 2)
	discProps.CFrame = baseCF
	discProps.World = true
	return Util.part(ctx, discProps :: any, anchor)
end

-- CFrame whose X axis points toward the car's front (-Z). Useful for round
-- lights / exhaust tips built with `disc`.
function Util.facingFront(position: Vector3): CFrame
	return CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0)
end

-- CFrame whose X axis points toward the car's rear (+Z).
function Util.facingRear(position: Vector3): CFrame
	return CFrame.new(position) * CFrame.Angles(0, math.rad(-90), 0)
end

-- CFrame whose X axis points up (+Y).
function Util.facingUp(position: Vector3): CFrame
	return CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
end

function Util.light(className: string, parent: Instance, props: { [string]: any }): Light
	local light = Instance.new(className) :: Light
	for key, value in props do
		(light :: any)[key] = value
	end
	light.Parent = parent
	return light
end

-- Picks black or white text for readability on top of `color`.
function Util.contrast(color: Color3): Color3
	local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return if luminance > 0.55 then Color3.new(0.05, 0.05, 0.05) else Color3.new(1, 1, 1)
end

return Util
