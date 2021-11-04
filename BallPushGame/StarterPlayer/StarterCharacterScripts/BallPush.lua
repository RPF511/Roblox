local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActivateBallPushAnim = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("ActivateBallPushAnim")
local DectivateBallPushAnim = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("DectivateBallPushAnim")

--local ServerStorage = game:GetService("ServerStorage")
--local GameSettings = require(ServerStorage.Configurations.GameSettings)
--local Configurations = ServerStorage:WaitForChild("Configurations",5)

--local GameSettings = require(Configurations.GameSettings)


local ball = game.Workspace.BallGame.Ball
local ballSize = ball.Size.X / 2
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

local function ballPush(ballpushdistance,speed)
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
	end
end


--startBtn.Touched:Connect(ballPush)
--stopBtn.Touched:Connect(ballPushStop)

ActivateBallPushAnim.OnClientEvent:connect(ballPush)
DectivateBallPushAnim.OnClientEvent:connect(ballPushStop)