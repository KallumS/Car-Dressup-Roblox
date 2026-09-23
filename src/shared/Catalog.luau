-- Every customization the player can make: base cars, slots, options and the
-- colour palette. Shared by the server (validation + building) and the client
-- (menus). Add a new option here and teach CarBuilder how to draw it.

local Catalog = {}

export type Option = { Id: string, Name: string }
export type Slot = {
	Id: string,
	Category: string,
	Name: string,
	Kind: "Option" | "Color",
	Options: { Option }?,
	Default: string,
	-- Slot is only relevant when another slot has one of these values (UI hint).
	ShowWhen: { Slot: string, NotValue: string }?,
}

-- Colour palette ------------------------------------------------------------

Catalog.Palette = {
	{ Id = "JetBlack", Name = "Jet Black", Color = Color3.fromRGB(16, 16, 20) },
	{ Id = "Gunmetal", Name = "Gunmetal", Color = Color3.fromRGB(62, 66, 74) },
	{ Id = "Silver", Name = "Silver", Color = Color3.fromRGB(192, 196, 202) },
	{ Id = "ArcticWhite", Name = "Arctic White", Color = Color3.fromRGB(242, 242, 244) },
	{ Id = "Crimson", Name = "Crimson", Color = Color3.fromRGB(150, 12, 28) },
	{ Id = "RaceRed", Name = "Race Red", Color = Color3.fromRGB(226, 32, 32) },
	{ Id = "BlazeOrange", Name = "Blaze Orange", Color = Color3.fromRGB(255, 112, 20) },
	{ Id = "Sunburst", Name = "Sunburst Yellow", Color = Color3.fromRGB(255, 206, 32) },
	{ Id = "Gold", Name = "Gold", Color = Color3.fromRGB(212, 172, 58) },
	{ Id = "Bronze", Name = "Bronze", Color = Color3.fromRGB(160, 102, 48) },
	{ Id = "Lime", Name = "Lime", Color = Color3.fromRGB(140, 228, 40) },
	{ Id = "RacingGreen", Name = "Racing Green", Color = Color3.fromRGB(12, 86, 48) },
	{ Id = "Teal", Name = "Teal", Color = Color3.fromRGB(0, 150, 150) },
	{ Id = "SkyBlue", Name = "Sky Blue", Color = Color3.fromRGB(110, 190, 255) },
	{ Id = "ElectricBlue", Name = "Electric Blue", Color = Color3.fromRGB(24, 108, 255) },
	{ Id = "Midnight", Name = "Midnight Blue", Color = Color3.fromRGB(16, 28, 88) },
	{ Id = "Purple", Name = "Royal Purple", Color = Color3.fromRGB(104, 40, 172) },
	{ Id = "HotPink", Name = "Hot Pink", Color = Color3.fromRGB(255, 52, 150) },
	{ Id = "ToxicGreen", Name = "Toxic Green", Color = Color3.fromRGB(57, 255, 20) },
	{ Id = "CyberCyan", Name = "Cyber Cyan", Color = Color3.fromRGB(0, 240, 255) },
	{ Id = "Ultraviolet", Name = "Ultraviolet", Color = Color3.fromRGB(170, 60, 255) },
	{ Id = "Magenta", Name = "Magenta", Color = Color3.fromRGB(255, 0, 200) },
	{ Id = "Xenon", Name = "Xenon", Color = Color3.fromRGB(214, 232, 255) },
	{ Id = "Halogen", Name = "Halogen", Color = Color3.fromRGB(255, 222, 160) },
}

Catalog.PaletteById = {}
for _, entry in Catalog.Palette do
	Catalog.PaletteById[entry.Id] = entry
end

function Catalog.GetColor(colorId: string): Color3
	local entry = Catalog.PaletteById[colorId]
	return if entry then entry.Color else Color3.new(1, 1, 1)
end

-- Base cars -------------------------------------------------------------------
-- Dimensions are in studs. The car faces -Z; y = 0 is the ground.

export type CarSpec = {
	Id: string,
	Name: string,
	Description: string,
	Length: number,
	Width: number,
	Clearance: number,
	BodyHeight: number,
	NoseLength: number,
	NoseBoxRatio: number,
	CabinLength: number,
	CabinHeight: number,
	CabinZ: number,
	WindshieldLength: number,
	RearWindowLength: number,
	WheelRadius: number,
	WheelWidth: number,
	FrontAxle: number,
	RearAxle: number,
	Extras: { string },
}

