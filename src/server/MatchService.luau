-- The match loop and everything players can ask the server to do.
--
--   Lobby -> Intermission -> Customize (5 min) -> Showcase (each car on stage,
--   everyone else rates it 1-5 stars) -> Results (top 3 on the podium) -> Lobby
--
-- The server is authoritative: builds are validated against the Catalog, cars
-- are built here, ratings are only accepted for the car currently on stage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local CarBuilder = require(script.Parent.CarBuilder)
local MapBuilder = require(script.Parent.MapBuilder)

local MatchService = {}

type Participant = {
	Bay: MapBuilder.Bay,
	Ready: boolean,
	Car: Model?,
	Dirty: boolean,
	Presented: boolean,
}

type ResultEntry = {
	UserId: number,
	Name: string,
	CarName: string,
	Average: number,
	Votes: number,
	Place: number,
}

local SHOW_OFF_FLAGS = { "DoorsOpen", "HoodOpen", "TrunkOpen", "Bounce", "Burnout" }

local map: MapBuilder.MapInfo
local carsFolder: Folder

local builds: { [Player]: Catalog.Build } = {}
local participants: { [Player]: Participant } = {}
local ratings: { [number]: { [number]: number } } = {}
local lastBuildUpdate: { [Player]: number } = {}
local lastShowOff: { [Player]: number } = {}

local state = {
	Phase = "Lobby",
	EndsAt = nil :: number?,
	Theme = nil :: { Name: string, Description: string }?,
	Message = "",
	PlayerCount = 0,
	MinPlayers = Config.MinPlayersToStart,
	Presenter = nil :: number?,
	PresenterName = nil :: string?,
	PresenterCar = nil :: string?,
	PresenterIndex = 0,
	PresenterCount = 0,
	Results = nil :: { ResultEntry }?,
}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function minPlayers(): number
	return if RunService:IsStudio() then Config.MinPlayersToStartInStudio else Config.MinPlayersToStart
end

local function participantCount(): number
	local n = 0
	for _ in participants do
		n += 1
	end
	return n
end

local function snapshot()
	local list = {}
	for player, info in participants do
		table.insert(list, {
			UserId = player.UserId,
			Name = player.DisplayName,
			Bay = info.Bay.Index,
			Ready = info.Ready,
		})
	end
	table.sort(list, function(a, b)
		return a.Bay < b.Bay
	end)
	return {
		Phase = state.Phase,
		EndsAt = state.EndsAt,
		Theme = state.Theme,
		Message = state.Message,
		PlayerCount = #Players:GetPlayers(),
		MinPlayers = minPlayers(),
		Participants = list,
		Presenter = state.Presenter,
		PresenterName = state.PresenterName,
		PresenterCar = state.PresenterCar,
		PresenterIndex = state.PresenterIndex,
		PresenterCount = state.PresenterCount,
		Results = state.Results,
	}
end

local function broadcast()
	Net.StateChanged:FireAllClients(snapshot())
end

local function notify(player: Player, text: string)
	Net.Notify:FireClient(player, text)
end

local function setPhase(phase: string, duration: number?)
	state.Phase = phase
	state.EndsAt = if duration then now() + duration else nil
	broadcast()
end

-- Waits until the phase timer runs out. Returns false if `abort` fired first.
-- state.EndsAt may be moved while waiting (e.g. everyone pressed Ready).
local function waitForTimer(abort: (() -> boolean)?): boolean
	while state.EndsAt and now() < state.EndsAt do
		if abort and abort() then
			return false
		end
		task.wait(0.2)
	end
	return true
end

-- Cars --------------------------------------------------------------------------

local function carName(player: Player): string
	return "Car_" .. player.UserId
end

local function rootOf(car: Model): BasePart?
	return car.PrimaryPart
end

local function spawnCar(player: Player)
	local info = participants[player]
	if not info then
		return
	end
	local oldCar = info.Car
	local car = CarBuilder.build(builds[player], { OwnerUserId = player.UserId, Name = carName(player) })
	car:PivotTo(info.Bay.CarCFrame)
	car.Parent = carsFolder
	info.Car = car
	info.Dirty = false
	if oldCar then
		oldCar:Destroy()
	end
end

local function destroyCar(player: Player)
	local info = participants[player]
	if info and info.Car then
		info.Car:Destroy()
		info.Car = nil
	end
end

local function flushDirtyCars()
	for player, info in participants do
		if info.Dirty then
			spawnCar(player)
		end
	end
end

local function resetFlags(car: Model)
	for _, flag in SHOW_OFF_FLAGS do
		car:SetAttribute(flag, false)
	end
	car:SetAttribute("Driving", false)
end

-- Remote handlers ------------------------------------------------------------------

local function onUpdateBuild(player: Player, slotId: any, value: any)
	if state.Phase ~= "Customize" then
		return
	end
	local info = participants[player]
	if not info then
		return
	end
	local build = builds[player]
	local t = os.clock()
	if t - (lastBuildUpdate[player] or 0) < Config.BuildUpdateCooldown or not Catalog.IsValidValue(slotId, value) then
		-- Rejected: resync the client, which applied the change optimistically.
		Net.BuildChanged:FireClient(player, build)
		return
	end
	lastBuildUpdate[player] = t
	if build[slotId] == value then
		return
	end
	build[slotId] = value
	info.Dirty = true
	Net.BuildChanged:FireClient(player, build)
