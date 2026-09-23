-- Bottom panel during the Showcase: rate the car on stage (1-5 stars), or,
-- when it's your car, buttons to show it off to everyone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Store = require(script.Parent.Store)
local UI = require(script.Parent.UI)

local ShowcaseMenu = {}

local T = UI.Theme
local player = Players.LocalPlayer

local SHOW_OFF = {
	{ Flag = "DoorsOpen", Name = "Doors" },
	{ Flag = "HoodOpen", Name = "Hood" },
	{ Flag = "TrunkOpen", Name = "Trunk" },
	{ Flag = "Bounce", Name = "Hit Switches" },
	{ Flag = "Burnout", Name = "Burnout" },
}

function ShowcaseMenu.start(gui: ScreenGui)
	local myRatings: { [number]: number } = {}

	local panel = UI.new("Frame", {
		Name = "ShowcasePanel",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(0, 520, 0, 150),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.06,
		Visible = false,
		Parent = gui,
	}, { UI.corner(14), UI.stroke(T.Accent, 2, 0.4) }) :: Frame

	local title = UI.label({
		Font = T.FontHeavy,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0, 10),
		Size = UDim2.new(1, 0, 0, 28),
		Parent = panel,
	})
	local subtitle = UI.label({
		Font = T.FontBody,
		TextSize = 15,
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(1, 0, 0, 20),
		Parent = panel,
	})

	-- Star rating row
	local starRow = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.new(0, 5 * 64, 0, 60),
		BackgroundTransparency = 1,
		Parent = panel,
	}, { UI.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center) })

	local stars: { TextButton } = {}
	local function paintStars()
		local current = myRatings[Store.State.Presenter or 0] or 0
		for i, star in stars do
			star.TextColor3 = if i <= current then T.Star else Color3.fromRGB(80, 82, 94)
		end
	end
	for i = Config.MinStars, Config.MaxStars do
		local star = UI.button({
			Text = "★",
			Font = T.FontHeavy,
			TextSize = 44,
			Size = UDim2.new(0, 56, 0, 56),
			BackgroundTransparency = 1,
			LayoutOrder = i,
			Parent = starRow,
		}, function()
			local presenter = Store.State.Presenter
			if not presenter or presenter == player.UserId then
				return
			end
			myRatings[presenter] = i
			paintStars()
			Net.SubmitRating:FireServer(presenter, i)
		end)
		table.insert(stars, star)
	end

	-- Show-off row (only for the presenter)
	local showRow = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 78),
		Size = UDim2.new(1, -24, 0, 44),
		BackgroundTransparency = 1,
		Parent = panel,
	}, { UI.list(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center) })
	for i, action in SHOW_OFF do
		UI.button({
			Text = action.Name,
			TextSize = 14,
			Size = UDim2.new(0, 92, 0, 40),
			LayoutOrder = i,
			BackgroundColor3 = T.Accent,
			Parent = showRow,
		}, function()
			Net.ShowOff:FireServer(action.Flag)
		end)
	end

	local function refresh()
		local state = Store.State
		local visible = state.Phase == "Showcase" and state.Presenter ~= nil
		panel.Visible = visible
		if not visible then
			return
		end
		local mine = state.Presenter == player.UserId
		title.Text = string.format("%s's %s", state.PresenterName or "?", state.PresenterCar or "Car")
		if mine then
			subtitle.Text = "You're on stage! Show it off:"
		else
			subtitle.Text = "Rate this ride"
		end
		starRow.Visible = not mine
		showRow.Visible = mine
		paintStars()
	end

	Store.StateChanged:Connect(function(newState, previous)
		if newState.Phase ~= "Showcase" and previous.Phase == "Showcase" then
			table.clear(myRatings)
		end
		refresh()
	end)
	refresh()
end

return ShowcaseMenu
