-- Animates every car locally by driving its Motor6D.Transform values:
-- doors / hood / trunk hinges, rolling wheels, spinners, subwoofer cones,
-- hydraulic hopping, tyre smoke and pulsing neon.
--
-- What to animate comes from attributes the server sets on the car model
-- (DoorsOpen, HoodOpen, TrunkOpen, Bounce, Burnout, Driving). The local player
-- can also preview effects on their own car via CarAnimator.setOverride.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local CarAnimator = {}

local TAG = "DressCar"
local HINGE_SPEED = 1.4 -- fraction of full travel per second

type Hinge = { Motor: Motor6D, Kind: string, RX: number, RY: number, RZ: number, Alpha: number }
type Record = {
	Model: Model,
	Hinges: { Hinge },
	Wheels: { { Motor: Motor6D, Rear: boolean, Angle: number } },
	Spinners: { { Motor: Motor6D, Angle: number } },
	Subs: { Motor6D },
	Suspension: Motor6D?,
	Smoke: { ParticleEmitter },
	PulseLights: { { Light: PointLight, Base: number, Group: string } },
	PulseNeon: { { Part: BasePart, Group: string } },
	Phase: number,
	Bounce: number,
}

local records: { [Model]: Record } = {}
local overrides: { [string]: { [string]: boolean } } = {}

local function scan(model: Model): Record
	local record: Record = {
		Model = model,
		Hinges = {},
		Wheels = {},
		Spinners = {},
		Subs = {},
		Suspension = nil,
		Smoke = {},
		PulseLights = {},
		PulseNeon = {},
		Phase = math.random() * 10,
		Bounce = 0,
	}
	for _, inst in model:GetDescendants() do
		if inst:IsA("Motor6D") then
			if inst.Name == "Hinge" then
				table.insert(record.Hinges, {
					Motor = inst,
					Kind = inst:GetAttribute("Kind") or "Door",
					RX = math.rad(inst:GetAttribute("RX") or 0),
					RY = math.rad(inst:GetAttribute("RY") or 0),
					RZ = math.rad(inst:GetAttribute("RZ") or 0),
					Alpha = 0,
				})
			elseif inst.Name == "Wheel" then
				table.insert(record.Wheels, { Motor = inst, Rear = inst:GetAttribute("Rear") == true, Angle = 0 })
			elseif inst.Name == "Spinner" then
				table.insert(record.Spinners, { Motor = inst, Angle = 0 })
			elseif inst.Name == "SubCone" then
				table.insert(record.Subs, inst)
			elseif inst.Name == "Suspension" then
				record.Suspension = inst
			end
		elseif inst:IsA("ParticleEmitter") and inst.Name == "TireSmoke" then
			table.insert(record.Smoke, inst)
		elseif inst:IsA("PointLight") then
			local group = inst:GetAttribute("PulseGroup")
			if typeof(group) == "string" then
				table.insert(record.PulseLights, { Light = inst, Base = inst.Brightness, Group = group })
			end
		elseif inst:IsA("BasePart") then
			if inst.Name == "UnderglowStrip" then
				table.insert(record.PulseNeon, { Part = inst, Group = "Underglow" })
			elseif inst.Name == "InteriorNeon" then
				table.insert(record.PulseNeon, { Part = inst, Group = "Interior" })
			end
		end
	end
	return record
end

local function flag(model: Model, name: string): boolean
	local o = overrides[model.Name]
	if o and o[name] ~= nil then
		return o[name]
	end
	return model:GetAttribute(name) == true
end

local function hingeTarget(kind: string, model: Model): boolean
	if kind == "Door" then
		return flag(model, "DoorsOpen")
	elseif kind == "Hood" then
		return flag(model, "HoodOpen")
	elseif kind == "Trunk" then
		return flag(model, "TrunkOpen")
	end
	return false
end

local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

