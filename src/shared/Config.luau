-- Global tuning values for the match loop, map layout and anti-spam limits.
-- Everything a designer is likely to tweak lives here.

local Config = {}

-- Match flow ---------------------------------------------------------------

Config.MaxParticipants = 10
Config.MinPlayersToStart = 2
-- Lets you test solo when pressing Play in Studio.
Config.MinPlayersToStartInStudio = 1

Config.IntermissionTime = 15 -- seconds of countdown before a match
Config.CustomizeTime = 300 -- 5 minutes to build your car
Config.ShowcaseTimePerCar = 18 -- seconds each car is on stage
Config.ResultsTime = 20 -- seconds the podium is shown
-- When every participant presses Ready, the build timer is cut down to this.
Config.AllReadyTimeLeft = 10

-- Showcase choreography (seconds after the car arrives on stage).
Config.ShowcaseDriveInTime = 2.5
Config.ShowcaseSequence = {
	{ At = 3, Flag = "DoorsOpen", Value = true },
	{ At = 5, Flag = "HoodOpen", Value = true },
	{ At = 6.5, Flag = "TrunkOpen", Value = true },
	{ At = 9, Flag = "Bounce", Value = true, RequiresHydraulics = true },
	{ At = 12, Flag = "Bounce", Value = false },
	{ At = 12, Flag = "Burnout", Value = true },
	{ At = 15.5, Flag = "Burnout", Value = false },
}

-- Rating
Config.MinStars = 1
Config.MaxStars = 5
Config.PodiumSize = 3

-- Rate limits (seconds between accepted requests per player)
Config.BuildUpdateCooldown = 0.05
Config.ShowOffCooldown = 0.4
Config.RebuildInterval = 0.12 -- dirty cars are rebuilt at most this often

-- Themes (one is picked per match, shown to everyone like Dress to Impress)
Config.Themes = {
	{ Name = "Street Racer", Description = "Built for midnight highway pulls." },
	{ Name = "Lowrider King", Description = "Low, loud and bouncing." },
	{ Name = "Drift Missile", Description = "Aggressive aero and tyre smoke." },
	{ Name = "Show Car", Description = "Every panel polished, every light on." },
	{ Name = "Rally Monster", Description = "Mud flaps, light bars and grit." },
	{ Name = "Supercar Exotic", Description = "Wild doors and wilder paint." },
	{ Name = "Retro Classic", Description = "Chrome, whitewalls and old-school style." },
	{ Name = "Villain's Ride", Description = "Dark, menacing and a little evil." },
	{ Name = "Neon Nights", Description = "Glow brighter than the city." },
	{ Name = "Time Attack", Description = "Wings, splitters and zero compromise." },
	{ Name = "Bass Monster", Description = "The trunk is the star of the show." },
	{ Name = "Candy Paint", Description = "Bright colours and big rims." },
}

-- Map layout ----------------------------------------------------------------

Config.LobbyCenter = Vector3.new(0, 0, 0)
Config.GarageOrigin = Vector3.new(0, 0, -140) -- centre of the row of bays
Config.BaySpacing = 32
Config.StageCenter = Vector3.new(0, 0, 150) -- where cars are presented
Config.StageHeight = 1.5
Config.PodiumCenter = Vector3.new(110, 0, 150)

return Config
