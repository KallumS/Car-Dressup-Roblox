
-- Client-side extras: signals, services, remotes ------------------------------
local function newSignal()
	local s = { handlers = {} }
	function s:Connect(fn)
		table.insert(self.handlers, fn)
		return { Disconnect = function() end }
	end
	function s:Fire(...)
		for _, fn in self.handlers do
			fn(...)
		end
	end
	function s:Wait() end
	return s
end
NEW_SIGNAL = newSignal

local EVENT_NAMES = {
	Activated = true, Event = true, Completed = true, OnClientEvent = true, OnServerEvent = true,
	RenderStepped = true, PreSimulation = true, Heartbeat = true, InputBegan = true, InputEnded = true,
	InputChanged = true, TouchPinch = true, PlayerAdded = true, PlayerRemoving = true,
}
local mt = getmetatable(Instance.new("Folder"))
local oldIndex = mt.__index
mt.__index = function(self, k)
	if EVENT_NAMES[k] then
		local key = "__sig_" .. k
		local sig = rawget(self, key)
		if not sig then
			sig = newSignal()
			rawset(self, key, sig)
		end
		return sig
	end
	if k == "Fire" then
		return function(inst, ...)
			inst.Event:Fire(...)
		end
	end
	if k == "GetPropertyChangedSignal" then
		return function()
			return newSignal()
		end
	end
	if k == "BindToRenderStep" or k == "Play" then
		return function() end
	end
	if k == "Create" then
		return function()
			local tween = Instance.new("Tween")
			return tween
		end
	end
	if k == "GetTagged" then
		return function()
			return {}
		end
	end
	if k == "GetInstanceAddedSignal" or k == "GetInstanceRemovedSignal" then
		return function()
			return newSignal()
		end
	end
	if k == "IsServer" then
		return function()
			return false
		end
	end
	if k == "IsStudio" then
		return function()
			return true
		end
	end
	if k == "GetServerTimeNow" then
		return function()
			return os.clock()
		end
	end
	return oldIndex(self, k)
end

local localPlayer = Instance.new("Player")
localPlayer.Name = "Tester"
rawset(localPlayer, "__props", localPlayer.__props)
localPlayer.__props.UserId = 7
localPlayer.__props.DisplayName = "Tester"
local playerGui = Instance.new("PlayerGui")
playerGui.Name = "PlayerGui"
playerGui.Parent = localPlayer
local playersService = game:GetService("Players")
playersService.__props.LocalPlayer = localPlayer

local camera = Instance.new("Camera")
camera.__props.ViewportSize = Vector2.new(1280, 720)
camera.__props.CFrame = CFrame.new()
workspace.__props.CurrentCamera = camera

local function remote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.__props.FireServer = function(_, ...)
		SENT = SENT or {}
		table.insert(SENT, { name, ... })
	end
	return r
end
local getState = Instance.new("RemoteFunction")
getState.__props.InvokeServer = function()
	return nil
end
NET_STUB = {
	StateChanged = remote("StateChanged"),
	BuildChanged = remote("BuildChanged"),
	Notify = remote("Notify"),
	UpdateBuild = remote("UpdateBuild"),
	SubmitRating = remote("SubmitRating"),
	ShowOff = remote("ShowOff"),
	SetReady = remote("SetReady"),
	GetState = getState,
}
