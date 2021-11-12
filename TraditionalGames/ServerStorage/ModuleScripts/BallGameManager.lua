local BallGameManager = {}

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BallManager = require(ServerStorage.ModuleScripts.BallManager)

--local Events = ServerStorage.Events
local ClientTriggerBall = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("ClientTriggerBall")
local BallPushAnim = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("BallPushAnim")


--Server Events
local EventsServer = ServerStorage:WaitForChild("Events")
local BallGameStartStop = EventsServer:WaitForChild("BallGameStartStop")
local TeleportPlayer = EventsServer:WaitForChild("TeleportPlayer")
local SendTimer = EventsServer:WaitForChild("SendTimer")


--GameSettings
local IsGameActive = false
local GameSettings = require(ServerStorage.Configurations.GameSettings)
local QUEUE_TIME_DURATION = GameSettings.QueueTime
local START_TIME_DURATION = GameSettings.GameStartTime
local BALL_PUSH_TIME = GameSettings.BallPushTime
local WholeGameMode = ServerStorage.Configurations.WholeGameMode


--Timer
local Timer = require(ServerStorage.Classes.Timer)
local TimerTable = {
	QueueTimer = Timer.new(),
	GameStartTimer = Timer.new(),
	GameTimer = Timer.new(),
	EndTimer = Timer.new()
}



--Connection
local ballPushConnection = nil
local ballCheckConnection = nil

local score = {
	A = 0,
	B = 0
}
local gameStatus = 0

function BallGameManager:ballGameActive()
	return IsGameActive
end




---------------------------------------------------------------------------------


function BallGameManager:ballGameStartRequest()
	-- If game is running, don't let players in
	if IsGameActive then return end

	if not TimerTable["QueueTimer"]:isRunning() then
		SendTimer:Fire("START","Queue","Ball","ALL",QUEUE_TIME_DURATION,"BallGame Starting....")
		TimerTable["QueueTimer"]:start(QUEUE_TIME_DURATION)
	end
end


function BallGameManager:prepareTimerStart()
	SendTimer:Fire("START","Playing","Ball","ALL",QUEUE_TIME_DURATION,"BallGame Starts in")
	TimerTable["GameStartTimer"]:start(START_TIME_DURATION)
end

function BallGameManager:prepareBallGame()
	TeleportPlayer:Fire("TEAM","Queue", "Ball", "Ball", "ALL")
	if not TimerTable["GameStartTimer"]:isRunning() and (not WholeGameMode.Value) then
		BallGameManager:prepareTimerStart()
	end
	score = {
		A = 0,
		B = 0
	}
end


local function startBallGame(players)
	TimerTable["GameStartTimer"]:stop()

	IsGameActive = true
	
	gameStatus = BallManager:setPlayer(players, GameSettings.BallPushDistance, GameSettings.BallSpeedMax)

	if not TimerTable["GameTimer"]:isRunning() then
		SendTimer:Fire("START","Playing","Ball","ALL",BALL_PUSH_TIME,"BallGame")
		TimerTable["GameTimer"]:start(BALL_PUSH_TIME)
	end


	ballPushConnection = game:GetService("RunService").Heartbeat:Connect(function(time)
		BallManager:updateLocation(time)
	end)
	ballCheckConnection = game:GetService("RunService").Heartbeat:Connect(function()
		BallManager:ballCheck()
	end)
	
end

local function stopConnection()
	if(ballPushConnection) then
		--print("disconnect ballpush")
		ballPushConnection:Disconnect()
		ballPushConnection = nil
	end
	if(ballCheckConnection) then
		--print("disconnect ballcheck")
		ballCheckConnection:Disconnect()
		ballPushConnection = nil
	end
end

local function stopBallGame(stat)
	IsGameActive = false
	SendTimer:Fire("STOP","Playing","Ball","ALL",START_TIME_DURATION,"BallGame Ends in...")
	
		

	stopConnection()

	BallManager:stopPush()

	
	if not WholeGameMode.Value then
		if not TimerTable["EndTimer"]:isRunning() then
			SendTimer:Fire("START","Playing","Ball","ALL",START_TIME_DURATION,"BallGame Ends in...")
			TimerTable["EndTimer"]:start(START_TIME_DURATION)
		end
	end
	BallGameStartStop:Fire("END")
end

local function handleBallGame(command, info)
	if(command == "START") then
		startBallGame(info)
	end
	if(command == "STOP") then
		if(gameStatus == 0) or (info == "FAIL") or (info == "SERVER") then
			if IsGameActive then
				TimerTable["GameTimer"]:stop()
				stopBallGame(info)
			end
		end
	end
end

function BallGameManager:calculateScore(team)
	score[team] = TimerTable["GameTimer"]:getTimeLeft()
	gameStatus -= 1
	return score[team]
end

function BallGameManager:getScore()
	return score
end

TimerTable["QueueTimer"].finished:Connect(function()
	TimerTable["QueueTimer"]:stop()
	BallGameManager:prepareBallGame()
end)

TimerTable["GameStartTimer"].finished:Connect(function()
	TimerTable["GameStartTimer"]:stop()
	BallGameStartStop:Fire("START_READY")
end)

TimerTable["GameTimer"].finished:Connect(function()
	TimerTable["GameTimer"]:stop()
	BallGameStartStop:Fire("FAIL")
end)

TimerTable["EndTimer"].finished:Connect(function()
	TimerTable["EndTimer"]:stop()
	TeleportPlayer:Fire("TEAM", "Playing", "Ball", "Lobby", "ALL")
end)

BallGameStartStop.Event:Connect(handleBallGame)


return BallGameManager
