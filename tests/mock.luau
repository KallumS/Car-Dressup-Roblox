-- Minimal mock of the Roblox runtime: enough to execute CarBuilder/MapBuilder
-- in the standalone Luau CLI and catch runtime errors and bad geometry.

MODULES = {}
PROPSETS = {}
local loadedModules = {}

-- Script tree nodes (for script.Parent.X / ReplicatedStorage.Shared.X requires)
local NodeMT = {}
local function node(path: string)
	return setmetatable({ __path = path }, NodeMT)
end
NodeMT.__index = function(t, k)
	local path = rawget(t, "__path")
	if k == "Parent" then
		local parent = string.match(path, "^(.*)/[^/]+$")
		return node(parent or "")
	end
	if k == "WaitForChild" or k == "FindFirstChild" then
		return function(self, name)
			return node(rawget(self, "__path") .. "/" .. name)
		end
	end
	return node(path .. "/" .. k)
end

local realRequire = require
function require(target)
	if type(target) == "table" and rawget(target, "__path") then
		local path = rawget(target, "__path")
		if loadedModules[path] == nil then
			local fn = MODULES[path]
			if not fn then
				error("no module at " .. path)
			end
			loadedModules[path] = fn(node(path))
		end
		return loadedModules[path]
	end
	return realRequire(target)
end

-- Vector3 -----------------------------------------------------------------------
local V3 = {}
V3.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return Vector3.new(v.X / m, v.Y / m, v.Z / m)
	end
	return V3[k]
end
Vector3 = {}
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0, __type = "Vector3" }, V3)
end
Vector3.zero = Vector3.new(0, 0, 0)
V3.__add = function(a, b)
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		return Vector3.new(b.X * a, b.Y * a, b.Z * a)
	elseif type(b) == "number" then
		return Vector3.new(a.X * b, a.Y * b, a.Z * b)
	end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	return Vector3.new(a.X / b, a.Y / b, a.Z / b)
end
V3.__unm = function(a)
	return Vector3.new(-a.X, -a.Y, -a.Z)
end
function V3.Cross(a, b)
	return Vector3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end
function V3.Dot(a, b)
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end

Vector2 = {}
function Vector2.new(x, y)
	return { X = x or 0, Y = y or 0 }
end
Vector2.zero = Vector2.new(0, 0)

-- CFrame ------------------------------------------------------------------------
local CF = {}
CF.__index = function(c, k)
	if k == "Position" then
		return Vector3.new(c.x, c.y, c.z)
	elseif k == "LookVector" then
		return Vector3.new(-c.r[3], -c.r[6], -c.r[9])
	elseif k == "X" then
		return c.x
	elseif k == "Y" then
		return c.y
	elseif k == "Z" then
		return c.z
	end
	return CF[k]
end
CFrame = {}
local function mk(r, x, y, z)
	return setmetatable({ r = r, x = x, y = y, z = z, __type = "CFrame" }, CF)
end
local I = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
function CFrame.new(a, b, c)
	if a == nil then
		return mk(I, 0, 0, 0)
	elseif type(a) == "table" then
		return mk(I, a.X, a.Y, a.Z)
	end
	return mk(I, a, b, c)
