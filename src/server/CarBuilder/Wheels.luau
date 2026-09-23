-- Wheels: tyres, rims (incl. spinners), brake rotors/calipers and tyre smoke.
--
-- Each wheel hangs off Root through a "Wheel" Motor6D whose origin is the axle
-- centre, so the client can roll it by rotating Transform about X. Brakes are
-- welded to Root so they stay still while the wheel turns.

local Util = require(script.Parent.Util)

local Wheels = {}

local BARREL = Color3.fromRGB(38, 38, 42)
local ROTOR = Color3.fromRGB(125, 125, 130)

local function rimProps(ctx)
	return { Name = "Rim", Color = ctx.colors.Rim, Material = Enum.Material.Metal, Reflectance = 0.25 }
end

-- `face` is a world CFrame at the tyre's outer face whose +X points outward.
local function buildRim(ctx, style: string, face: CFrame, rimR: number, hub: BasePart)
	local props = rimProps(ctx)
	local trim = { Name = "RimDetail", Look = "Trim" }
	local function out(d: number): CFrame
		return face * CFrame.new(d, 0, 0)
	end
	local function cap(d: number)
		Util.disc(ctx, out(d), rimR * 0.18, 0.08, props, hub)
	end

	if style == "Stock" then
		for i = 0, 5 do
			Util.spoke(ctx, out(0.16), i * math.pi / 3, rimR * 0.15, rimR * 0.95, rimR * 0.34, 0.08, props, hub)
		end
		Util.ring(ctx, out(0.16), rimR * 0.95, 0.1, 0.1, 16, props, hub)
		cap(0.2)
	elseif style == "FiveSpoke" or style == "Spinners" then
		for i = 0, 4 do
			Util.spoke(ctx, out(0.16), i * math.pi * 2 / 5, rimR * 0.15, rimR * 0.95, rimR * 0.24, 0.08, props, hub)
		end
		Util.ring(ctx, out(0.16), rimR * 0.95, 0.12, 0.1, 16, props, hub)
		cap(0.2)
		if style == "Spinners" then
			local spinRoot = Util.pivot(ctx, "SpinnerRoot", out(0.3), true)
			Util.motor("Spinner", hub, spinRoot)
			local chrome = { Name = "Spinner", Look = "Chrome" }
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3
				-- Two offset segments per blade give a swept, curved look.
				Util.spoke(ctx, out(0.3), a, rimR * 0.12, rimR * 0.6, rimR * 0.2, 0.05, chrome, spinRoot)
				Util.spoke(ctx, out(0.3), a + 0.35, rimR * 0.5, rimR * 0.98, rimR * 0.18, 0.05, chrome, spinRoot)
			end
			Util.disc(ctx, out(0.33), rimR * 0.22, 0.06, chrome, spinRoot)
		end
	elseif style == "DeepDish" then
		Util.ring(ctx, out(0.2), rimR * 0.86, rimR * 0.3, 0.12, 20, {
			Name = "Lip",
			Look = "Chrome",
		}, hub)
		for i = 0, 7 do
			Util.spoke(ctx, out(0.08), i * math.pi / 4, rimR * 0.1, rimR * 0.72, rimR * 0.12, 0.06, props, hub)
		end
		cap(0.12)
	elseif style == "Mesh" then
		for i = 0, 9 do
			Util.spoke(ctx, out(0.15), i * math.pi / 5, 0, rimR * 0.95, 0.07, 0.05, props, hub)
			Util.spoke(ctx, out(0.17), i * math.pi / 5 + math.pi / 10, 0, rimR * 0.95, 0.07, 0.05, props, hub)
		end
		Util.ring(ctx, out(0.17), rimR * 0.95, 0.12, 0.1, 16, props, hub)
		cap(0.21)
	elseif style == "Turbofan" then
		Util.disc(ctx, out(0.14), rimR * 0.92, 0.06, props, hub)
		for i = 0, 13 do
			Util.spoke(ctx, out(0.18), i * math.pi / 7, rimR * 0.3, rimR * 0.85, 0.07, 0.03, trim, hub)
		end
		cap(0.21)
	elseif style == "Beadlock" then
		Util.disc(ctx, out(0.12), rimR * 0.9, 0.06, props, hub)
		for i = 0, 7 do
			local a = i * math.pi / 4
			Util.disc(ctx, out(0.15) * CFrame.Angles(a, 0, 0) * CFrame.new(0, rimR * 0.55, 0), rimR * 0.13, 0.02, trim, hub)
		end
		Util.ring(ctx, out(0.16), rimR * 0.94, 0.16, 0.1, 16, { Name = "Beadlock", Look = "Trim" }, hub)
		for i = 0, 11 do
			local a = i * math.pi / 6
			Util.disc(ctx, out(0.22) * CFrame.Angles(a, 0, 0) * CFrame.new(0, rimR * 0.94, 0), 0.05, 0.05, {
				Name = "Bolt",
				Look = "Chrome",
			}, hub)
		end
		cap(0.2)
	end
