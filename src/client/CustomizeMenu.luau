-- The build menu shown during the Customize phase:
--   * category tabs down the left edge
--   * option buttons / colour swatches for every slot in that category
--   * preview toggles (doors, hood, trunk, hydraulics, burnout) and a Ready button

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Net = require(ReplicatedStorage.Shared.Net)
local CarAnimator = require(script.Parent.CarAnimator)
local Hud = require(script.Parent.Hud)
local Store = require(script.Parent.Store)
local UI = require(script.Parent.UI)

local CustomizeMenu = {}

local T = UI.Theme
local player = Players.LocalPlayer

local PREVIEWS = {
	{ Flag = "DoorsOpen", Name = "Doors" },
	{ Flag = "HoodOpen", Name = "Hood" },
	{ Flag = "TrunkOpen", Name = "Trunk" },
	{ Flag = "Bounce", Name = "Hydraulics", RequiresSlot = "Suspension", RequiresValue = "Hydraulics" },
	{ Flag = "Burnout", Name = "Burnout" },
}

local selectedCategory = "Car"
local panel: Frame
local content: ScrollingFrame
local tabs: { [string]: TextButton } = {}
local previewButtons: { [string]: TextButton } = {}
local readyButton: TextButton
local actionBar: Frame

local function myCarName(): string
	return Store.carName(player.UserId)
end

local function slotVisible(slot: Catalog.Slot, build): boolean
	local cond = slot.ShowWhen
	if cond and build[cond.Slot] == cond.NotValue then
		return false
	end
	return true
end

local function choose(slotId: string, value: string)
	if Store.Build[slotId] == value then
		return
	end
	-- Optimistic update; the server echoes the authoritative build back.
	local build = table.clone(Store.Build)
	build[slotId] = value
	Store.setBuild(build)
	Net.UpdateBuild:FireServer(slotId, value)
end

local function sectionHeader(slot: Catalog.Slot, build, order: number)
	local header = UI.new("Frame", {
		Name = slot.Id .. "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = order,
		Parent = content,
	})
	UI.label({
		Text = string.upper(slot.Name),
		Font = T.FontHeavy,
		TextSize = 15,
		Size = UDim2.new(0.5, 0, 1, 0),
		Parent = header,
	})
	UI.label({
		Text = Catalog.GetOptionName(slot.Id, build[slot.Id]),
		TextColor3 = T.Accent,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.5, -4, 1, 0),
		Parent = header,
	})
end

