local BallManager = {}

local ServerStorage = game:GetService("ServerStorage")
local Events = ServerStorage:WaitForChild("Events")
local BallGameStartStop = Events:WaitForChild("BallGameStartStop")


local ball = {
	A = game.Workspace.BallGame.BallA,
	B = game.Workspace.BallGame.BallB
}
local ballPositionBackup = {
	A = ball["A"].CFrame,
	B = ball["B"].CFrame
}
local ballBar = {
	A = game.Workspace.BallGame.BallBarA.Position,
	B = game.Workspace.BallGame.BallBarB.Position
}
local ballSize = {
	A = ball["A"].Size.X / 2,
	B = ball["B"].Size.X / 2
}
local players = {}
local numOfPlayers = {
	A = 0,
	B = 0
}
local ballPushDistance
local ballSpeedMax
local curVector = {
	A = Vector3.new(0,0,0),
	B = Vector3.new(0,0,0)
}
local count = {
	A = 0,
	B = 0
}
local calCount = 0
local zeroVector = Vector3.new(0,0,0)
local ballStep = {
	A = 0,
	B = 0
}
local ballCheckFrom = {
	A = 0,
	B = 0
}
local endline = {
	A = 25,
	B = 25
}




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


function BallManager:setPlayer(Players, BallPushDistance, BallSpeedMax)
	players = Players
	numOfPlayers["A"] = #players["A"]
	numOfPlayers["B"] = #players["B"]
	ballPushDistance = BallPushDistance
	ballSpeedMax = BallSpeedMax
	ball["A"].Anchored = false
	ball["B"].Anchored = false
	if (numOfPlayers["A"] == 0) or (numOfPlayers["B"] == 0) then
		return 1
	end
	return 2
end



local function getDirection(team)
	local vector = Vector3.new(0,0,0)
	local distance = ballSize[team] + ballPushDistance
	
	for _ , player in pairs(players[team]) do
		local vectorSingle = getSingleDireciton(ball[team].Position, player.Character.HumanoidRootPart.Position)
		if(vectorLength(vectorSingle) < distance) then
			local temp = orthogonalVector(vectorSingle)

			vector +=  temp / vectorLength(temp)
		end
	end
	if(numOfPlayers[team] == 0) then
		return vector
	end
	return vector / numOfPlayers[team]
end

local function updateLoc(team,time)
	local vector = getDirection(team)
	
	if(vector ~= zeroVector) then
		if(count[team] < 200) then
			count[team] += 1
		end
		curVector[team] += vector
		curVector[team] /= vectorLength(curVector[team])

	else
		if(count[team] == 0) then
			curVector[team] = Vector3.new(0,0,0)
		end
		if(count[team] > 0) then
			count[team] -= 1
		end

	end
	local plus = (curVector[team] * ballSpeedMax * (count[team] / 200) * time) 
	--print("count : ",count[team]," vector : ", vector, " curvector : ", curVector[team] ," plus : ",plus)
	ball[team].CFrame = ball[team].CFrame + plus
	ball[team].Velocity = zeroVector
end

function BallManager:updateLocation(time)
	updateLoc("A",time)
	updateLoc("B",time)
end


local function checkBall(team)
	if(ballStep[team] == 0) then
		--print("step 0")
		if(ball[team].Position.Z > ballBar[team].Z) then
			if(ball[team].Position.X < ballBar[team].X) then
				--print("from rigiht")
				ballStep[team] = 1
				ballCheckFrom[team] = 1
			else
				--print("from left")
				ballStep[team] = 1
				ballCheckFrom[team] = 2
			end
		end
	end
	if(ballStep[team] == 1) then
		if(ball[team].Position.Z < ballBar[team].Z) then
			ballStep[team] = 0
			ballCheckFrom[team] = 0
		end
		if ((ball[team].Position.X < ballBar[team].X) and ballCheckFrom[team] == 2) then
			--print("to rigiht")
			ballStep[team] = 2
		end
		if ((ball[team].Position.X > ballBar[team].X) and ballCheckFrom[team] == 1)  then
			--print("to left")
			ballStep[team] = 2
		end
	end
	if(ballStep[team] == 2) then
		if(ball[team].Position.Z < ballBar[team].Z) then
			ballStep[team] = 3
		end
		if ((ball[team].Position.X > ballBar[team].X) and ballCheckFrom[team] == 2) then
			--print("to rigiht")
			ballStep[team] = 2
		end
		if ((ball[team].Position.X < ballBar[team].X) and ballCheckFrom[team] == 1)  then
			--print("to left")
			ballStep[team] = 2
		end
	end
	if(ballStep[team] == 3) then
		--print("getback")
		if(ball[team].Position.Z < endline[team]) then
			BallGameStartStop:Fire("SUCCESS",team)
		end
	end
end

function BallManager:ballCheck()
	calCount += 1
	if (calCount == 2) then
		checkBall("A")
		checkBall("B")
		calCount = 0
	end
end


function BallManager:stopPush()
	players = {} 
	curVector = {
		A = Vector3.new(0,0,0),
		B = Vector3.new(0,0,0)
	}
	count = {
		A = 0,
		B = 0
	}
	calCount = 0
	numOfPlayers["A"] = 0
	numOfPlayers["B"] = 0
	ball["A"].CFrame = ballPositionBackup["A"]
	ball["B"].CFrame = ballPositionBackup["B"]
	ball["A"].Anchored = true
	ball["B"].Anchored = true
	ballStep = {
		A = 0,
		B = 0
	}
	ballCheckFrom = {
		A = 0,
		B = 0
	}
end


return BallManager
