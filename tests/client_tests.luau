MODULES["ReplicatedStorage/Shared/Net"] = function()
	return NET_STUB
end
task = {
	delay = function() end,
	defer = function(fn, ...) fn(...) end,
	spawn = function(fn, ...) fn(...) end,
	wait = function() end,
}

-- Runs the real client entry script (init.client.luau) against the mocks.
MODULES["StarterPlayer/StarterPlayerScripts/Client"](node("StarterPlayer/StarterPlayerScripts/Client"))
local Store = require(node("StarterPlayer/StarterPlayerScripts/Client/Store"))
local Catalog = require(node("ReplicatedStorage/Shared/Catalog"))

local me = 7
Store.setState({ Phase = "Lobby", Message = "Waiting", PlayerCount = 1, Participants = {} })
Store.setState({ Phase = "Intermission", EndsAt = 10, Participants = {} })
Store.setState({
	Phase = "Customize",
	EndsAt = 300,
	Theme = { Name = "Drift Missile", Description = "x" },
	Participants = { { UserId = me, Name = "Tester", Bay = 1, Ready = false } },
})

-- Click every category tab, then every option / swatch button in it.
local gui = game:GetService("Players").LocalPlayer.PlayerGui.CarDressUp
local panel = gui.CustomizePanel
assert(panel.Visible == true, "customize panel should be visible")
local clicks = 0
for _, category in Catalog.Categories do
	panel.Tabs[category.Id].Activated:Fire()
	for _, section in panel.Content:GetChildren() do
		for _, button in section:GetChildren() do
			if button.ClassName == "TextButton" then
				button.Activated:Fire()
				clicks += 1
			end
		end
	end
end
for _, button in gui.ActionBar:GetDescendants() do
	if button.ClassName == "TextButton" then
		button.Activated:Fire()
	end
end
Store.setBuild(Store.Build)

Store.setState({ Phase = "Showcase", EndsAt = 18, Presenter = 99, PresenterName = "Other", PresenterCar = "Supercar", PresenterIndex = 1, PresenterCount = 2, Participants = { { UserId = me, Name = "Tester", Bay = 1 } } })
for _, button in gui.ShowcasePanel:GetDescendants() do
	if button.ClassName == "TextButton" then
		button.Activated:Fire()
	end
end
Store.setState({ Phase = "Showcase", EndsAt = 18, Presenter = me, PresenterName = "Tester", PresenterCar = "Coupe", PresenterIndex = 2, PresenterCount = 2, Participants = { { UserId = me, Name = "Tester", Bay = 1 } } })
for _, button in gui.ShowcasePanel:GetDescendants() do
	if button.ClassName == "TextButton" then
		button.Activated:Fire()
	end
end
Store.setState({ Phase = "Results", EndsAt = 20, Participants = {}, Results = {
	{ UserId = 99, Name = "Other", CarName = "Supercar", Average = 4.5, Votes = 2, Place = 1 },
	{ UserId = me, Name = "Tester", CarName = "Street Coupe", Average = 3, Votes = 1, Place = 2 },
} })
assert(gui.ResultsPanel.Visible, "results visible")
Store.setState({ Phase = "Lobby", Participants = {} })

local kinds = {}
for _, s in SENT or {} do
	kinds[s[1]] = (kinds[s[1]] or 0) + 1
end
print(string.format("client ok: %d option clicks, UpdateBuild=%d SetReady=%d SubmitRating=%d ShowOff=%d", clicks, kinds.UpdateBuild or 0, kinds.SetReady or 0, kinds.SubmitRating or 0, kinds.ShowOff or 0))