end

local function onSetReady(player: Player, ready: any)
	if state.Phase ~= "Customize" or typeof(ready) ~= "boolean" then
		return
	end
	local info = participants[player]
	if not info or info.Ready == ready then
		return
	end
	info.Ready = ready

	local allReady = true
	for _, p in participants do
		if not p.Ready then
			allReady = false
			break
		end
	end
	if allReady and state.EndsAt and state.EndsAt - now() > Config.AllReadyTimeLeft then
		state.EndsAt = now() + Config.AllReadyTimeLeft
	end
	broadcast()
end

local function onSubmitRating(player: Player, presenterId: any, stars: any)
	if state.Phase ~= "Showcase" or typeof(presenterId) ~= "number" or typeof(stars) ~= "number" then
		return
	end
	if presenterId ~= state.Presenter or presenterId == player.UserId then
		return
	end
	if stars ~= math.floor(stars) or stars < Config.MinStars or stars > Config.MaxStars then
		return
	end
	local bucket = ratings[presenterId]
	if bucket then
		bucket[player.UserId] = stars
	end
end

local function onShowOff(player: Player, flag: any)
	if state.Phase ~= "Showcase" or state.Presenter ~= player.UserId then
		return
	end
	if typeof(flag) ~= "string" or not table.find(SHOW_OFF_FLAGS, flag) then
		return
	end
	local t = os.clock()
	if t - (lastShowOff[player] or 0) < Config.ShowOffCooldown then
		return
	end
	lastShowOff[player] = t
	local info = participants[player]
	local car = info and info.Car
	if not car then
		return
	end
	if flag == "Bounce" and not car:GetAttribute("HasHydraulics") then
		notify(player, "Install Hydraulics to hit switches!")
		return
	end
	car:SetAttribute(flag, not car:GetAttribute(flag))
end

-- Phases ------------------------------------------------------------------------------

local function presentCar(player: Player, index: number, total: number)
	local info = participants[player]
	local car = info and info.Car
	local root = car and rootOf(car)
	if not info or not car or not root then
		return
	end
	info.Presented = true
	ratings[player.UserId] = {}

	state.Presenter = player.UserId
	state.PresenterName = player.DisplayName
	state.PresenterCar = car:GetAttribute("CarName") :: string?
	state.PresenterIndex = index
	state.PresenterCount = total
	setPhase("Showcase", Config.ShowcaseTimePerCar)

	resetFlags(car)
	local start = now()
	local stillHere = function(): boolean
		return car.Parent ~= nil and participants[player] ~= nil
	end

	-- Drive onto the stage.
	car:SetAttribute("Driving", true)
	root.CFrame = map.StageEntryCFrame
	while stillHere() do
		local alpha = math.clamp((now() - start) / Config.ShowcaseDriveInTime, 0, 1)
		local eased = 1 - (1 - alpha) ^ 3
		root.CFrame = map.StageEntryCFrame:Lerp(map.StageCFrame, eased)
		if alpha >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	if stillHere() then
		car:SetAttribute("Driving", false)
	end

	-- Scripted reveal; the owner can also toggle things with ShowOff.
	local fired = {}
	local hydraulics = car:GetAttribute("HasHydraulics") == true
	while state.EndsAt and now() < state.EndsAt and stillHere() do
		local elapsed = now() - start
		for i, step in Config.ShowcaseSequence do
			if not fired[i] and elapsed >= step.At then
				fired[i] = true
				if not step.RequiresHydraulics or hydraulics then
					car:SetAttribute(step.Flag, step.Value)
				end
			end
		end
		task.wait(0.1)
	end

	if stillHere() then
		resetFlags(car)
		root.CFrame = info.Bay.CarCFrame
	end
end

local function computeResults(order: { Player }, names: { [Player]: string }, cars: { [Player]: string }): { ResultEntry }
	local results: { ResultEntry } = {}
	for _, player in order do
		local bucket = ratings[player.UserId]
		if bucket then
			local sum, votes = 0, 0
			for _, stars in bucket do
				sum += stars
				votes += 1
			end
			table.insert(results, {
				UserId = player.UserId,
				Name = names[player],
				CarName = cars[player],
				Average = if votes > 0 then math.floor(sum / votes * 100 + 0.5) / 100 else 0,
				Votes = votes,
				Place = 0,
			})
		end
	end
	table.sort(results, function(a, b)
		if a.Average ~= b.Average then
			return a.Average > b.Average
		end
		if a.Votes ~= b.Votes then
			return a.Votes > b.Votes
		end
		return a.Name < b.Name
	end)
	for i, entry in results do
		entry.Place = i
	end
	return results
end