local function step(record: Record, dt: number, t: number)
	local model = record.Model

	for _, hinge in record.Hinges do
		local target = if hingeTarget(hinge.Kind, model) then 1 else 0
		if hinge.Alpha ~= target then
			local delta = HINGE_SPEED * dt
			hinge.Alpha = if target > hinge.Alpha
				then math.min(target, hinge.Alpha + delta)
				else math.max(target, hinge.Alpha - delta)
			local a = smooth(hinge.Alpha)
			hinge.Motor.Transform = CFrame.Angles(0, hinge.RY * a, 0)
				* CFrame.Angles(0, 0, hinge.RZ * a)
				* CFrame.Angles(hinge.RX * a, 0, 0)
		end
	end

	local driving = flag(model, "Driving")
	local burnout = flag(model, "Burnout")
	for _, wheel in record.Wheels do
		local speed = 0
		if driving then
			speed = 9
		end
		if burnout and wheel.Rear then
			speed = 40
		end
		if speed ~= 0 then
			-- Negative X rotation rolls the tyre forward (toward -Z).
			wheel.Angle = (wheel.Angle - speed * dt) % (math.pi * 2)
			wheel.Motor.Transform = CFrame.Angles(wheel.Angle, 0, 0)
		end
	end

	for _, spinner in record.Spinners do
		spinner.Angle = (spinner.Angle + 3 * dt) % (math.pi * 2)
		spinner.Motor.Transform = CFrame.Angles(spinner.Angle, 0, 0)
	end

	local trunkOpen = flag(model, "TrunkOpen")
	for _, cone in record.Subs do
		local pump = if trunkOpen then math.max(0, math.sin(t * 15 + record.Phase)) * 0.1 else 0
		-- Cones face up along their local X axis.
		cone.Transform = CFrame.new(pump, 0, 0)
	end

	for _, emitter in record.Smoke do
		if emitter.Enabled ~= burnout then
			emitter.Enabled = burnout
		end
	end

	local suspension = record.Suspension
	if suspension then
		local bounceTarget = if flag(model, "Bounce") and model:GetAttribute("HasHydraulics") then 1 else 0
		record.Bounce += (bounceTarget - record.Bounce) * math.min(1, dt * 4)
		local b = record.Bounce
		local cf = CFrame.identity
		if b > 0.001 then
			local tt = t * 2.6 + record.Phase
			local hop = math.abs(math.sin(tt * 2)) * 1.3
			cf = CFrame.new(0, hop * b, 0) * CFrame.Angles(math.sin(tt) * 0.16 * b, 0, math.cos(tt) * 0.12 * b)
		end
		if burnout then
			-- Squat on the rear and shake.
			cf = cf
				* CFrame.new(0, -0.08 + math.sin(t * 60) * 0.03, 0)
				* CFrame.Angles(-0.03, 0, math.sin(t * 47) * 0.01)
		end
		suspension.Transform = cf
	end

	local underglowPulse = model:GetAttribute("UnderglowMode") == "Pulse"
	local interiorPulse = model:GetAttribute("InteriorMode") == "Pulse"
	if underglowPulse or interiorPulse then
		local wave = 0.5 + 0.5 * math.sin(t * 4 + record.Phase)
		for _, entry in record.PulseLights do
			local pulsing = (entry.Group == "Underglow" and underglowPulse) or (entry.Group == "Interior" and interiorPulse)
			if pulsing then
				entry.Light.Brightness = entry.Base * (0.25 + 0.75 * wave)
			end
		end
		for _, entry in record.PulseNeon do
			local pulsing = (entry.Group == "Underglow" and underglowPulse) or (entry.Group == "Interior" and interiorPulse)
			if pulsing then
				entry.Part.Transparency = 0.6 * (1 - wave)
			end
		end
	end
end

local function track(model: Instance)
	if not model:IsA("Model") or records[model] then
		return
	end
	-- Give streaming a frame to deliver descendants before scanning.
	task.defer(function()
		if model.Parent then
			records[model] = scan(model)
		end
	end)
end

-- Local preview flags for a car by model name (e.g. the player's own car).
function CarAnimator.setOverride(modelName: string, name: string, value: boolean?)
	local o = overrides[modelName]
	if not o then
		o = {}
		overrides[modelName] = o
	end
	o[name] = value
end

function CarAnimator.getOverride(modelName: string, name: string): boolean
	local o = overrides[modelName]
	return o ~= nil and o[name] == true
end

function CarAnimator.clearOverrides(modelName: string)
	overrides[modelName] = nil
end

function CarAnimator.start()
	for _, model in CollectionService:GetTagged(TAG) do
		track(model)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(model)
		records[model :: Model] = nil
	end)

	RunService.PreSimulation:Connect(function(dt)
		local t = os.clock()
		for model, record in records do
			if model.Parent == nil then
				records[model] = nil
			else
				step(record, dt, t)
			end
		end
	end)
end

return CarAnimator
