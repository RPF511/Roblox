local RopeManager = {}

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameSettings = require(ServerStorage.Configurations.GameSettings)

local RopeData = ReplicatedStorage:WaitForChild("EventsRope"):WaitForChild("RopeData")

--rope SETTING
local ROPE_CFRAME_ORIGIN = GameSettings.RopeCFrameOrigin
local ROPE_DIRECTION = GameSettings.RopeDirection
local ROPE_PL_BETWEEN = GameSettings.RopePlayerBetween
local ROPE_LEFT_RIGHT = GameSettings.RopePlayerLeftRight
local ROPE_START_DIS = GameSettings.RopePlayerStartDistance
local ROPE_ENDURE_MAG = GameSettings.RopeEndureMag
local ROPE_MAX_VEL = GameSettings.RopeMaxVel
local ROPE_END_DISTANCE = GameSettings.RopeEndDistance

local Rope = game.Workspace.RopeGame.Rope

local Events = ServerStorage:WaitForChild("Events")
local RopeGameStartStop = Events:WaitForChild("RopeGameStartStop")


local moveVector = nil


local teamState = {
	A = {},
	B = {}
}

local stateNum = {
	A = {
		endure = 0,
		pull = 0,
		release = 0,
		broken = 0
	},
	B = {
		endure = 0,
		pull = 0,
		release = 0,
		broken = 0
	}
}
local numA = 0
local numB = 0
local netVel = 0
local netForce = 0

function RopeManager:resetRope()
	if(ROPE_DIRECTION == "Z") then
		moveVector = Vector3.new(0,0,1)
	end
	if(ROPE_DIRECTION == "X") then
		moveVector = Vector3.new(1,0,0)
	end
	
end

local function CheckWin()
	if(ROPE_DIRECTION == "Z") then
		if(Rope.CFrame.Z > ROPE_CFRAME_ORIGIN.Z + ROPE_END_DISTANCE) then
			print("A win")
			RopeGameStartStop:Fire("WIN","A")
		end
		if(Rope.CFrame.Z < ROPE_CFRAME_ORIGIN.Z - ROPE_END_DISTANCE) then
			print("B win")
			RopeGameStartStop:Fire("WIN","B")
		end
	end
	if(ROPE_DIRECTION == "X") then
		if(Rope.CFrame.X > ROPE_CFRAME_ORIGIN.X + ROPE_END_DISTANCE) then
			RopeGameStartStop:Fire("WIN","A")
		end
		if(Rope.CFrame.X < ROPE_CFRAME_ORIGIN.X - ROPE_END_DISTANCE) then
			RopeGameStartStop:Fire("WIN","B")
		end
	end
end


function RopeManager:getLocationSettings()
	return ROPE_DIRECTION, ROPE_PL_BETWEEN, ROPE_LEFT_RIGHT, ROPE_START_DIS
end

function RopeManager:setStateA(players)
	numA = #players
	for _, player in pairs(players) do
		teamState["A"][player] = "endure"
		stateNum["A"]["endure"] += 1
	end
end

function RopeManager:setStateB(players)
	numB = #players
	for _, player in pairs(players) do
		teamState["B"][player] = "endure"
		stateNum["B"]["endure"] += 1
	end
end

function RopeManager:setState(players)
	RopeManager:setStateA(players["A"])
	RopeManager:setStateB(players["B"])
end

--print(teamState, stateNum)

function RopeManager:updatePlayer(player, stat, team)
	stateNum[team][teamState[team][player]] -= 1
	teamState[team][player] = stat
	stateNum[team][stat] += 1
	if(stat == "broken") then
		RopeData:FireClient(player,"broken")
	end
end

function RopeManager:updateNet()
	local pullDIF = stateNum["A"]["pull"] - stateNum["B"]["pull"]
	local endureDIF = stateNum["A"]["endure"] - stateNum["B"]["endure"]
	if (pullDIF == 0) then
		netForce =  endureDIF * (1 - ROPE_ENDURE_MAG)
		--netForce = 0
		--print(0)
		return
	end
	if(endureDIF == 0) then
		netForce = pullDIF
		--print(7)
		return
	else
		if(endureDIF > 0) then
			if(pullDIF < 0) then
				local temp = (endureDIF/math.abs(pullDIF)) * ROPE_ENDURE_MAG
				if(temp > 1) then
					netForce = 0
					--print(1)
					return
				else
					netForce = pullDIF * (1-temp)
					--print(2)
					return
				end
			else
				netForce = pullDIF + endureDIF * (1 - ROPE_ENDURE_MAG)
				--print(3)
				return
			end
		else
			if(pullDIF > 0) then
				local temp = (math.abs(endureDIF)/pullDIF) * ROPE_ENDURE_MAG
				if(temp > 1) then
					netForce = 0
					--print(4)
					return
				else
					netForce = pullDIF * (1-temp)
					--print(5)
					return
				end
			else
				netForce = pullDIF + endureDIF * (1 - ROPE_ENDURE_MAG)
				--print(6)
				return
			end
		end
	end
	
end

function RopeManager:updateVelocity()
	local releaseDIF = stateNum["A"]["release"] - stateNum["B"]["release"]
	if(releaseDIF < -(numB/2)) or (releaseDIF > (numA/2)) then
		for player, state in pairs(teamState["A"]) do
			if(state == "endure") then
				RopeManager:updatePlayer(player, "broken", "A")
			end
		end
		for player, state in pairs(teamState["B"]) do
			if(state == "endure") then
				RopeManager:updatePlayer(player, "broken", "A")
			end
		end
	end
	
	if(netForce == 0 or math.abs(netVel) > ROPE_MAX_VEL) then
		netVel *= 0.9
	else
		netVel += netForce
	end
	
	--if(netForce == 0 or math.abs(netVel) > ROPE_MAX_VEL) then
	--	netVel *= 0.9
	--else
	--	netVel = netForce
	--end
	CheckWin()
	
	print("netForce : ",netForce, " netVel : ",netVel)
end

function RopeManager:updateMove(time)
	local plus =  moveVector * netVel * time
	--print("count : ",count,"vector : ", vector, "curvector : ", curVector ," plus : ",plus)
	Rope.CFrame = Rope.CFrame + plus
	for player, state in pairs(teamState["A"]) do
		player.character.HumanoidRootPart.CFrame = player.character.HumanoidRootPart.CFrame + plus
	end
	for player, state in pairs(teamState["B"]) do
		player.character.HumanoidRootPart.CFrame = player.character.HumanoidRootPart.CFrame + plus
	end
end

function RopeManager:EndRope()
	
	teamState = {
		A = {},
		B = {}
	}
	stateNum = {
		A = {
			endure = 0,
			pull = 0,
			release = 0,
			broken = 0
		},
		B = {
			endure = 0,
			pull = 0,
			release = 0,
			broken = 0
		}
	}
	numA = 0
	numB = 0
	netVel = 0
	netForce = 0
	moveVector = nil

	
	
end

function RopeManager:RopeToOrigin()
	Rope.CFrame = ROPE_CFRAME_ORIGIN
end

return RopeManager
