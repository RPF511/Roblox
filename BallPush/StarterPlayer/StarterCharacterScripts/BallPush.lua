local ball = game.Workspace.ball
local ballSize = ball.Size.X / 2
local player = script.Parent
local startBtn = game.Workspace.StartBtn
local stopBtn = game.Workspace.StopBtn

local pushingAnimation = Instance.new("Animation")
--pushingAnimation.AnimationId = "rbxassetid://7741380613"
pushingAnimation.AnimationId = "rbxassetid://7742368334"

local ballPushStat = false



local function getDistance(pos1, pos2)
	return math.sqrt((pos1.x - pos2.x)^2 + (pos1.y - pos2.y)^2 + (pos1.z - pos2.z)^2)
end

print(ballSize)

--while(1) do
--	wait(0.1)
--	print("player [", player.HumanoidRootPart.Position, "]   ball [",ball.Position,"] distance ", getDistance(playerHumanoid.Position, ball.Position))
--end

local function ballPushing()
	if(ballPushStat) then
		while(ballPushStat) do
			wait(0.1)
			if(not ballPushStat) then
				break
			end

			local pushingAnim = player.Humanoid:LoadAnimation(pushingAnimation)
			--pushingAnim.Looped = true
			local distance = getDistance(player.HumanoidRootPart.Position, ball.Position)
			--print(getDistance(player.HumanoidRootPart.Position, ball.Position))
			if(distance >= ballSize + 3) then
				if(pushingAnim.IsPlaying) then
					-- print("pushing stop")
					pushingAnim:stop()
				end
			end
			
			if(distance < ballSize + 3) then
				if(not pushingAnim.IsPlaying) then
					-- print("pushing start")
					pushingAnim:play()
				-- else
				-- 	print("keep Pushing")
				end

			else
				-- print("distance out ",getDistance(player.HumanoidRootPart.Position, ball.Position))
				if(pushingAnim.IsPlaying) then
					-- print("pushing stop")
					pushingAnim:stop()
				end

			end
		end
	end
	
	return
end

local function ballPush()
	if(not ballPushStat) then
		ballPushStat = true
		ballPushing()
	end
	-- print("startbtn touched")
	return
end

local function ballPushStop()
	if(ballPushStat) then
		ballPushStat = false
		
	end
	-- print("stopbtn touched")
	return
end


startBtn.Touched:Connect(ballPush)
stopBtn.Touched:Connect(ballPushStop)