Catalog.Cars = {
	{
		Id = "Coupe",
		Name = "Street Coupe",
		Description = "Balanced tuner coupe. A blank canvas.",
		Length = 16,
		Width = 7,
		Clearance = 0.9,
		BodyHeight = 2.2,
		NoseLength = 1.3,
		NoseBoxRatio = 0.6,
		CabinLength = 4.5,
		CabinHeight = 2.0,
		CabinZ = 0.8,
		WindshieldLength = 2.4,
		RearWindowLength = 2.0,
		WheelRadius = 1.35,
		WheelWidth = 1.1,
		FrontAxle = -5.2,
		RearAxle = 5.0,
		Extras = {},
	},
	{
		Id = "Muscle",
		Name = "Muscle Car",
		Description = "Long hood, big V8, bigger attitude.",
		Length = 17.5,
		Width = 7.4,
		Clearance = 0.9,
		BodyHeight = 2.5,
		NoseLength = 1.2,
		NoseBoxRatio = 0.7,
		CabinLength = 4.2,
		CabinHeight = 1.9,
		CabinZ = 1.8,
		WindshieldLength = 2.2,
		RearWindowLength = 1.8,
		WheelRadius = 1.45,
		WheelWidth = 1.25,
		FrontAxle = -5.8,
		RearAxle = 5.6,
		Extras = { "HoodBulge" },
	},
	{
		Id = "Supercar",
		Name = "Supercar",
		Description = "Low, wide and wedge-shaped. Mid-engine drama.",
		Length = 16.5,
		Width = 7.8,
		Clearance = 0.6,
		BodyHeight = 1.9,
		NoseLength = 2.2,
		NoseBoxRatio = 0.45,
		CabinLength = 3.4,
		CabinHeight = 1.6,
		CabinZ = 0.2,
		WindshieldLength = 3.4,
		RearWindowLength = 3.2,
		WheelRadius = 1.35,
		WheelWidth = 1.3,
		FrontAxle = -5.4,
		RearAxle = 5.4,
		Extras = { "SideIntakes" },
	},
	{
		Id = "Hatch",
		Name = "Hot Hatch",
		Description = "Short, tall and tossable. JDM energy.",
		Length = 13.5,
		Width = 6.6,
		Clearance = 0.9,
		BodyHeight = 2.2,
		NoseLength = 1.0,
		NoseBoxRatio = 0.6,
		CabinLength = 5.0,
		CabinHeight = 2.3,
		CabinZ = 1.4,
		WindshieldLength = 2.0,
		RearWindowLength = 0.8,
		WheelRadius = 1.25,
		WheelWidth = 1.05,
		FrontAxle = -4.4,
		RearAxle = 4.4,
		Extras = {},
	},
	{
		Id = "Cruiser",
		Name = "Classic Cruiser",
		Description = "Long chrome-trimmed land yacht. Lowrider royalty.",
		Length = 19,
		Width = 7.4,
		Clearance = 0.8,
		BodyHeight = 2.3,
		NoseLength = 1.3,
		NoseBoxRatio = 0.75,
		CabinLength = 6.0,
		CabinHeight = 2.0,
		CabinZ = 0.8,
		WindshieldLength = 2.2,
		RearWindowLength = 2.0,
		WheelRadius = 1.3,
		WheelWidth = 1.15,
		FrontAxle = -6.4,
		RearAxle = 6.2,
		Extras = { "ChromeTrim" },
	},
} :: { CarSpec }

Catalog.CarsById = {} :: { [string]: CarSpec }
for _, car in Catalog.Cars do
	Catalog.CarsById[car.Id] = car
end

-- Categories (tabs in the customize menu, in order) ---------------------------

Catalog.Categories = {
	{ Id = "Car", Name = "Car", Icon = "🚗" },
	{ Id = "BodyKit", Name = "Body Kit", Icon = "🛠" },
	{ Id = "Lights", Name = "Lights", Icon = "💡" },
	{ Id = "Paint", Name = "Paint", Icon = "🎨" },
	{ Id = "Vinyls", Name = "Vinyls", Icon = "🏁" },
	{ Id = "Wheels", Name = "Wheels", Icon = "🛞" },
	{ Id = "Audio", Name = "Audio", Icon = "🔊" },
	{ Id = "Neon", Name = "Neon", Icon = "🌈" },
	{ Id = "Performance", Name = "Performance", Icon = "⚙" },
	{ Id = "Doors", Name = "Doors", Icon = "🚪" },
}

