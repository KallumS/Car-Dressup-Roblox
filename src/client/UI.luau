-- Tiny UI toolkit: instance factory + the game's visual theme.

local UI = {}

UI.Theme = {
	Background = Color3.fromRGB(14, 15, 19),
	Panel = Color3.fromRGB(22, 23, 29),
	PanelLight = Color3.fromRGB(34, 36, 44),
	Accent = Color3.fromRGB(255, 106, 0),
	AccentDark = Color3.fromRGB(170, 70, 0),
	Text = Color3.fromRGB(242, 242, 246),
	SubText = Color3.fromRGB(160, 163, 178),
	Good = Color3.fromRGB(60, 200, 110),
	Star = Color3.fromRGB(255, 200, 40),
	Font = Enum.Font.GothamBold,
	FontHeavy = Enum.Font.GothamBlack,
	FontBody = Enum.Font.Gotham,
}

-- UI.new("Frame", { Size = ..., [UI.Children] = {...} })
function UI.new(className: string, props: { [any]: any }?, children: { Instance }?): Instance
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				(inst :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.corner(radius: number?): UICorner
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 8) }) :: UICorner
end

function UI.stroke(color: Color3?, thickness: number?, transparency: number?): UIStroke
	return UI.new("UIStroke", {
		Color = color or UI.Theme.Accent,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}) :: UIStroke
end

function UI.padding(all: number): UIPadding
	local u = UDim.new(0, all)
	return UI.new("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u }) :: UIPadding
end

function UI.list(padding: number?, direction: Enum.FillDirection?, align: Enum.HorizontalAlignment?): UIListLayout
	return UI.new("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		FillDirection = direction or Enum.FillDirection.Vertical,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) :: UIListLayout
end

function UI.label(props: { [any]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = UI.Theme.Font,
		TextColor3 = UI.Theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 22),
	}
	for key, value in props do
		defaults[key] = value
	end
	return UI.new("TextLabel", defaults) :: TextLabel
end

function UI.button(props: { [any]: any }, onClick: (() -> ())?): TextButton
	local defaults = {
		BackgroundColor3 = UI.Theme.PanelLight,
		AutoButtonColor = true,
		Font = UI.Theme.Font,
		TextColor3 = UI.Theme.Text,
		TextSize = 15,
		Size = UDim2.new(0, 120, 0, 36),
	}
	for key, value in props do
		defaults[key] = value
	end
	local button = UI.new("TextButton", defaults, { UI.corner(8) }) :: TextButton
	if onClick then
		button.Activated:Connect(onClick)
	end
	return button
end

function UI.formatTime(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

return UI
