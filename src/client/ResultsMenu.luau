-- Leaderboard shown during Results. The top 3 cars are also parked on the
-- podium in the world (see MatchService); this panel lists everyone's score.

local Players = game:GetService("Players")

local Store = require(script.Parent.Store)
local UI = require(script.Parent.UI)

local ResultsMenu = {}

local T = UI.Theme
local MEDALS = { "🥇", "🥈", "🥉" }

function ResultsMenu.start(gui: ScreenGui)
	local panel = UI.new("Frame", {
		Name = "ResultsPanel",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 20),
		Size = UDim2.new(0, 360, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.06,
		Visible = false,
		Parent = gui,
	}, { UI.corner(14), UI.padding(14), UI.list(6), UI.stroke(T.Star, 2, 0.3) }) :: Frame

	local function render()
		for _, child in panel:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local state = Store.State
		local results = state.Results
		panel.Visible = state.Phase == "Results" and results ~= nil
		if not panel.Visible or not results then
			return
		end

		UI.label({
			Text = "FINAL STANDINGS",
			Font = T.FontHeavy,
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = 0,
			Parent = panel,
		})
		if #results == 0 then
			UI.label({ Text = "No cars were presented.", LayoutOrder = 1, Parent = panel })
			return
		end
		for i, entry in results do
			local isMe = entry.UserId == Players.LocalPlayer.UserId
			local row = UI.new("Frame", {
				Size = UDim2.new(1, 0, 0, 44),
				BackgroundColor3 = if isMe then T.AccentDark else T.PanelLight,
				LayoutOrder = i,
				Parent = panel,
			}, { UI.corner(8) })
			UI.label({
				Text = MEDALS[entry.Place] or ("#" .. entry.Place),
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(0, 44, 1, 0),
				Parent = row,
			})
			UI.label({
				Text = entry.Name,
				TextSize = 15,
				Position = UDim2.new(0, 48, 0, 4),
				Size = UDim2.new(1, -150, 0, 20),
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})
			UI.label({
				Text = entry.CarName,
				Font = T.FontBody,
				TextSize = 12,
				TextColor3 = T.SubText,
				Position = UDim2.new(0, 48, 0, 23),
				Size = UDim2.new(1, -150, 0, 16),
				Parent = row,
			})
			UI.label({
				Text = string.format("★ %.2f", entry.Average),
				TextColor3 = T.Star,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -100, 0, 4),
				Size = UDim2.new(0, 92, 0, 22),
				Parent = row,
			})
			UI.label({
				Text = string.format("%d vote%s", entry.Votes, if entry.Votes == 1 then "" else "s"),
				Font = T.FontBody,
				TextSize = 12,
				TextColor3 = T.SubText,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -100, 0, 25),
				Size = UDim2.new(0, 92, 0, 16),
				Parent = row,
			})
		end
	end

	Store.StateChanged:Connect(render)
	render()
end

return ResultsMenu
