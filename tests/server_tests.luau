-- Test driver ----------------------------------------------------------------
local Catalog = require(node("ReplicatedStorage/Shared/Catalog"))
local CarBuilder = require(node("ServerScriptService/Server/CarBuilder"))
local MapBuilder = require(node("ServerScriptService/Server/MapBuilder"))

local failures = 0
local maxParts = 0
local builds = 0

local function finite(n)
	return n == n and n ~= math.huge and n ~= -math.huge
end

local function fail(msg)
	failures += 1
	if failures <= 40 then
		print("FAIL: " .. msg)
	end
end

local function check(model, label)
	local parts = 0
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			parts += 1
			local s = inst.Size
			if not s or not (s.X > 0 and s.Y > 0 and s.Z > 0) then
				fail(label .. ": bad size on " .. inst.Name .. " " .. tostring(s and s.X) .. "," .. tostring(s and s.Y) .. "," .. tostring(s and s.Z))
			end
			local cf = inst.CFrame
			if not cf or not (finite(cf.x) and finite(cf.y) and finite(cf.z)) then
				fail(label .. ": bad CFrame on " .. inst.Name)
			end
			if inst.Name ~= "Root" then
				local joints = 0
				for _, c in inst:GetChildren() do
					if (c:IsA("JointInstance")) and c.Part1 == inst then
						joints += 1
						if not c.Part0 then
							fail(label .. ": joint without Part0 on " .. inst.Name)
						end
					end
				end
				if joints ~= 1 then
					fail(label .. ": " .. inst.Name .. " has " .. joints .. " joints")
				end
				if inst.Anchored then
					fail(label .. ": anchored non-root " .. inst.Name)
				end
			end
		elseif inst:IsA("GuiObject") then
			local size = inst.Size
			if size and (not finite(size.X.Scale) or not finite(size.Y.Scale)) then
				fail(label .. ": gui size NaN")
			end
		end
	end
	maxParts = math.max(maxParts, parts)
	-- Every car needs its animated joints.
	local names = {}
	for _, inst in model:GetDescendants() do
		if inst:IsA("Motor6D") then
			names[inst.Name] = (names[inst.Name] or 0) + 1
		end
	end
	if names.Suspension ~= 1 then
		fail(label .. ": suspension motors = " .. tostring(names.Suspension))
	end
	if names.Wheel ~= 4 then
		fail(label .. ": wheel motors = " .. tostring(names.Wheel))
	end
	if names.Hinge ~= 4 then
		fail(label .. ": hinge motors = " .. tostring(names.Hinge))
	end
end

local function tryBuild(build, label)
	builds += 1
	local ok, result = pcall(CarBuilder.build, build, { OwnerUserId = 1234, Name = "Car_1234" })
	if not ok then
		fail(label .. ": " .. tostring(result))
		return
	end
	check(result, label)
end

-- Every option of every slot, on every base car.
for _, car in Catalog.Cars do
	for _, slot in Catalog.Slots do
		if slot.Kind == "Option" and slot.Id ~= "Car" then
			for _, option in slot.Options do
				local build = Catalog.DefaultBuild()
				build.Car = car.Id
				build[slot.Id] = option.Id
				tryBuild(build, car.Id .. "/" .. slot.Id .. "=" .. option.Id)
			end
		end
	end
end

-- Random combinations.
math.randomseed(42)
for i = 1, 400 do
	local build = {}
	for _, slot in Catalog.Slots do
		if slot.Kind == "Color" then
			build[slot.Id] = Catalog.Palette[math.random(1, #Catalog.Palette)].Id
		else
			build[slot.Id] = slot.Options[math.random(1, #slot.Options)].Id
		end
	end
	-- Stack vinyls often.
	tryBuild(build, "random#" .. i)
end

-- Garbage input must sanitize to defaults.
tryBuild({ Car = "Tank", Rims = 5, Hood = "Nope" }, "garbage")
assert(Catalog.IsValidValue("Rims", "Spinners"))
assert(not Catalog.IsValidValue("Rims", "Nope"))
assert(not Catalog.IsValidValue("Nope", "Stock"))
assert(not Catalog.IsValidValue("BodyColor", 5))

-- Default values must be valid options.
for _, slot in Catalog.Slots do
	if not Catalog.IsValidValue(slot.Id, slot.Default) then
		fail("default for " .. slot.Id .. " is invalid")
	end
end

local okMap, mapResult = pcall(MapBuilder.build)
if not okMap then
	fail("MapBuilder: " .. tostring(mapResult))
else
	assert(#mapResult.Bays == 10, "expected 10 bays")
	assert(#mapResult.PodiumCFrames == 3, "expected 3 podium spots")
end

print(string.format("builds=%d  maxPartsPerCar=%d  failures=%d", builds, maxParts, failures))
if failures > 0 then
	error("harness failed")
end
