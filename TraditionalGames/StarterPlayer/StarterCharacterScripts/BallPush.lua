
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BallPushAnim = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("BallPushAnim")

--local ServerStorage = game:GetService("ServerStorage")
--local GameSettings = require(ServerStorage.Configurations.GameSettings)
--local Configurations = ServerStorage:WaitForChild("Configurations",5)

--local GameSettings = require(Configurations.GameSettings)


local ball = nil
local ballSize = nil
local player = script.Parent


local pushingAnimation = Instance.new("Animation")
pushingAnimation.AnimationId = "rbxassetid://7742368334"

local ballPushStat = false
local pushingConneciton = nil


local function getDistance(pos1, pos2)
	return math.sqrt((pos1.x - pos2.x)^2 + (pos1.y - pos2.y)^2 + (pos1.z - pos2.z)^2)
end


local function ballPushing(BallPushDistance)
	local pushingAnim = player.Humanoid:LoadAnimation(pushingAnimation)
	pushingConneciton = game:GetService("RunService").Heartbeat:Connect(function()
		local distance = getDistance(player.HumanoidRootPart.Position, ball.Position)
		if(distance >= ballSize + BallPushDistance) then
			if(pushingAnim.IsPlaying) then
				pushingAnim:stop()
			end
		end
		--pushingAnim.Looped = true
		if(distance < ballSize + BallPushDistance) then
			if(not pushingAnim.IsPlaying) then
				pushingAnim:play()
			end
		else
			if(pushingAnim.IsPlaying) then
				pushingAnim:stop()
			end

		end
	end)
end

local function ballPush(ballpushdistance,speed,team)
	if team == "A" then
		ball = game.Workspace.BallGame.BallA
	end
	if team == "B" then
		ball = game.Workspace.BallGame.BallB
	end
	ballSize = ball.Size.X / 2

	if(not pushingConneciton) then
		player.Humanoid.WalkSpeed = speed
		ballPushing(ballpushdistance)
	end
end



local function ballPushStop()
	if(pushingConneciton) then
		player.Humanoid.WalkSpeed = 16
		pushingConneciton:Disconnect()
		pushingConneciton = nil
		ball = nil
		ballSize = nil
	end
end

local function handleBallAnim(command, distance, speed, team)
	if(command == "START") then
		ballPush(distance,speed,team)
	end
	if(command == "STOP") then
		ballPushStop()
	end
end

BallPushAnim.OnClientEvent:connect(handleBallAnim)
