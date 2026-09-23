-- Builds a complete, animatable car Model from a player's build table.
--
-- The model is one assembly: an anchored invisible Root with every other part
-- welded or Motor6D-jointed to it. Clients animate the Motor6Ds (doors, hood,
-- trunk, wheels, spinners, subwoofers, hydraulics) locally via CarAnimator,
-- driven by attributes on the model, so nothing is simulated by physics.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Util = require(script.Util)
local Body = require(script.Body)
local Kits = require(script.Kits)
local Wheels = require(script.Wheels)
local Extras = require(script.Extras)
local Vinyls = require(script.Vinyls)

local CarBuilder = {}

CarBuilder.Tag = "DressCar"

local RIDE_HEIGHT = {
	Stock = 0,
	Lowered = -0.3,
	Slammed = -0.55,
	Lifted = 0.9,
	Hydraulics = -0.35,
}

-- Multipliers on the base car's wheel radius / width, and rim radius as a
-- fraction of the tyre radius.
local TIRES = {
	Street = { Front = { 1, 1, 0.64 }, Rear = { 1, 1, 0.64 } },
	LowProfile = { Front = { 1, 1.1, 0.8 }, Rear = { 1, 1.1, 0.8 } },
	Offroad = { Front = { 1.18, 1.25, 0.58 }, Rear = { 1.18, 1.25, 0.58 } },
	Whitewall = { Front = { 1, 1, 0.6 }, Rear = { 1, 1, 0.6 } },
	DragSlicks = { Front = { 0.92, 0.75, 0.66 }, Rear = { 1.2, 1.6, 0.56 } },
}

export type BuildOptions = {
	OwnerUserId: number?,
	Name: string?,
}

local function computeLayout(ctx)
	local spec = ctx.spec
	local build = ctx.build

	local W = spec.Width + (if build.Widebody == "Full" then 0.9 else 0)
	local L = spec.Length
	ctx.W, ctx.L = W, L
	ctx.c, ctx.h = spec.Clearance, spec.BodyHeight
	ctx.yT = ctx.c + ctx.h
	ctx.zF, ctx.zR = -L / 2, L / 2
	ctx.zN = ctx.zF + spec.NoseLength
	ctx.zc0 = spec.CabinZ - spec.CabinLength / 2
	ctx.zc1 = spec.CabinZ + spec.CabinLength / 2
	ctx.zw0 = ctx.zc0 - spec.WindshieldLength
	ctx.zr1 = ctx.zc1 + spec.RearWindowLength
	ctx.cabinW = spec.Width * 0.84
	ctx.cabinH = spec.CabinHeight

	local tire = TIRES[build.Tires] or TIRES.Street
	local frontR = spec.WheelRadius * tire.Front[1]
	local rearR = spec.WheelRadius * tire.Rear[1]
	local frontW = spec.WheelWidth * tire.Front[2]
	ctx.frontR, ctx.rearR = frontR, rearR
	ctx.frontAxle, ctx.rearAxle = spec.FrontAxle, spec.RearAxle
	ctx.wheelW = frontW

	-- Bigger front tyres lift the body so they do not swallow the arches.
	ctx.rideOffset = (RIDE_HEIGHT[build.Suspension] or 0) + math.max(0, frontR - spec.WheelRadius)
	ctx.chassisCF = CFrame.new(0, ctx.rideOffset, 0)

	local flare = if build.Widebody == "Flares" then 0.28 else 0
	local function track(width: number): number
		return W / 2 - width * 0.22 + flare
	end
	ctx.trackX = track(frontW)

	ctx.wheelLayout = {}
	for _, def in
		{
			{ "WheelFL", -1, false },
			{ "WheelFR", 1, false },
			{ "WheelRL", -1, true },
			{ "WheelRR", 1, true },
		}
	do
		local rear = def[3]
		local dims = if rear then tire.Rear else tire.Front
		local R = spec.WheelRadius * dims[1]
		local width = spec.WheelWidth * dims[2]
		table.insert(ctx.wheelLayout, {
			Name = def[1],
			Side = def[2],
			Rear = rear,
			Z = if rear then spec.RearAxle else spec.FrontAxle,
			Radius = R,
			Width = width,
			RimRadius = R * dims[3],
			TrackX = track(width),
		})
	end

	-- Doors sit between the front wheel and the rear wheel.
	local doorZ0 = math.max(ctx.zc0 - spec.WindshieldLength * 0.5, spec.FrontAxle + frontR + 0.3)
	local doorLen = math.min(spec.CabinLength + spec.WindshieldLength * 0.4, 4.8, spec.RearAxle - rearR - 0.2 - doorZ0)
	ctx.doorZ0, ctx.doorLen = doorZ0, doorLen
end

local function resolveColors(build): { [string]: Color3 }
	local get = Catalog.GetColor
	return {
		Body = get(build.BodyColor),
		Caliper = get(build.CaliperColor),
		Engine = get(build.EngineColor),
		Rim = get(build.RimColor),
		Smoke = get(build.TireSmoke),
		Accent = get(build.AudioAccent),
		Underglow = get(build.UnderglowColor),
		Interior = get(build.InteriorColor),
		Headlight = get(build.HeadlightColor),
		Vinyl1 = get(build.Vinyl1Color),
		Vinyl2 = get(build.Vinyl2Color),
		Vinyl3 = get(build.Vinyl3Color),
	}
end

function CarBuilder.build(rawBuild: { [string]: any }?, options: BuildOptions?): Model
	local build = Catalog.Sanitize(rawBuild)
	local spec = Catalog.CarsById[build.Car] or Catalog.Cars[1]
	local ownerUserId = (options and options.OwnerUserId) or 0

	local ctx: Util.Ctx = {
		build = build,
		spec = spec,
		colors = resolveColors(build),
		sideSurfaces = {},
		topSurfaces = {},
		ownerSeed = math.abs(ownerUserId),
	}
	computeLayout(ctx)

	local model = Instance.new("Model")
	model.Name = (options and options.Name) or "Car"
	-- Cameras look at cars from far away (stage, other bays), so always stream them.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	ctx.model = model

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 0.2, 1)
	root.CFrame = CFrame.identity
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Parent = model
	model.PrimaryPart = root
	ctx.root = root

	local chassis = Util.pivot(ctx, "Chassis", ctx.chassisCF, true)
	Util.motor("Suspension", root, chassis)
	ctx.chassis = chassis

	Body.build(ctx)
	Wheels.build(ctx)
	Kits.build(ctx)
	Extras.build(ctx)
	Vinyls.build(ctx)

	model:SetAttribute("CarId", spec.Id)
	model:SetAttribute("CarName", spec.Name)
	model:SetAttribute("OwnerUserId", ownerUserId)
	model:SetAttribute("HasHydraulics", build.Suspension == "Hydraulics")
	model:SetAttribute("UnderglowMode", build.Underglow)
	model:SetAttribute("InteriorMode", build.InteriorNeon)
	model:SetAttribute("Length", ctx.L)
	CollectionService:AddTag(model, CarBuilder.Tag)

	return model
end

return CarBuilder
