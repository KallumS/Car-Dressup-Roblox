-- Single place that defines every RemoteEvent/RemoteFunction.
-- The server creates them on first require; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"StateChanged", -- server -> all: match state snapshot
	"BuildChanged", -- server -> player: authoritative build after an edit
	"Notify", -- server -> player: toast message
	"UpdateBuild", -- client -> server: (slotId, value)
	"SubmitRating", -- client -> server: (presenterUserId, stars)
	"ShowOff", -- client -> server: (action) while presenting
	"SetReady", -- client -> server: (isReady) during customize
}

local FUNCTIONS = {
	"GetState", -- client -> server: returns current state + own build
}

local folder: Folder
if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in EVENTS do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	for _, name in FUNCTIONS do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

local function event(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

local function func(name: string): RemoteFunction
	return folder:WaitForChild(name) :: RemoteFunction
end

return {
	StateChanged = event("StateChanged"),
	BuildChanged = event("BuildChanged"),
	Notify = event("Notify"),
	UpdateBuild = event("UpdateBuild"),
	SubmitRating = event("SubmitRating"),
	ShowOff = event("ShowOff"),
	SetReady = event("SetReady"),
	GetState = func("GetState"),
}
