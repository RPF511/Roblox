local Tool = script.Parent.Parent
local ShoulderCamMode = Tool:WaitForChild("Configuration"):WaitForChild("ShoulderCamMode")
local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()
local character = player.Character
if not character or not character.Parent then
	character = player.CharacterAdded:wait()
end
local humanoid = character:WaitForChild("Humanoid")
local rotation = Instance.new("BodyGyro")
rotation.P = 1000000 --Increase the power
rotation.Parent = humanoid.RootPart
local UserInputService = game:GetService("UserInputService")

local equipConnection = nil

local camera = game.Workspace.CurrentCamera

function activeShoulderCam() --Toggle shift lock function
	if not ShoulderCamMode.Value then 
		ShoulderCamMode.Value = true
		UserInputService.MouseIconEnabled = false
		
		--humanoid.CameraOffset = Vector3.new(1,0.5,0)
		humanoid.CameraOffset = Vector3.new(3,1,0)
		rotation.MaxTorque = Vector3.new(0, math.huge, 0)
		
		equipConnection = game:GetService("RunService").RenderStepped:Connect(function()
			rotation.CFrame = mouse.Origin
			game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.LockCenter
		end) 
		
	end
end

function disableShoulderCam()
	if ShoulderCamMode.Value then
		ShoulderCamMode.Value = false
		UserInputService.MouseIconEnabled = true
		humanoid.CameraOffset = Vector3.new(0,0,0)
		rotation.MaxTorque = Vector3.new(0, 0, 0)

		if equipConnection then
			equipConnection:Disconnect() 
		end 
	end
end


Tool.Equipped:connect(activeShoulderCam)
Tool.Unequipped:connect(disableShoulderCam)