local function awardWin(userId: number)
	local player = Players:GetPlayerByUserId(userId)
	local stats = player and player:FindFirstChild("leaderstats")
	local wins = stats and stats:FindFirstChild("Wins")
	if wins and wins:IsA("IntValue") then
		wins.Value += 1
	end
end

local function endMatch()
	for player in participants do
		destroyCar(player)
	end
	for _, bay in map.Bays do
		bay.NameLabel.Text = "OPEN"
	end
	for _, emitter in map.Confetti do
		emitter.Enabled = false
	end
	participants = {}
	ratings = {}
	state.Theme = nil
	state.Presenter = nil
	state.PresenterName = nil
	state.PresenterCar = nil
	state.Results = nil
end

local function runMatch()
	-- Seat up to MaxParticipants players in garage bays.
	participants = {}
	ratings = {}
	for i, player in Players:GetPlayers() do
		if i > Config.MaxParticipants then
			notify(player, "This match is full - you can still rate cars!")
			continue
		end
		local bay = map.Bays[i]
		participants[player] = { Bay = bay, Ready = false, Car = nil, Dirty = false, Presented = false }
		bay.NameLabel.Text = player.DisplayName
		spawnCar(player)
		Net.BuildChanged:FireClient(player, builds[player])
	end
	state.Theme = Config.Themes[math.random(1, #Config.Themes)]

	-- Customize
	setPhase("Customize", Config.CustomizeTime)
	local rebuildRunning = true
	task.spawn(function()
		while rebuildRunning do
			flushDirtyCars()
			task.wait(Config.RebuildInterval)
		end
	end)
	waitForTimer(function()
		return participantCount() == 0
	end)
	rebuildRunning = false
	flushDirtyCars()
	for _, info in participants do
		info.Ready = false
	end

	if participantCount() == 0 then
		endMatch()
		return
	end

	-- Showcase, in random order
	local order: { Player } = {}
	local names: { [Player]: string } = {}
	local cars: { [Player]: string } = {}
	for player, info in participants do
		table.insert(order, player)
		names[player] = player.DisplayName
		cars[player] = if info.Car then (info.Car:GetAttribute("CarName") :: string) or "Car" else "Car"
	end
	for i = #order, 2, -1 do
		local j = math.random(1, i)
		order[i], order[j] = order[j], order[i]
	end
	for index, player in order do
		if participants[player] then
			presentCar(player, index, #order)
		end
	end
	state.Presenter = nil

	-- Results
	local results = computeResults(order, names, cars)
	state.Results = results
	for place = 1, math.min(Config.PodiumSize, #results) do
		local entry = results[place]
		local player = Players:GetPlayerByUserId(entry.UserId)
		local info = player and participants[player]
		local car = info and info.Car
		local root = car and rootOf(car)
		if car and root then
			root.CFrame = map.PodiumCFrames[place]
			car:SetAttribute("DoorsOpen", true)
		end
	end
	if results[1] and results[1].Votes > 0 then
		awardWin(results[1].UserId)
	end
	for _, emitter in map.Confetti do
		emitter.Enabled = true
	end
	setPhase("Results", Config.ResultsTime)
	waitForTimer()
	endMatch()
end

local function lobbyMessage(): string
	local count = #Players:GetPlayers()
	local needed = minPlayers()
	if count < needed then
		return string.format("Waiting for players (%d/%d)", count, needed)
	end
	return "Match starting soon!"
end

local function gameLoop()
	while true do
		state.Message = lobbyMessage()
		setPhase("Lobby")
		while #Players:GetPlayers() < minPlayers() do
			local message = lobbyMessage()
			if message ~= state.Message then
				state.Message = message
				broadcast()
			end
			task.wait(0.5)
		end

		state.Message = lobbyMessage()
		setPhase("Intermission", Config.IntermissionTime)
		local started = waitForTimer(function()
			return #Players:GetPlayers() < minPlayers()
		end)
		if started then
			local ok, err = pcall(runMatch)
			if not ok then
				warn("[CarDressUp] Match crashed:", err)
				endMatch()
			end
		end
	end
end

-- Players -------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	builds[player] = Catalog.DefaultBuild()
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = stats
	stats.Parent = player
	broadcast()
end

local function onPlayerRemoving(player: Player)
	local info = participants[player]
	if info then
		destroyCar(player)
		info.Bay.NameLabel.Text = "OPEN"
		participants[player] = nil
	end
	builds[player] = nil
	lastBuildUpdate[player] = nil
	lastShowOff[player] = nil
	task.defer(broadcast)
end

function MatchService.start()
	map = MapBuilder.build()
	carsFolder = workspace:WaitForChild("Cars") :: Folder

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Net.UpdateBuild.OnServerEvent:Connect(onUpdateBuild)
	Net.SetReady.OnServerEvent:Connect(onSetReady)
	Net.SubmitRating.OnServerEvent:Connect(onSubmitRating)
	Net.ShowOff.OnServerEvent:Connect(onShowOff)
	Net.GetState.OnServerInvoke = function(player: Player)
		return snapshot(), builds[player]
	end

	task.spawn(gameLoop)
end

return MatchService
