-- Top bar (phase, timer, theme) and toast notifications.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local Store = require(script.Parent.Store)
local UI = require(script.Parent.UI)

local Hud = {}
Hud.holder = nil :: Instance?

local T = UI.Theme

local function phaseTitle(state): string
	local phase = state.Phase
	if phase == "Lobby" then
		return state.Message or "Waiting for players"
	elseif phase == "Intermission" then
		return "Match starting"
	elseif phase == "Customize" then
		return if Store.isParticipant() then "BUILD YOUR CAR" else "Match in progress"
	elseif phase == "Showcase" then
		return string.format("SHOWCASE  %d / %d", state.PresenterIndex or 0, state.PresenterCount or 0)
	elseif phase == "Results" then
		return "RESULTS"
	end
	return phase
end

function Hud.start(gui: ScreenGui)
	local bar = UI.new("Frame", {
		Name = "TopBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.new(0, 460, 0, 74),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.08,
		Parent = gui,
	}, { UI.corner(12), UI.stroke(T.Accent, 2, 0.3) }) :: Frame

	local title = UI.label({
		Name = "Title",
		Position = UDim2.new(0, 16, 0, 8),
		Size = UDim2.new(1, -130, 0, 30),
		Font = T.FontHeavy,
		TextSize = 22,
		TextScaled = true,
		Parent = bar,
	})
	UI.new("UITextSizeConstraint", { MaxTextSize = 24, Parent = title })

	local subtitle = UI.label({
		Name = "Subtitle",
		Position = UDim2.new(0, 16, 0, 40),
		Size = UDim2.new(1, -130, 0, 24),
		Font = T.FontBody,
		TextSize = 15,
		TextColor3 = T.SubText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = bar,
	})

	local timer = UI.label({
		Name = "Timer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 110, 0, 50),
		Font = T.FontHeavy,
		TextSize = 34,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = T.Accent,
		Parent = bar,
	})

	local function refresh()
		local state = Store.State
		title.Text = phaseTitle(state)
		if state.Theme then
			subtitle.Text = "Theme: " .. state.Theme.Name .. " - " .. state.Theme.Description
		elseif state.Phase == "Lobby" then
			subtitle.Text = string.format("%d player(s) in server", state.PlayerCount or 0)
		elseif state.Phase == "Intermission" then
			subtitle.Text = "Get ready to pick your ride!"
		else
			subtitle.Text = ""
		end
	end
	Store.StateChanged:Connect(refresh)
	refresh()

	RunService.RenderStepped:Connect(function()
		if Store.State.EndsAt then
			local left = Store.timeLeft()
			timer.Text = UI.formatTime(left)
			timer.TextColor3 = if left <= 10 and Store.State.Phase == "Customize" then Color3.fromRGB(255, 60, 60) else T.Accent
		else
			timer.Text = ""
		end
	end)

	-- Toasts ------------------------------------------------------------------
	local toastHolder = UI.new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 94),
		Size = UDim2.new(0, 420, 0, 200),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { UI.list(6, nil, Enum.HorizontalAlignment.Center) })

	Net.Notify.OnClientEvent:Connect(function(text: string)
		Hud.toast(toastHolder, text)
	end)
	Hud.holder = toastHolder
end

function Hud.toast(holder: Instance?, text: string)
	holder = holder or Hud.holder
	if not holder then
		return
	end
	local toast = UI.label({
		Text = text,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 0.1,
		BackgroundColor3 = T.Background,
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = T.Font,
		TextSize = 16,
		Parent = holder,
	})
	UI.corner(8).Parent = toast
	task.delay(3, function()
		local tween = TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		toast:Destroy()
	end)
end

return Hud
