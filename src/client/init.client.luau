-- Client entry point: builds the UI, starts the camera and car animator and
-- keeps the local Store in sync with the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Store = require(script.Store)
local CarAnimator = require(script.CarAnimator)
local CameraController = require(script.CameraController)
local Hud = require(script.Hud)
local CustomizeMenu = require(script.CustomizeMenu)
local ShowcaseMenu = require(script.ShowcaseMenu)
local ResultsMenu = require(script.ResultsMenu)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "CarDressUp"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Shrink the whole UI on small (phone) screens.
local scale = Instance.new("UIScale")
scale.Parent = gui
local function updateScale()
	local viewport = workspace.CurrentCamera.ViewportSize
	scale.Scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.55, 1)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

Net.StateChanged.OnClientEvent:Connect(function(state)
	Store.setState(state)
end)
Net.BuildChanged.OnClientEvent:Connect(function(build)
	Store.setBuild(build)
end)

CarAnimator.start()
CameraController.start()
Hud.start(gui)
CustomizeMenu.start(gui)
ShowcaseMenu.start(gui)
ResultsMenu.start(gui)

local ok, state, build = pcall(function()
	return Net.GetState:InvokeServer()
end)
if ok and state then
	Store.setBuild(build)
	Store.setState(state)
end
