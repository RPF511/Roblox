local BallManager = {}

local ServerStorage = game:GetService("ServerStorage")
local Events = ServerStorage:WaitForChild("Events")
local BallGameStopEvent = Events:WaitForChild("BallGameStop")


local ball = game.Workspace.BallGame.Ball
local ballPositionBackup = ball.CFrame
local ballBar = game.Workspace.BallGame.BallBar.Position
local ballSize = ball.Size.X / 2
local players = {}
local numOfPlayers = 0
local ballPushDistance
local ballSpeedMax
local curVector = Vector3.new(0,0,0)
local count = 0
local zeroVector = Vector3.new(0,0,0)
local ballPushTime = 0
local ballStep = false
local ballCheckFrom = 0
local getBack = false




local function vectorLength(pos)
	return math.sqrt((pos.X)^2 + (pos.Y)^2 + (pos.Z)^2)
end

local function getDistance(pos1, pos2)
	return math.sqrt((pos1.x - pos2.x)^2 + (pos1.y - pos2.y)^2 + (pos1.z - pos2.z)^2)
end

local function getSingleDireciton(ballpos, playerpos)
	--print("ball : ",ballpos,", player : ", playerpos)
	return ballpos - playerpos
end

local function orthogonalVector(vec)
	local vect = vec -Vector3.new(0,vec.Y,0)
	return vect
end


function BallManager:setPlayer(Players, BallPushDistance, BallSpeedMax, ballpushtime)
	players = Players
	numOfPlayers = #players
	--print(numOfPlayers)
	ballPushDistance = BallPushDistance
	ballSpeedMax = BallSpeedMax
	ball.Anchored = false
	curVector = Vector3.new(0,0,0)
	ballPushTime = ballpushtime
	return players
end



local function getDirection()
	local vector = Vector3.new(0,0,0)
	local numOfPushing = 0;
	local distance = ballSize + ballPushDistance
	
	for _ , player in pairs(players) do
		local vectorSingle = getSingleDireciton(ball.Position, player.Character.HumanoidRootPart.Position)
		if(vectorLength(vectorSingle) < distance) then
			numOfPushing += 1
			local temp = orthogonalVector(vectorSingle)

			vector +=  temp / vectorLength(temp)
		end
	end
	return vector / numOfPlayers
end

function BallManager:updateLocation(time)
	
	
	local vector = getDirection()
	
	if(vector ~= zeroVector) then
		if(count < 200) then
			count += 1
		end
		curVector += vector
		curVector /= vectorLength(curVector)
		
	else
		if(count == 0) then
			curVector = Vector3.new(0,0,0)
		end
		if(count > 0) then
			count -= 1
		end
		
	end
	local plus = (curVector * ballSpeedMax * count / 200 * time) 
	--print("count : ",count,"vector : ", vector, "curvector : ", curVector ," plus : ",plus)
	ball.CFrame = ball.CFrame + plus
	ball.Velocity = zeroVector
end

function BallManager:ballCheck()
	if(not getBack) then
		if(not ballStep) then
			--print("step 0")
			if(ball.Position.Z > ballBar.Z) then
				if(ball.Position.X < ballBar.X) then
					--print("from rigiht")
					ballStep = 1
					ballCheckFrom = 1
				else
					--print("from left")
					ballStep = 1
					ballCheckFrom = 2
				end
			end
		end
		if(ballStep) then
			--print("step 1")
			if(ball.Position.Z < ballBar.Z) then
				if ((ball.Position.X < ballBar.X) and ballCheckFrom == 2) then
					--print("to rigiht")
					getBack = true
				end
				if ((ball.Position.X > ballBar.X) and ballCheckFrom == 1)  then
					--print("to left")
					getBack = true
				end
			end
		end
	else
		--print("getback")
		if(ball.Position.Z < 25) then
			BallGameStopEvent:Fire("SUCCESS")
		end
	end
end


--function BallManager:startPush()
	
--end

function BallManager:stopPush()
	--print("stop ballmanager")
	players = {} 
	curVector = Vector3.new(0,0,0)
	count = 0
	numOfPlayers = 0
	ball.CFrame = ballPositionBackup
	ball.Anchored = true
	ballPushTime = 0
	ballStep = false
	ballCheckFrom = 0
	getBack = false
	
end


return BallManager
