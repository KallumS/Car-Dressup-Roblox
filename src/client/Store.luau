-- Client-side copy of the match state and this player's build.
-- Controllers read from here and subscribe to changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Catalog)

local Store = {}

Store.State = {
	Phase = "Lobby",
	Participants = {},
} :: { [string]: any }
Store.Build = Catalog.DefaultBuild()

local stateChanged = Instance.new("BindableEvent")
local buildChanged = Instance.new("BindableEvent")
Store.StateChanged = stateChanged.Event
Store.BuildChanged = buildChanged.Event

function Store.setState(newState: { [string]: any })
	local previous = Store.State
	Store.State = newState
	stateChanged:Fire(newState, previous)
end

function Store.setBuild(build: { [string]: any }?)
	Store.Build = Catalog.Sanitize(build)
	buildChanged:Fire(Store.Build)
end

function Store.isParticipant(): boolean
	local me = Players.LocalPlayer.UserId
	for _, entry in Store.State.Participants or {} do
		if entry.UserId == me then
			return true
		end
	end
	return false
end

function Store.myBay(): number?
	local me = Players.LocalPlayer.UserId
	for _, entry in Store.State.Participants or {} do
		if entry.UserId == me then
			return entry.Bay
		end
	end
	return nil
end

function Store.amReady(): boolean
	local me = Players.LocalPlayer.UserId
	for _, entry in Store.State.Participants or {} do
		if entry.UserId == me then
			return entry.Ready == true
		end
	end
	return false
end

function Store.timeLeft(): number
	local endsAt = Store.State.EndsAt
	if not endsAt then
		return 0
	end
	return math.max(0, endsAt - workspace:GetServerTimeNow())
end

function Store.carName(userId: number): string
	return "Car_" .. userId
end

function Store.findCar(userId: number?): Model?
	if not userId then
		return nil
	end
	local folder = workspace:FindFirstChild("Cars")
	local car = folder and folder:FindFirstChild(Store.carName(userId))
	if car and car:IsA("Model") then
		return car
	end
	return nil
end

return Store
