-- Vinyls and decals, drawn in up to three stacked layers.
--
-- Side designs are painted with SurfaceGuis. Every side panel (nose, bay wall,
-- cabin section, door, trunk wall) gets a window into one shared "canvas" that
-- spans the whole side of the car, so designs flow continuously across panels
-- and doors carry their slice when they open.
--
-- Canvas coordinates: u = 0 at the front bumper -> 1 at the rear,
--                     v = 0 at the top of the body -> 1 at the sill.
--
-- Racing stripes run over the top of the car and are thin welded parts.

local Util = require(script.Parent.Util)

local Vinyls = {}

local PIXELS_PER_STUD = 24
local SPONSORS = { "TURBO", "NITRO", "APEX", "V8", "RACING" }

type Element = {
	U: number,
	V: number,
	W: number,
	H: number,
	Color: Color3?,
	Round: boolean?,
	Gradient: { Rotation: number, Transparency: NumberSequence, Color: ColorSequence? }?,
	Text: string?,
	TextColor: Color3?,
}

-- Seeded pseudo random so every panel draws the same camo blobs.
local function seeded(seed: number)
	local rng = Random.new(seed)
	return function(a: number, b: number): number
		return a + (b - a) * rng:NextNumber()
	end
end

-- Each pattern returns a list of elements in canvas space (unmirrored).
local PATTERNS: { [string]: (ctx: any, color: Color3) -> { Element } } = {}

PATTERNS.SideStripe = function(_, color)
	return {
		{ U = 0.02, V = 0.26, W = 0.96, H = 0.16, Color = color },
		{ U = 0.02, V = 0.47, W = 0.96, H = 0.04, Color = color },
	}
end

PATTERNS.TwoTone = function(_, color)
	return { { U = 0, V = 0.56, W = 1, H = 0.44, Color = color } }
end

PATTERNS.Fade = function(_, color)
	return {
		{
			U = 0,
			V = 0,
			W = 1,
			H = 1,
			Color = color,
			Gradient = {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.35, 1),
					NumberSequenceKeypoint.new(1, 0),
				}),
			},
		},
	}
end

PATTERNS.Flames = function(_, color)
	local hot = color:Lerp(Color3.fromRGB(255, 230, 90), 0.65)
	local gradient = {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Color = ColorSequence.new(hot, color),
	}
	local tongues = {
		{ 0.18, 0.42 },
		{ 0.31, 0.6 },
		{ 0.44, 0.5 },
		{ 0.57, 0.66 },
		{ 0.7, 0.44 },
		{ 0.82, 0.32 },
	}
	local out: { Element } = { { U = 0, V = 0.12, W = 0.1, H = 0.88, Color = hot } }
	for _, t in tongues do
		table.insert(out, { U = 0.02, V = t[1], W = t[2], H = 0.12, Color = color, Round = true, Gradient = gradient })
	end
	return out
end

PATTERNS.Slash = function(_, color)
	return {
		{
			U = 0.26,
			V = 0,
			W = 0.5,
			H = 1,
			Color = color,
			Gradient = {
				Rotation = 60,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.3, 1),
					NumberSequenceKeypoint.new(0.301, 0),
					NumberSequenceKeypoint.new(0.42, 0),
					NumberSequenceKeypoint.new(0.421, 1),
					NumberSequenceKeypoint.new(0.5, 1),
					NumberSequenceKeypoint.new(0.501, 0),
					NumberSequenceKeypoint.new(0.56, 0),
					NumberSequenceKeypoint.new(0.561, 1),
					NumberSequenceKeypoint.new(0.62, 1),
					NumberSequenceKeypoint.new(0.621, 0),
					NumberSequenceKeypoint.new(0.645, 0),
					NumberSequenceKeypoint.new(0.646, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			},
		},
	}
end

PATTERNS.Checker = function(ctx, color)
	local out: { Element } = {}
	local cols, rows = 8, 4
	local u0, v0 = 0.7, 0.18
	local cellV = 0.64 / rows
	-- Square cells in studs: convert the vertical size into canvas-u units.
	local cellU = cellV * ctx.h / ctx.L
	for cx = 0, cols - 1 do
		for cy = 0, rows - 1 do
			if (cx + cy) % 2 == 0 then
				table.insert(out, { U = u0 + cx * cellU, V = v0 + cy * cellV, W = cellU, H = cellV, Color = color })
			end
		end
	end
	return out
end

PATTERNS.Camo = function(ctx, color)
	local rand = seeded(1337)
	local out: { Element } = {}
	local aspect = ctx.h / ctx.L
	for _ = 1, 26 do
		local size = rand(0.25, 0.55)
		table.insert(out, {
			U = rand(-0.05, 1),
			V = rand(-0.2, 0.9),
			W = size * aspect * rand(1.2, 2.6),
			H = size,
			Color = color,
			Round = true,
		})
	end
	return out
end

PATTERNS.Pinstripes = function(_, color)
	local fade = {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.75, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}
	return {
		{ U = 0.05, V = 0.2, W = 0.85, H = 0.025, Color = color, Gradient = fade },
		{ U = 0.05, V = 0.25, W = 0.8, H = 0.025, Color = color, Gradient = fade },
		{ U = 0.05, V = 0.3, W = 0.75, H = 0.025, Color = color, Gradient = fade },
	}
