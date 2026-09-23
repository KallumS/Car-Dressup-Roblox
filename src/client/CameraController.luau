-- Scripted cameras for each phase:
--   Customize -> orbit your own car in your garage bay (drag to rotate, wheel/pinch to zoom)
--   Showcase  -> orbit the car on stage
--   Results   -> fixed shot of the podium
--   otherwise -> normal player camera
-- Character movement is disabled while a scripted camera is active.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Store = require(script.Parent.Store)

local CameraController = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local yaw = math.rad(35)
local pitch = math.rad(14)
local distance = 24
local lastInput = 0
local dragging = false
local scripted = false

local function setControls(enabled: boolean)
	local ok, module = pcall(function()
		return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: ModuleScript) :: any
	end)
	if ok and module then
		local controls = module:GetControls()
		if enabled then
			controls:Enable()
		else
			controls:Disable()
		end
	end
end

local function focusFor(phase: string): (Vector3?, number?)
	if phase == "Customize" and Store.isParticipant() then
		local car = Store.findCar(player.UserId)
		if car and car.PrimaryPart then
			return car.PrimaryPart.Position + Vector3.new(0, 2.2, 0), 24
		end
		local bay = Store.myBay()
		if bay then
			local x = (bay - (Config.MaxParticipants + 1) / 2) * Config.BaySpacing
			return Config.GarageOrigin + Vector3.new(x, 2.5, 0), 24
		end
	elseif phase == "Showcase" then
		local car = Store.findCar(Store.State.Presenter)
		if car and car.PrimaryPart then
			return car.PrimaryPart.Position + Vector3.new(0, 2.2, 0), 26
		end
		return Config.StageCenter + Vector3.new(0, 3, 0), 26
	end
	return nil
end

local function update(dt: number)
	local phase = Store.State.Phase
	if phase == "Results" then
		if not scripted then
			scripted = true
			setControls(false)
		end
		camera.CameraType = Enum.CameraType.Scriptable
		local target = Config.PodiumCenter + Vector3.new(0, 5, 0)
		local sway = math.sin(os.clock() * 0.3) * 6
		camera.CFrame = CFrame.lookAt(Config.PodiumCenter + Vector3.new(sway, 16, -58), target)
		return
	end

	local focus, defaultDistance = focusFor(phase)
	if not focus then
		if scripted then
			scripted = false
			camera.CameraType = Enum.CameraType.Custom
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
			end
			setControls(true)
		end
		return
	end

	if not scripted then
		scripted = true
		distance = defaultDistance or 24
		setControls(false)
	end
	camera.CameraType = Enum.CameraType.Scriptable

	-- Gentle auto-orbit once the player stops dragging.
	if not dragging and os.clock() - lastInput > 2.5 then
		yaw += dt * 0.25
	end
	local offset = CFrame.fromEulerAnglesYXZ(-pitch, yaw, 0) * Vector3.new(0, 0, distance)
	local desired = CFrame.lookAt(focus + offset, focus)
	camera.CFrame = camera.CFrame:Lerp(desired, math.min(1, dt * 8))
end

function CameraController.start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			lastInput = os.clock()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input, processed)
		if not scripted then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel and not processed then
			distance = math.clamp(distance - input.Position.Z * 2, 12, 45)
			lastInput = os.clock()
		elseif
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			yaw -= math.rad(input.Delta.X * 0.4)
			pitch = math.clamp(pitch + math.rad(input.Delta.Y * 0.3), math.rad(-5), math.rad(60))
			lastInput = os.clock()
		end
	end)
	UserInputService.TouchPinch:Connect(function(_, scale, _, _, processed)
		if scripted and not processed then
			distance = math.clamp(distance * (1 - (scale - 1) * 0.04), 12, 45)
			lastInput = os.clock()
		end
	end)

	Store.StateChanged:Connect(function(newState, previous)
		-- Frame the stage car from the front whenever a new car comes out.
		if newState.Phase == "Showcase" and newState.Presenter ~= previous.Presenter then
			yaw = math.rad(180 + 30)
			pitch = math.rad(12)
			distance = 26
		elseif newState.Phase == "Customize" and previous.Phase ~= "Customize" then
			-- Garage cars face +Z, so yaw 0 looks at the front.
			yaw = math.rad(35)
			pitch = math.rad(14)
			distance = 24
		end
	end)

	RunService:BindToRenderStep("CarDressUpCamera", Enum.RenderPriority.Camera.Value + 1, update)
end

return CameraController