-- Slots -------------------------------------------------------------------------

local function opts(list: { { string } }): { Option }
	local out = {}
	for _, pair in list do
		table.insert(out, { Id = pair[1], Name = pair[2] })
	end
	return out
end

local carOptions = {}
for _, car in Catalog.Cars do
	table.insert(carOptions, { Id = car.Id, Name = car.Name })
end

local VINYL_OPTIONS = opts({
	{ "None", "None" },
	{ "RacingStripes", "Racing Stripes" },
	{ "SideStripe", "Side Stripe" },
	{ "TwoTone", "Two-Tone" },
	{ "Fade", "Fade" },
	{ "Flames", "Flames" },
	{ "Slash", "Slash" },
	{ "Checker", "Checkered" },
	{ "Camo", "Camo" },
	{ "Pinstripes", "Pinstripes" },
	{ "Sponsors", "Sponsor Decals" },
	{ "RaceNumber", "Race Number" },
})

Catalog.Slots = {
	-- Car
	{ Id = "Car", Category = "Car", Name = "Base Car", Kind = "Option", Options = carOptions, Default = "Coupe" },

	-- Body kit
	{
		Id = "FrontBumper",
		Category = "BodyKit",
		Name = "Front Bumper",
		Kind = "Option",
		Options = opts({
			{ "Stock", "Stock" },
			{ "Lip", "Street Lip" },
			{ "Splitter", "Race Splitter" },
			{ "Canards", "Aggressive Canards" },
			{ "BullBar", "Off-road Bull Bar" },
		}),
		Default = "Stock",
	},
	{
		Id = "RearBumper",
		Category = "BodyKit",
		Name = "Rear Bumper",
		Kind = "Option",
		Options = opts({
			{ "Stock", "Stock" },
			{ "Diffuser", "Diffuser" },
			{ "QuadExhaust", "Quad Exhaust" },
			{ "RaceDiffuser", "Race Diffuser" },
		}),
		Default = "Stock",
	},
	{
		Id = "SideSkirts",
		Category = "BodyKit",
		Name = "Side Skirts",
		Kind = "Option",
		Options = opts({ { "None", "None" }, { "Slim", "Slim" }, { "Aero", "Carbon Aero" }, { "MudFlaps", "Rally Mud Flaps" } }),
		Default = "None",
	},
	{
		Id = "Spoiler",
		Category = "BodyKit",
		Name = "Spoiler",
		Kind = "Option",
		Options = opts({
			{ "None", "None" },
			{ "Lip", "Trunk Lip" },
			{ "Ducktail", "Ducktail" },
			{ "GTWing", "GT Wing" },
			{ "SwanNeck", "Swan Neck" },
			{ "DragWing", "Drag Wing" },
		}),
		Default = "None",
	},
	{
		Id = "Hood",
		Category = "BodyKit",
		Name = "Hood",
		Kind = "Option",
		Options = opts({
			{ "Stock", "Stock" },
			{ "Vented", "Vented" },
			{ "Carbon", "Carbon Fibre" },
			{ "Scoop", "Hood Scoop" },
			{ "Blower", "Supercharger Blower" },
		}),
		Default = "Stock",
	},
	{
		Id = "Roof",
		Category = "BodyKit",
		Name = "Roof",
		Kind = "Option",
		Options = opts({
			{ "None", "None" },
			{ "Scoop", "Roof Scoop" },
			{ "Vortex", "Vortex Generators" },
			{ "RoofWing", "Roof Wing" },
			{ "LightBar", "Rally Light Bar" },
		}),
		Default = "None",
	},
	{
		Id = "Widebody",
		Category = "BodyKit",
		Name = "Widebody",
		Kind = "Option",
		Options = opts({ { "Off", "Off" }, { "Flares", "Bolt-on Flares" }, { "Full", "Full Widebody" } }),
		Default = "Off",
	},

	-- Lights & mirrors
	{
		Id = "Headlights",
		Category = "Lights",
		Name = "Headlights",
		Kind = "Option",
		Options = opts({
			{ "Stock", "Stock" },
			{ "AngelEyes", "Angel Eyes" },
			{ "LEDStrip", "LED Strip" },
			{ "QuadRound", "Quad Round" },
			{ "PopUp", "Pop-Ups" },
		}),
		Default = "Stock",
	},
	{ Id = "HeadlightColor", Category = "Lights", Name = "Headlight Tint", Kind = "Color", Default = "Xenon" },
	{
		Id = "Taillights",
		Category = "Lights",
		Name = "Taillights",
		Kind = "Option",
		Options = opts({
			{ "Stock", "Stock" },
			{ "LightBar", "Full-Width Bar" },
			{ "RoundQuad", "Round Quad" },
			{ "TriBar", "Tri-Bar" },
			{ "Smoked", "Smoked" },
		}),
		Default = "Stock",
	},
	{
		Id = "Mirrors",
		Category = "Lights",
		Name = "Side Mirrors",
		Kind = "Option",
		Options = opts({
			{ "Stock", "Stock" },
			{ "Aero", "Aero" },
			{ "CarbonStalk", "Carbon Stalk" },
			{ "Fender", "JDM Fender" },
			{ "Bullet", "Chrome Bullet" },
		}),
		Default = "Stock",
	},

	-- Paint
	{ Id = "BodyColor", Category = "Paint", Name = "Base Coat", Kind = "Color", Default = "RaceRed" },
	{
		Id = "Finish",
		Category = "Paint",
		Name = "Finish",
		Kind = "Option",
		Options = opts({
			{ "Gloss", "Gloss" },
			{ "Matte", "Matte" },
			{ "Satin", "Satin" },
			{ "Metallic", "Metallic" },
			{ "Pearl", "Pearl" },
			{ "Chrome", "Chrome Wrap" },
		}),
		Default = "Gloss",
	},
	{
		Id = "WindowTint",
		Category = "Paint",
		Name = "Window Tint",
		Kind = "Option",
		Options = opts({ { "Clear", "Clear" }, { "Light", "Light" }, { "Dark", "Dark" }, { "Limo", "Limo" } }),
		Default = "Light",
	},
	{ Id = "CaliperColor", Category = "Paint", Name = "Brake Calipers", Kind = "Color", Default = "RaceRed" },
	{ Id = "EngineColor", Category = "Paint", Name = "Engine", Kind = "Color", Default = "Gunmetal" },

	-- Vinyls (three stackable layers)
	{ Id = "Vinyl1", Category = "Vinyls", Name = "Layer 1", Kind = "Option", Options = VINYL_OPTIONS, Default = "None" },
	{
		Id = "Vinyl1Color",
		Category = "Vinyls",
		Name = "Layer 1 Colour",
		Kind = "Color",
		Default = "ArcticWhite",
		ShowWhen = { Slot = "Vinyl1", NotValue = "None" },
	},
	{ Id = "Vinyl2", Category = "Vinyls", Name = "Layer 2", Kind = "Option", Options = VINYL_OPTIONS, Default = "None" },
	{
		Id = "Vinyl2Color",
		Category = "Vinyls",
		Name = "Layer 2 Colour",
		Kind = "Color",
		Default = "JetBlack",
		ShowWhen = { Slot = "Vinyl2", NotValue = "None" },
	},
	{ Id = "Vinyl3", Category = "Vinyls", Name = "Layer 3", Kind = "Option", Options = VINYL_OPTIONS, Default = "None" },
	{
		Id = "Vinyl3Color",
		Category = "Vinyls",
		Name = "Layer 3 Colour",
		Kind = "Color",
		Default = "Sunburst",
		ShowWhen = { Slot = "Vinyl3", NotValue = "None" },
	},

	-- Wheels
	{
		Id = "Rims",
		Category = "Wheels",
		Name = "Rims",
		Kind = "Option",
		Options = opts({
			{ "Stock", "Stock" },
			{ "FiveSpoke", "Five Spoke" },
			{ "DeepDish", "Deep Dish" },
			{ "Mesh", "Mesh" },
			{ "Turbofan", "Turbofan" },
			{ "Spinners", "Spinners" },
			{ "Beadlock", "Beadlock" },
		}),
		Default = "Stock",
	},
	{ Id = "RimColor", Category = "Wheels", Name = "Rim Colour", Kind = "Color", Default = "Silver" },
	{
		Id = "Tires",
		Category = "Wheels",
		Name = "Tyres",
		Kind = "Option",
		Options = opts({
			{ "Street", "Street" },
			{ "LowProfile", "Low Profile" },
			{ "Offroad", "Off-road" },
			{ "Whitewall", "Whitewall" },
			{ "DragSlicks", "Drag Slicks" },
		}),
		Default = "Street",
	},
	{ Id = "TireSmoke", Category = "Wheels", Name = "Tyre Smoke", Kind = "Color", Default = "ArcticWhite" },

	-- Audio
	{
		Id = "Trunk",
		Category = "Audio",
		Name = "Trunk Setup",
		Kind = "Option",
		Options = opts({
			{ "Empty", "Empty" },
			{ "SingleSub", "Single Sub" },
			{ "DualSubs", "Dual Subs" },
			{ "AmpRack", "Subs + Amp Rack" },
			{ "SubWall", "Wall of Subs" },
		}),
		Default = "Empty",
	},
	{
		Id = "AudioAccent",
		Category = "Audio",
		Name = "Audio Accent",
		Kind = "Color",
		Default = "ElectricBlue",
		ShowWhen = { Slot = "Trunk", NotValue = "Empty" },
	},

	-- Neon
	{
		Id = "Underglow",
		Category = "Neon",
		Name = "Underglow",
		Kind = "Option",
		Options = opts({ { "Off", "Off" }, { "Solid", "Solid" }, { "Pulse", "Pulse" } }),
		Default = "Off",
	},
	{
		Id = "UnderglowColor",
		Category = "Neon",
		Name = "Underglow Colour",
		Kind = "Color",
		Default = "CyberCyan",
		ShowWhen = { Slot = "Underglow", NotValue = "Off" },
	},
	{
		Id = "InteriorNeon",
		Category = "Neon",
		Name = "Interior Neon",
		Kind = "Option",
		Options = opts({ { "Off", "Off" }, { "Solid", "Solid" }, { "Pulse", "Pulse" } }),
		Default = "Off",
	},
	{
		Id = "InteriorColor",
		Category = "Neon",
		Name = "Interior Colour",
		Kind = "Color",
		Default = "Magenta",
		ShowWhen = { Slot = "InteriorNeon", NotValue = "Off" },
	},

	-- Performance
	{
		Id = "Suspension",
		Category = "Performance",
		Name = "Suspension",
		Kind = "Option",
		Options = opts({
			{ "Stock", "Stock" },
			{ "Lowered", "Lowered" },
			{ "Slammed", "Slammed" },
			{ "Lifted", "Lifted" },
			{ "Hydraulics", "Hydraulics" },
		}),
		Default = "Stock",
	},

	-- Doors
	{
		Id = "Doors",
		Category = "Doors",
		Name = "Door Style",
		Kind = "Option",
		Options = opts({
			{ "Stock", "Stock" },
			{ "Scissor", "Scissor" },
			{ "Lambo", "Lambo" },
			{ "Butterfly", "Butterfly" },
			{ "Gullwing", "Gullwing" },
		}),
		Default = "Stock",
	},
} :: { Slot }