local function optionGrid(slot: Catalog.Slot, build, order: number)
	local isCar = slot.Id == "Car"
	local grid = UI.new("Frame", {
		Name = slot.Id,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = content,
	}, {
		UI.new("UIGridLayout", {
			CellSize = if isCar then UDim2.new(1, 0, 0, 58) else UDim2.new(0.5, -4, 0, 38),
			CellPadding = UDim2.new(0, 6, 0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local options: { Catalog.Option } = slot.Options or {}
	for i, option in options do
		local selected = build[slot.Id] == option.Id
		local button = UI.button({
			Name = option.Id,
			Text = "",
			LayoutOrder = i,
			BackgroundColor3 = if selected then T.AccentDark else T.PanelLight,
			Parent = grid,
		}, function()
			choose(slot.Id, option.Id)
		end)
		if selected then
			UI.stroke(T.Accent, 2).Parent = button
		end
		if isCar then
			local spec = Catalog.CarsById[option.Id]
			UI.label({
				Text = option.Name,
				Font = T.FontHeavy,
				TextSize = 16,
				Position = UDim2.new(0, 12, 0, 6),
				Size = UDim2.new(1, -24, 0, 22),
				Parent = button,
			})
			UI.label({
				Text = spec and spec.Description or "",
				Font = T.FontBody,
				TextSize = 13,
				TextColor3 = T.SubText,
				TextWrapped = true,
				Position = UDim2.new(0, 12, 0, 28),
				Size = UDim2.new(1, -24, 0, 24),
				Parent = button,
			})
		else
			UI.label({
				Text = option.Name,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextWrapped = true,
				Size = UDim2.new(1, -8, 1, 0),
				Position = UDim2.new(0, 4, 0, 0),
				Parent = button,
			})
		end
	end
end

local function colorGrid(slot: Catalog.Slot, build, order: number)
	local grid = UI.new("Frame", {
		Name = slot.Id,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = content,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.new(0, 34, 0, 34),
			CellPadding = UDim2.new(0, 6, 0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i, entry in Catalog.Palette do
		local selected = build[slot.Id] == entry.Id
		local swatch = UI.button({
			Name = entry.Id,
			Text = "",
			LayoutOrder = i,
			BackgroundColor3 = entry.Color,
			Parent = grid,
		}, function()
			choose(slot.Id, entry.Id)
		end)
		UI.stroke(if selected then T.Text else Color3.new(0, 0, 0), if selected then 3 else 1, if selected then 0 else 0.6).Parent =
			swatch
	end
end

local function renderContent()
	for _, child in content:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	local build = Store.Build
	local order = 0
	for _, slot in Catalog.Slots do
		if slot.Category == selectedCategory and slotVisible(slot, build) then
			order += 1
			sectionHeader(slot, build, order)
			order += 1
			if slot.Kind == "Color" then
				colorGrid(slot, build, order)
			else
				optionGrid(slot, build, order)
			end
		end
	end
	for id, tab in tabs do
		tab.BackgroundColor3 = if id == selectedCategory then T.Accent else T.PanelLight
	end
end

local function refreshPreviewButtons()
	local build = Store.Build
	for _, preview in PREVIEWS do
		local button = previewButtons[preview.Flag]
		local available = preview.RequiresSlot == nil or build[preview.RequiresSlot] == preview.RequiresValue
		local on = CarAnimator.getOverride(myCarName(), preview.Flag)
		if not available and on then
			CarAnimator.setOverride(myCarName(), preview.Flag, false)
			on = false
		end
		button.BackgroundColor3 = if on then T.Accent elseif available then T.PanelLight else T.Panel
		button.TextColor3 = if available then T.Text else T.SubText
	end
	local ready = Store.amReady()
	readyButton.Text = if ready then "READY ✓" else "I'M READY"
	readyButton.BackgroundColor3 = if ready then T.Good else T.Accent
end

local function refreshVisibility()
	local visible = Store.State.Phase == "Customize" and Store.isParticipant()
	panel.Visible = visible
	actionBar.Visible = visible
	if not visible then
		CarAnimator.clearOverrides(myCarName())
	end
end

function CustomizeMenu.start(gui: ScreenGui)
	panel = UI.new("Frame", {
		Name = "CustomizePanel",
		Position = UDim2.new(0, 12, 0, 96),
		Size = UDim2.new(0, 470, 1, -108),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.06,
		Visible = false,
		Parent = gui,
	}, { UI.corner(12) }) :: Frame

	local tabList = UI.new("ScrollingFrame", {
		Name = "Tabs",
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(0, 118, 1, -16),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, { UI.list(6) })

	for i, category in Catalog.Categories do
		local tab = UI.button({
			Name = category.Id,
			Text = category.Icon .. "  " .. category.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 14,
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = i,
			Parent = tabList,
		}, function()
			selectedCategory = category.Id
			renderContent()
			content.CanvasPosition = Vector2.zero
		end)
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = tab })
		tabs[category.Id] = tab
	end

	content = UI.new("ScrollingFrame", {
		Name = "Content",
		Position = UDim2.new(0, 134, 0, 8),
		Size = UDim2.new(1, -142, 1, -16),
		BackgroundColor3 = T.Background,
		BackgroundTransparency = 0.3,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = T.Accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, { UI.corner(10), UI.list(6), UI.padding(10) }) :: ScrollingFrame

	-- Preview + Ready bar (bottom right)
	actionBar = UI.new("Frame", {
		Name = "ActionBar",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.new(0, 360, 0, 150),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.06,
		Visible = false,
		Parent = gui,
	}, { UI.corner(12), UI.padding(10) }) :: Frame

	UI.label({ Text = "PREVIEW", Font = T.FontHeavy, TextSize = 14, TextColor3 = T.SubText, Parent = actionBar })
	local previewRow = UI.new("Frame", {
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundTransparency = 1,
		Parent = actionBar,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.new(0.333, -5, 0, 32),
			CellPadding = UDim2.new(0, 6, 0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i, preview in PREVIEWS do
		previewButtons[preview.Flag] = UI.button({
			Text = preview.Name,
			TextSize = 13,
			LayoutOrder = i,
			Parent = previewRow,
		}, function()
			local build = Store.Build
			if preview.RequiresSlot and build[preview.RequiresSlot] ~= preview.RequiresValue then
				Hud.toast(nil, "Install Hydraulics in Performance to hit switches!")
				return
			end
			local name = myCarName()
			CarAnimator.setOverride(name, preview.Flag, not CarAnimator.getOverride(name, preview.Flag))
			refreshPreviewButtons()
		end)
	end

	readyButton = UI.button({
		Text = "I'M READY",
		Font = T.FontHeavy,
		TextSize = 18,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = T.Accent,
		Parent = actionBar,
	}, function()
		Net.SetReady:FireServer(not Store.amReady())
	end)

	Store.BuildChanged:Connect(function()
		renderContent()
		refreshPreviewButtons()
	end)
	Store.StateChanged:Connect(function(newState, previous)
		if newState.Phase == "Customize" and previous.Phase ~= "Customize" then
			selectedCategory = "Car"
			renderContent()
		end
		refreshVisibility()
		refreshPreviewButtons()
	end)

	renderContent()
	refreshPreviewButtons()
	refreshVisibility()
end

return CustomizeMenu
