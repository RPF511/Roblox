local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local ToolEquipped = Tool:WaitForChild("Configuration"):WaitForChild("Equipped")
local Remote = Tool:WaitForChild("Remote")
local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character
if not Character or not Character.Parent then
	Character = Player.CharacterAdded:wait()
end
local UIS = game:GetService("UserInputService")
local Mouse = Player:GetMouse()
local Remote = Tool:WaitForChild("Remote")
local InputType = Enum.UserInputType

local Heartbeat = game:GetService("RunService").Heartbeat

local BeganConnection = nil
local EndedConnection = nil

local camera = game.Workspace.CurrentCamera



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientTriggerTuho = ReplicatedStorage:WaitForChild("EventsTuho"):WaitForChild("ClientTriggerTuho")

--timer
local Timer = require(ReplicatedStorage.ModuleScripts.Timer)
local timer = Timer.new()
local inputable = true
local inputed = false

---------------
local vel = Tool:WaitForChild("Configuration"):WaitForChild("ThrowVelocity")
local beamConnection = nil
local camConnection = nil
local lookData = {0,0,0,0,0,0,0,0,0,0}
local attach0 = Instance.new("Attachment", game.Workspace.Terrain);
local attach1 = Instance.new("Attachment", game.Workspace.Terrain);

local beam = Instance.new("Beam", game.Workspace.Terrain);
beam.Attachment0 = attach0;
beam.Attachment1 = attach1;

local function beamProjectile(g, v0, x0, t1)
	-- calculate the bezier points
	local c = 0.5*0.5*0.5;
	local p3 = 0.5*g*t1*t1 + v0*t1 + x0;
	local p2 = p3 - (g*t1*t1 + v0*t1)/3;
	local p1 = (c*g*t1*t1 + 0.5*v0*t1 + x0 - c*(x0+p3))/(3*c) - p2;

	-- the curve sizes
	local curve0 = (p1 - x0).magnitude;
	local curve1 = (p2 - p3).magnitude;

	-- build the world CFrames for the attachments
	local b = (x0 - p3).unit;
	local r1 = (p1 - x0).unit;
	local u1 = r1:Cross(b).unit;
	local r2 = (p2 - p3).unit;
	local u2 = r2:Cross(b).unit;
	b = u1:Cross(r1).unit;

	local cf1 = CFrame.new(
		x0.x, x0.y, x0.z,
		r1.x, u1.x, b.x,
		r1.y, u1.y, b.y,
		r1.z, u1.z, b.z
	)

	local cf2 = CFrame.new(
		p3.x, p3.y, p3.z,
		r2.x, u2.x, b.x,
		r2.y, u2.y, b.y,
		r2.z, u2.z, b.z
	)

	return curve0, -curve1, cf1, cf2;
end

function startBeam()
	beamConnection  = game:GetService("RunService").RenderStepped:Connect(function(dt)
		local unitV0 = camera.CFrame.LookVector
		local g = Vector3.new(0, -game.Workspace.Gravity, 0);
		local x0 = Handle.Position
		local v0 = unitV0 * vel.Value
		local t = 0.5
		if(v0.Y > 0) then
			t += (v0.Y / game.Workspace.Gravity) * 3.0
			--print("time ",t)
			--else
			--	t = 0.5
			--print("time ",t)
		end

		local curve0, curve1, cf1, cf2 = beamProjectile(g, v0, x0, t);
		beam.CurveSize0 = curve0;
		beam.CurveSize1 = curve1;
		beam.Transparency = NumberSequence.new({ -- a color sequence shifting from white to blue
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0)
		}
		)
		beam.Color = ColorSequence.new({ -- a color sequence shifting from white to blue
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
		}
		)
		--beam.Texture = "rbxasset://textures/particles/sparkles_main.dds" -- a built in sparkle texture
		beam.TextureMode = Enum.TextureMode.Wrap -- wrap so length can be set by TextureLength
		--print("curve 1, curve 2",curve0,curve1)

		--convert world space CFrames to be relative to the attachment parent
		attach0.CFrame = attach0.Parent.CFrame:inverse() * cf1;
		attach1.CFrame = attach1.Parent.CFrame:inverse() * cf2;
	end)
end

function stopBeam()
	if beamConnection then 
		beam.Transparency = NumberSequence.new({ -- a color sequence shifting from white to blue
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 1)
		}
		)
		beamConnection:Disconnect() 
	end 
end



function startLookData()
	if not camConnection then
		local y = camera.CFrame.LookVector.Y
		lookData = {y,y,y,y,y,y,y,y,y,y}
		camConnection = game:GetService("RunService").RenderStepped:Connect(function()
			lookData = {lookData[2],lookData[3],lookData[4],lookData[5],lookData[6],lookData[7],lookData[8],lookData[9],lookData[10],camera.CFrame.LookVector.Y}
			--print(lookData)
		end)
	end
end
function stopLookData()
	if camConnection then 
		camConnection:Disconnect() 
		camConnection = nil
		lookData = {0,0,0,0,0,0,0,0,0,0}
	end 
end

function inputBegan(input)
	if inputable then
		if input.UserInputType == InputType.MouseButton1 then
			--print("client left down")
			--print(Mouse.Hit.p)
			startBeam()
			startLookData()
			Remote:FireServer("LeftDown")
			inputed = true
		end
		if input.UserInputType == InputType.MouseButton2 then
			--print("client right down")
		end
	end
end

function inputEnded(input)
	if inputed then
		if input.UserInputType == InputType.MouseButton1 then
			--print("client left up")
			stopBeam()
			Remote:FireServer("LeftUp", camera.CFrame.LookVector, lookData[10] - lookData[1])
			stopLookData()
			inputable = false
			inputed = false
			timer:start(0.8)
		end
	end
end

function onRemote(func, ...)
	if func == "PlayAnimation" then
		--playAnimation(...)
	elseif func == "StopAnimation" then
		--stopAnimation(...)
	end
end

function onEquip()
	BeganConnection = UIS.InputBegan:connect(inputBegan)
	EndedConnection = UIS.InputEnded:connect(inputEnded)

end

function onUnequip()
	if BeganConnection then
		BeganConnection:disconnect()
		BeganConnection = nil
	end

	if EndedConnection then
		EndedConnection:disconnect()
		EndedConnection = nil
	end

end

local function startInput(command)
	if command == "TUHOGAME_STARTED" then
		inputable = true
	end
end

local function setInputable()
	if(timer:isRunning()) then
		timer:stop()
	end
	inputable = true
end

Tool.Equipped:connect(onEquip)
Tool.Unequipped:connect(onUnequip)
Remote.OnClientEvent:connect(onRemote)
----?????????
ClientTriggerTuho.OnClientEvent:Connect(startInput)
timer.finished:Connect(setInputable)
Tool.Unequipped:connect(stopBeam)