Catalog.SlotById = {} :: { [string]: Slot }
for _, slot in Catalog.Slots do
	Catalog.SlotById[slot.Id] = slot
end

export type Build = { [string]: string }

function Catalog.IsValidValue(slotId: string, value: any): boolean
	if typeof(slotId) ~= "string" or typeof(value) ~= "string" then
		return false
	end
	local slot = Catalog.SlotById[slotId]
	if not slot then
		return false
	end
	if slot.Kind == "Color" then
		return Catalog.PaletteById[value] ~= nil
	end
	for _, option in slot.Options or {} do
		if option.Id == value then
			return true
		end
	end
	return false
end

function Catalog.DefaultBuild(): Build
	local build = {}
	for _, slot in Catalog.Slots do
		build[slot.Id] = slot.Default
	end
	return build
end

-- Returns a copy of `build` with every missing/invalid slot reset to default.
function Catalog.Sanitize(build: { [any]: any }?): Build
	local clean = Catalog.DefaultBuild()
	if typeof(build) == "table" then
		for slotId, value in build do
			if Catalog.IsValidValue(slotId, value) then
				clean[slotId] = value
			end
		end
	end
	return clean
end

function Catalog.GetOptionName(slotId: string, value: string): string
	local slot = Catalog.SlotById[slotId]
	if slot and slot.Kind == "Color" then
		local entry = Catalog.PaletteById[value]
		return if entry then entry.Name else value
	end
	for _, option in (slot and slot.Options) or {} do
		if option.Id == value then
			return option.Name
		end
	end
	return value
end

return Catalog