end

PATTERNS.Sponsors = function(ctx, color)
	local aspect = ctx.h / ctx.L
	local out: { Element } = {}
	local spots = {
		{ 0.08, 0.55, 3.2 },
		{ 0.42, 0.62, 3.6 },
		{ 0.73, 0.5, 2.6 },
	}
	for i, spot in spots do
		local word = SPONSORS[(ctx.ownerSeed + i) % #SPONSORS + 1]
		table.insert(out, {
			U = spot[1],
			V = spot[2],
			W = spot[3] * 0.24 * aspect,
			H = 0.24,
			Text = word,
			TextColor = color,
		})
	end
	return out
end

PATTERNS.RaceNumber = function(ctx, color)
	local aspect = ctx.h / ctx.L
	local size = 0.62
	local doorMidU = (ctx.doorZ0 + ctx.doorLen / 2 - ctx.zF) / ctx.L
	local w = size * aspect
	return {
		{ U = doorMidU - w / 2, V = 0.18, W = w, H = size, Color = color, Round = true },
		{
			U = doorMidU - w / 2,
			V = 0.18,
			W = w,
			H = size,
			Text = string.format("%02d", ctx.ownerSeed % 100),
			TextColor = Util.contrast(color),
		},
	}
end

local function makeElement(el: Element, mirrored: boolean, z: number): GuiObject
	local u = if mirrored then 1 - el.U - el.W else el.U
	local obj: GuiObject
	if el.Text then
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Text = el.Text
		label.TextColor3 = el.TextColor or Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		obj = label
	else
		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = el.Color or Color3.new(1, 1, 1)
		frame.BorderSizePixel = 0
		obj = frame
	end
	obj.Position = UDim2.fromScale(u, el.V)
	obj.Size = UDim2.fromScale(el.W, el.H)
	obj.ZIndex = z

	if el.Round then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = obj
	end
	if el.Gradient then
		local gradient = Instance.new("UIGradient")
		local rotation = el.Gradient.Rotation
		gradient.Rotation = if mirrored then 180 - rotation else rotation
		gradient.Transparency = el.Gradient.Transparency
		if el.Gradient.Color then
			gradient.Color = el.Gradient.Color
		end
		gradient.Parent = obj
	end
	return obj
end

-- Draws all side layers onto one registered panel.
local function paintPanel(ctx, surface, layers: { { Elements: { Element }, Z: number } })
	local part: BasePart = surface.Part
	local side: number = surface.Side
	local partLen = surface.Z1 - surface.Z0
	local partH = surface.Y1 - surface.Y0
	if partLen <= 0 or partH <= 0 then
		return
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Vinyl"
	gui.Face = if side < 0 then Enum.NormalId.Left else Enum.NormalId.Right
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 1
	gui.ZOffset = 0.5
	gui.Parent = part

	local clip = Instance.new("Frame")
	clip.Name = "Clip"
	clip.BackgroundTransparency = 1
	clip.Size = UDim2.fromScale(1, 1)
	clip.ClipsDescendants = true
	clip.Parent = gui

	-- Left faces read front->rear, right faces read rear->front (mirrored).
	local mirrored = side > 0
	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.BackgroundTransparency = 1
	canvas.Size = UDim2.fromScale(ctx.L / partLen, ctx.h / partH)
	local offsetZ = if mirrored then (ctx.zR - surface.Z1) else (surface.Z0 - ctx.zF)
	local offsetY = ctx.yT - surface.Y1
	canvas.Position = UDim2.fromScale(-offsetZ / partLen, -offsetY / partH)
	canvas.Parent = clip

	for _, layer in layers do
		for _, el in layer.Elements do
			makeElement(el, mirrored, layer.Z).Parent = canvas
		end
	end
end

local function racingStripes(ctx, color: Color3, layerIndex: number)
	for _, top in ctx.topSurfaces do
		local width = top.Width * 0.11
		local gap = top.Width * 0.05
		for _, sign in { -1, 1 } do
			local cf = top.CFrame * CFrame.new(sign * (gap + width / 2), 0.012 + layerIndex * 0.006, 0)
			Util.part(ctx, {
				Name = "RacingStripe",
				Size = Vector3.new(width, 0.02, top.Length),
				CFrame = cf,
				World = true,
				Color = color,
				Material = Enum.Material.SmoothPlastic,
			}, top.Anchor)
		end
	end
end

function Vinyls.build(ctx)
	local layers = {}
	for i = 1, 3 do
		local pattern = ctx.build["Vinyl" .. i]
		local color = ctx.colors["Vinyl" .. i]
		if pattern == "RacingStripes" then
			racingStripes(ctx, color, i)
		elseif pattern and PATTERNS[pattern] then
			table.insert(layers, { Elements = PATTERNS[pattern](ctx, color), Z = i + 1 })
		end
	end
	if #layers == 0 then
		return
	end
	for _, surface in ctx.sideSurfaces do
		paintPanel(ctx, surface, layers)
	end
end

return Vinyls
