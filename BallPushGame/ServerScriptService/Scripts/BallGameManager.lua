local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local PlayerManager = require(ServerStorage.ModuleScripts.PlayerManager)
local BallManager = require(ServerStorage.ModuleScripts.BallManager)

--local Events = ServerStorage.Events
local ClientTriggerBallGame = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("ClientTriggerBallGame")
local ClientTriggerBallGameStop = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("ClientTriggerBallGameStop")
local ActivateBallPushAnim = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("ActivateBallPushAnim")
local DectivateBallPushAnim = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("DectivateBallPushAnim")
local RemoteAddPlayer = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("RemoteAddPlayer")
local timerStartStop = ReplicatedStorage:WaitForChild("Events"):WaitForChild("TimerStartStop")


--Server Events
local Events = ServerStorage:WaitForChild("Events")
local TriggerBallGameEvent = Events:WaitForChild("TriggerBallGameEvent")
local BallGameStartEvent = Events:WaitForChild("BallGameStart")
local BallGameStopEvent = Events:WaitForChild("BallGameStop")


local isGameActive = script.IsGameActive
local GameSettings = require(ServerStorage.Configurations.GameSettings)
local WholeGameMode = ServerStorage.Configurations:WaitForChild("WholeGameMode")

local Timer = require(ServerStorage.Classes.Timer)
local playerQueue = {}
local queueTimer = Timer.new()
local gameStartTimer = Timer.new()
local gameTimer = Timer.new()

--local timerConnection = nil
local ballPushConnection = nil
local ballCheckConnection = nil

--Waiting 
local QUEUE_TIME_DURATION = GameSettings.QueueTime
local START_TIME_DURATION = GameSettings.GameStartTime
local BALL_PUSH_TIME = GameSettings.BallPushTime
local ballGameQueueUpdate = ReplicatedStorage.EventsBall.BallGameQueueUpdate

--local character = player.Character
--if not character or not character.Parent then
--	character = player.CharacterAdded:wait()
--end
--local humanoid = character:WaitForChild("Humanoid")
--local humanoidRootPart = character:WaitForChild("HumanoidRootPart")



local function clearTimer(timer)
	if timer:isRunning() then
		timer:stop()
	end
end

local function getDistance(pos1, pos2)
	return math.sqrt((pos1.x - pos2.x)^2 + (pos1.y - pos2.y)^2 + (pos1.z - pos2.z)^2)
end

local function updatePlayerRequest(player)
	RemoteAddPlayer:FireClient(player,"UPDATE_PLAYER",PlayerManager:getBallPlayers())
end

local function sendPlayerUpdate()
	for _, pl in ipairs(PlayerManager:getBallPlayers()) do
		updatePlayerRequest(pl)
	end
end

local function addPlayerUpdate(player)
	PlayerManager:addPlayerToBallGame(player)
	sendPlayerUpdate()
end
local function removePlayerUpdate(player)
	PlayerManager:removePlayerFromBallGame(player)
	updatePlayerRequest(player)
	sendPlayerUpdate()
end

local function addPlayer(player,command)
	if command == "ADD" then
		if(not isGameActive.Value) then
			addPlayerUpdate(player)
		end
	end
	if command == "GET" then
		updatePlayerRequest(player)
	end
	if command == "REMOVE" then
		if(not isGameActive.Value) then
			removePlayerUpdate(player)
		end
	end
end

local function sendClientTimerStart(player, duration,info)
	timerStartStop:FireClient(player, "START", duration, info)
end

local function sendClientsTimerStart(duration,info)
	for _, player in ipairs(PlayerManager:getBallPlayers()) do
		sendClientTimerStart(player, duration,info)
	end
end

local function onBallGameStartRequest()
	-- If game is running, don't let players in
	if isGameActive.Value then return end

	if not queueTimer:isRunning() then
		sendClientsTimerStart(QUEUE_TIME_DURATION, "BallGame Starting....")
		queueTimer:start(QUEUE_TIME_DURATION)
		
		ballGameQueueUpdate:FireAllClients("BALLGAME_STARTING")
	end