end
CFrame.identity = CFrame.new()
local function mulR(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			local s = 0
			for k = 0, 2 do
				s += a[i * 3 + k + 1] * b[k * 3 + j + 1]
			end
			r[i * 3 + j + 1] = s
		end
	end
	return r
end
local function rx(t)
	local c, s = math.cos(t), math.sin(t)
	return { 1, 0, 0, 0, c, -s, 0, s, c }
end
local function ry(t)
	local c, s = math.cos(t), math.sin(t)
	return { c, 0, s, 0, 1, 0, -s, 0, c }
end
local function rz(t)
	local c, s = math.cos(t), math.sin(t)
	return { c, -s, 0, s, c, 0, 0, 0, 1 }
end
function CFrame.Angles(a, b, c)
	return mk(mulR(mulR(rx(a), ry(b)), rz(c)), 0, 0, 0)
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
function CFrame.fromEulerAnglesYXZ(a, b, c)
	return mk(mulR(mulR(ry(b), rx(a)), rz(c)), 0, 0, 0)
end
function CFrame.lookAt(at, target)
	local look = (target - at).Unit
	local right = look:Cross(Vector3.new(0, 1, 0)).Unit
	local up = right:Cross(look)
	return mk({ right.X, up.X, -look.X, right.Y, up.Y, -look.Y, right.Z, up.Z, -look.Z }, at.X, at.Y, at.Z)
end
local function rotV(r, v)
	return r[1] * v.X + r[2] * v.Y + r[3] * v.Z, r[4] * v.X + r[5] * v.Y + r[6] * v.Z, r[7] * v.X + r[8] * v.Y + r[9] * v.Z
end
CF.__mul = function(a, b)
	if getmetatable(b) == V3 then
		local x, y, z = rotV(a.r, b)
		return Vector3.new(x + a.x, y + a.y, z + a.z)
	end
	local x, y, z = rotV(a.r, Vector3.new(b.x, b.y, b.z))
	return mk(mulR(a.r, b.r), x + a.x, y + a.y, z + a.z)
end
function CF.Inverse(c)
	local r = c.r
	local t = { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
	local x, y, z = rotV(t, Vector3.new(c.x, c.y, c.z))
	return mk(t, -x, -y, -z)
end
function CF.Lerp(a, b, t)
	local r = if t < 0.5 then a.r else b.r
	return mk(r, a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t)
end
function CF.ToObjectSpace(a, b)
	return a:Inverse() * b
end

-- Other datatypes ---------------------------------------------------------------
local C3 = {}
C3.__index = C3
Color3 = {}
function Color3.new(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0, __type = "Color3" }, C3)
end
function Color3.fromRGB(r, g, b)
	for _, v in { r, g, b } do
		assert(v >= 0 and v <= 255, "Color3.fromRGB out of range")
	end
	return Color3.new(r / 255, g / 255, b / 255)
end
function C3.Lerp(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

UDim = {}
function UDim.new(s, o)
	return { Scale = s, Offset = o }
end
UDim2 = {}
function UDim2.new(a, b, c, d)
	return { X = UDim.new(a or 0, b or 0), Y = UDim.new(c or 0, d or 0) }
end
function UDim2.fromScale(a, b)
	return UDim2.new(a, 0, b, 0)
end
function UDim2.fromOffset(a, b)
	return UDim2.new(0, a, 0, b)
end

NumberSequenceKeypoint = {}
function NumberSequenceKeypoint.new(t, v)
	return { Time = t, Value = v }
end
NumberSequence = {}
function NumberSequence.new(a, b)
	if type(a) == "number" then
		return { Keypoints = { { Time = 0, Value = a }, { Time = 1, Value = b or a } } }
	end
	assert(#a >= 2 and #a <= 20, "NumberSequence: 2..20 keypoints")
	assert(a[1].Time == 0 and a[#a].Time == 1, "NumberSequence must start at 0 and end at 1")
	for i = 2, #a do
		assert(a[i].Time > a[i - 1].Time, "NumberSequence times must increase")
	end
	return { Keypoints = a }
end
ColorSequenceKeypoint = {}
function ColorSequenceKeypoint.new(t, c)
	return { Time = t, Value = c }
end
ColorSequence = {}
function ColorSequence.new(a, b)
	if getmetatable(a) == C3 then
		return { a, b or a }
	end
	assert(#a >= 2 and #a <= 20 and a[1].Time == 0 and a[#a].Time == 1, "bad ColorSequence")
	return a
end
NumberRange = {}
function NumberRange.new(a, b)
	assert(b == nil or a <= b, "NumberRange min > max")
	return { Min = a, Max = b or a }
end
Random = {}
function Random.new(_seed)
	return {
		NextNumber = function(_, a, b)
			a = a or 0
			b = b or 1
			return a + (b - a) * math.random()
		end,
	}
end

Enum = setmetatable({}, {
	__index = function(_, enumName)
		return setmetatable({}, {
			__index = function(_, item)
				return { Name = item, EnumType = enumName, Value = 0 }
			end,
		})
	end,
})

-- Instances ---------------------------------------------------------------------
local ISA = {
	Part = { "BasePart", "PVInstance" },
	WedgePart = { "BasePart", "PVInstance" },
	SpawnLocation = { "Part", "BasePart", "PVInstance" },
	Model = { "PVInstance" },
	Frame = { "GuiObject" },
	TextLabel = { "GuiObject" },
	TextButton = { "GuiObject" },
	ScrollingFrame = { "GuiObject" },
	PointLight = { "Light" },
	SpotLight = { "Light" },
	Weld = { "JointInstance" },
	Motor6D = { "JointInstance", "Motor" },
}
ALL_INSTANCES = {}
local InstMT = {}
local methods = {}
function methods.IsA(self, cls)
	local cn = self.__props.ClassName
	if cn == cls or cls == "Instance" then
		return true
	end
	return table.find(ISA[cn] or {}, cls) ~= nil
end
function methods.SetAttribute(self, k, v)
	self.__attrs[k] = v
end
function methods.GetAttribute(self, k)
	return self.__attrs[k]
end
function methods.GetChildren(self)
	return table.clone(self.__children)
end
function methods.GetDescendants(self)
	local out = {}
	local function walk(n)
		for _, c in n.__children do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function methods.FindFirstChild(self, name)
	for _, c in self.__children do
		if c.__props.Name == name then
			return c
		end
	end
	return nil
end
methods.WaitForChild = methods.FindFirstChild
function methods.FindFirstChildOfClass(self, cls)
	for _, c in self.__children do
		if c.__props.ClassName == cls then
			return c
		end
	end
	return nil
end
function methods.Destroy(self)
	self.Parent = nil
end
function methods.PivotTo(self, cf)
	self.__props.__pivot = cf
end
function methods.AddTag(_, inst, tag)
	inst.__tags = inst.__tags or {}
	inst.__tags[tag] = true
end
InstMT.__index = function(self, k)
	if methods[k] then
		return methods[k]
	end
	local v = self.__props[k]
	if v ~= nil then
		return v
	end
	return methods.FindFirstChild(self, k)
end
InstMT.__newindex = function(self, k, v)
	if k == "Parent" then
		local old = self.__props.Parent
		if old then
			local i = table.find(old.__children, self)
			if i then
				table.remove(old.__children, i)
			end
		end
		self.__props.Parent = v
		if v then
			table.insert(v.__children, self)
		end
		return
	end
	if k == "Shape" and self.__props.ClassName ~= "Part" and self.__props.ClassName ~= "SpawnLocation" then
		error("Shape is not a valid member of " .. self.__props.ClassName)
	end
	PROPSETS[self.__props.ClassName .. "." .. k] = true
	self.__props[k] = v
end
Instance = {}
function Instance.new(className)
	local self = setmetatable({ __props = { ClassName = className, Name = className }, __children = {}, __attrs = {} }, InstMT)
	table.insert(ALL_INSTANCES, self)
	return self
end

local services = {}
game = {
	GetService = function(_, name)
		if name == "ReplicatedStorage" or name == "ServerScriptService" then
			return node(name)
		end
		services[name] = services[name] or Instance.new(name)
		return services[name]
	end,
}
workspace = Instance.new("Workspace")