end

function Wheels.build(ctx)
	local root = ctx.root
	local tires = ctx.build.Tires
	local rimStyle = ctx.build.Rims

	for _, info in ctx.wheelLayout do
		local side, z, R, ww, rimR = info.Side, info.Z, info.Radius, info.Width, info.RimRadius
		local x = side * info.TrackX
		local wheelModel = Instance.new("Model")
		wheelModel.Name = info.Name
		wheelModel.Parent = ctx.model

		local hubCF = CFrame.new(x, R, z)
		ctx.currentParent = wheelModel
		local hub = Util.pivot(ctx, "Hub", hubCF, true)
		local motor = Util.motor("Wheel", root, hub)
		motor:SetAttribute("Rear", info.Rear)

		-- Tyre
		Util.part(ctx, {
			Name = "Tire",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(ww, R * 2, R * 2),
			CFrame = hubCF,
			World = true,
			Look = "Rubber",
		}, hub)

		-- Outer face, +X pointing away from the car.
		local face = hubCF * CFrame.new(side * ww / 2, 0, 0) * (if side < 0 then CFrame.Angles(0, math.pi, 0) else CFrame.identity)

		if tires == "Offroad" then
			for i = 0, 15 do
				local a = i * math.pi / 8
				local offset = if i % 2 == 0 then 0.12 else -0.12
				Util.part(ctx, {
					Name = "Tread",
					Size = Vector3.new(ww * 0.8, 0.2, 0.42),
					CFrame = hubCF * CFrame.new(offset, 0, 0) * CFrame.Angles(a, 0, 0) * CFrame.new(0, R, 0),
					World = true,
					Look = "Rubber",
				}, hub)
			end
		elseif tires == "Whitewall" then
			local mid = rimR + (R - rimR) * 0.5
			Util.ring(ctx, face * CFrame.new(0.01, 0, 0), mid, (R - rimR) * 0.45, 0.03, 20, {
				Name = "Whitewall",
				Color = Color3.fromRGB(240, 240, 236),
			}, hub)
		end

		-- Barrel shadow behind the spokes
		Util.disc(ctx, face * CFrame.new(0.02, 0, 0), rimR, 0.04, { Name = "Barrel", Color = BARREL }, hub)

		-- Brakes (static, welded to Root)
		Util.disc(ctx, face * CFrame.new(0.06, 0, 0), rimR * 0.72, 0.04, {
			Name = "Rotor",
			Color = ROTOR,
			Material = Enum.Material.Metal,
		}, root)
		Util.part(ctx, {
			Name = "Caliper",
			Size = Vector3.new(0.1, rimR * 0.5, rimR * 0.34),
			CFrame = face * CFrame.new(0.1, 0, 0) * CFrame.Angles(math.rad(-40), 0, 0) * CFrame.new(0, rimR * 0.52, 0),
			World = true,
			Color = ctx.colors.Caliper,
		}, root)

		buildRim(ctx, rimStyle, face, rimR, hub)

		ctx.currentParent = nil

		if info.Rear then
			local attachment = Instance.new("Attachment")
			attachment.Name = "SmokeAttachment"
			attachment.CFrame = CFrame.new(x, 0.3, z + R * 0.6)
			attachment.Parent = root
			local smoke = Instance.new("ParticleEmitter")
			smoke.Name = "TireSmoke"
			smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
			smoke.Color = ColorSequence.new(ctx.colors.Smoke)
			smoke.LightEmission = 0.1
			smoke.LightInfluence = 0.6
			smoke.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.2),
				NumberSequenceKeypoint.new(1, 7),
			})
			smoke.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.25),
				NumberSequenceKeypoint.new(1, 1),
			})
			smoke.Lifetime = NumberRange.new(1.4, 2.4)
			smoke.Rate = 45
			smoke.Speed = NumberRange.new(3, 6)
			smoke.SpreadAngle = Vector2.new(35, 35)
			smoke.Acceleration = Vector3.new(0, 1.5, 4)
			smoke.RotSpeed = NumberRange.new(-40, 40)
			smoke.Rotation = NumberRange.new(0, 360)
			smoke.EmissionDirection = Enum.NormalId.Back
			smoke.Enabled = false
			smoke.Parent = attachment
		end
	end
end

return Wheels