end

local function onBallGameStopRequest(player)
	if(isGameActive.Value) then
		BallGameStopEvent:Fire()
	end
end

--local function updateTimer()
--	--print("timer running")
--	local players = PlayerManager:getBallPlayers()
--	for _ , player in pairs(players) do
--		timerEvent:FireClient(player, gameTimer:getTimeLeft())
--	end
--end


local function prepareBallGame()
	clearTimer(queueTimer)
	
	PlayerManager:movePlayersToGame("BALL")
	if not gameStartTimer:isRunning() then
		sendClientsTimerStart(START_TIME_DURATION, "BallGame Starts in")
		gameStartTimer:start(START_TIME_DURATION)

		ballGameQueueUpdate:FireAllClients("BALLGAME_PREPARING")
	end
end

local function startBallGame()
	clearTimer(gameStartTimer)
	
	isGameActive.Value = true
	ballGameQueueUpdate:FireAllClients("BALLGAME_STARTED")
	local numberOfPlayers = PlayerManager:getNumberOfBallPlayers()

	--print("BallGame Started")
	--print("players :", PlayerManager:getBallPlayers())
	playerQueue = PlayerManager:getBallPlayers()
	BallManager:setPlayer(playerQueue, GameSettings.BallPushDistance, GameSettings.BallSpeedMax)
	
	if not gameTimer:isRunning() then
		sendClientsTimerStart(BALL_PUSH_TIME, "BallGame")
		gameTimer:start(BALL_PUSH_TIME)
	end
	

	ballPushConnection = game:GetService("RunService").Heartbeat:Connect(function(time)
		BallManager:updateLocation(time)
	end)
	ballCheckConnection = game:GetService("RunService").Heartbeat:Connect(function()
		BallManager:ballCheck()
	end)
	BallGameStartEvent:Fire()
end

local function ballPush()
	local players = PlayerManager:getBallPlayers()
	local playerNum = PlayerManager:getNumberOfBallPlayers()
	
	for _ , player in pairs(players) do
		ActivateBallPushAnim:FireClient(player, GameSettings.BallPushDistance, GameSettings.BallSpeedMax)
		timerStartStop:FireClient(player, "start")
	end
	
	
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

local function ballPushStop(stat)
	clearTimer(gameTimer)
	if(isGameActive.Value) then
		isGameActive.Value = false
		ballGameQueueUpdate:FireAllClients("BALLGAME_STOP")
		
		local players = PlayerManager:getBallPlayers()
		for _ , player in pairs(players) do
			DectivateBallPushAnim:FireClient(player)
			timerStartStop:FireClient(player,"STOP")
			ClientTriggerBallGameStop:FireClient(player, stat, START_TIME_DURATION, "BallGame Ends in...")
		end
		
		stopConnection()
		
		gameTimer:stop()
		BallManager:stopPush()
		
		
		--has to be chainged
		wait(3)
		PlayerManager:movePlayersToSpawn("BALL")
		playerQueue = {}
		PlayerManager:endBallPlayers()
	end
end






ClientTriggerBallGame.OnServerEvent:Connect(function(player)
	if(not WholeGameMode.Value) then
		TriggerBallGameEvent:Fire()
	else
		ballGameQueueUpdate:FireClient("WHOLE_GAME_WAITING")
	end
	
end)

--NOT UPDATED ON REAL SERVER
ClientTriggerBallGameStop.OnServerEvent:Connect(function(player)
	print(player,"fire stop")
	onBallGameStopRequest()
end)

RemoteAddPlayer.OnServerEvent:Connect(addPlayer)
queueTimer.finished:Connect(prepareBallGame)
gameStartTimer.finished:Connect(startBallGame)
--WholeGameMode Start
TriggerBallGameEvent.Event:connect(onBallGameStartRequest)
BallGameStartEvent.Event:connect(ballPush)
BallGameStopEvent.Event:connect(ballPushStop)
gameTimer.finished:Connect(function()
	if(isGameActive.Value) then
		BallGameStopEvent:Fire("FAIL")
	end
end)