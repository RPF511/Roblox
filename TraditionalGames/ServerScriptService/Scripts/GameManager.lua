local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

---- Events Folder ------------------------------------------------------
--RemoteEvents
local EventsManager = ReplicatedStorage:WaitForChild("EventsManager")
local EventsReplicated = ReplicatedStorage:WaitForChild("Events")
local EventsBall = ReplicatedStorage:WaitForChild("EventsBall")
local EventsTuho = ReplicatedStorage:WaitForChild("EventsTuho")
local EventsRope = ReplicatedStorage:WaitForChild("EventsRope")
local RemoteQueue = EventsReplicated:WaitForChild("RemoteQueue")

local ClientTriggerBall = EventsBall:WaitForChild("ClientTriggerBall")
local ClientTriggerTuho = EventsTuho:WaitForChild("ClientTriggerTuho")
local ClientTriggerRope = EventsRope:WaitForChild("ClientTriggerRope")

--BindableEvents - Server
local EventsServer = ServerStorage:WaitForChild("Events")
local TeleportPlayer = EventsServer:WaitForChild("TeleportPlayer")
local SendTimer = EventsServer:WaitForChild("SendTimer")
local RopeGameSet = EventsServer:WaitForChild("RopeGameSet")

--BindableEvents - Ball
local BallGameStartStop = EventsServer:WaitForChild("BallGameStartStop")
local TuhoGameStartStop = EventsServer:WaitForChild("TuhoGameStartStop")
local RopeGameStartStop = EventsServer:WaitForChild("RopeGameStartStop")


--Manager Authority
local ManagerAuth = EventsManager:WaitForChild("ManagerAuth")
--Manager Function Connection
local ManagerConnection = EventsManager:WaitForChild("ManagerConnection")


---- ManageModules ----
local PlayerManager = require(ServerStorage.ModuleScripts.PlayerManager)
local BallGameManager = require(ServerStorage.ModuleScripts.BallGameManager)
local TuhoGameManager = require(ServerStorage.ModuleScripts.TuhoGameManager)
local RopeGameManager = require(ServerStorage.ModuleScripts.RopeGameManager)


local WholeGameMode = ServerStorage.Configurations.WholeGameMode
local GameSettings = require(ServerStorage.Configurations.GameSettings)
local MANAGER_KEY = GameSettings.ManagerKey
local MANAGER_LIST = GameSettings.ManagerAuthorized

local WholeGameStarted = false
local WholeGameStatus = "BALLTUHO"
local BallPlaying = false
local TuhoPlaying = false




local function sendClientTimer(command, kinds, gameName,detail,duration,info)
	if(command == "START") or (command == "STOP") then
		PlayerManager:sendClientsTimer(command, kinds,gameName,detail,duration,info)
	else
		PlayerManager:sendClientTimerSingle("START", kinds, duration, info)
	end
end

local function clearWholeGame()
	WholeGameStarted = false
	WholeGameStatus = "BALLTUHO"
	BallPlaying = false
	TuhoPlaying = false
end




------Player Function----------------------------------------------

local function findPlayer(playerName)
	local allPlayers = Players:GetPlayers()
	for _, player in ipairs(allPlayers) do
		if player.Name == playerName then
			return player
		end
	end
	return nil
end

local function handleQueue(player, command, kinds, gameName, detail, playerName)
	if command == "ADD" then
		--if(not WholeGameMode.Value) then
		--	PlayerManager:addPlayerQueue(player,gameName,detail)
		--	PlayerManager:updatePlayers(kinds,gameName,"ALL")
		--end
		PlayerManager:addPlayerQueue(player,gameName,detail)
	end
	if command == "GET" then
		PlayerManager:updatePlayerSingle(player,kinds,gameName,detail)
	end
	if command == "REMOVE" then
		PlayerManager:removePlayer(player,kinds,gameName,detail)
	end
	if command == "ADD_SERVER" then
		if(WholeGameMode.Value) then
			local foundplayer = findPlayer(playerName)
			if(foundplayer) then
				PlayerManager:addPlayerQueue(foundplayer,gameName,detail)
			end
		end
	end
	if command == "GET_PLAYING" then
		PlayerManager:updatePlaying(player,"Playing")
	end
end

local function handleTeleport(command,fromKinds, fromGameName, destination, detail, player)
	if(command == "TEAM") then
		PlayerManager:moveAndUpdateGame(fromKinds, fromGameName, destination, detail)
	end
	if(command == "SINGLE") then
		PlayerManager:moveAndUpdateSingle(player, fromKinds, fromGameName, destination, detail)
	end
end


----------------------------------------------------------------------


------Ball Function---------------------------------------------------
local function handleClientTriggerBall(player)
	if(not WholeGameMode.Value) then
		BallGameManager:ballGameStartRequest()
	end
end

local function handleBallStatus(command, info)
	if(command == "START_READY") then
		BallGameStartStop:Fire("START", PlayerManager:getPlayers("Playing","Ball","ALL"))
		PlayerManager:setAnimation("START", "Ball","ALL")
		BallPlaying = true
	end
	if(command == "SUCCESS") then
		local score = BallGameManager:calculateScore(info)
		sendClientTimer("STOP", "Playing","Ball",info,0,"SUCCESS")
		BallGameStartStop:Fire("STOP", command)
		
		PlayerManager:sendResult("Ball",command, info, score)
	end
	if(command == "FAIL") then
		BallGameStartStop:Fire("STOP", command)
	end
	if(command == "SERVER") then
		BallGameStartStop:Fire("STOP", command)
		sendClientTimer("STOP", "Playing","Ball","ALL",0,"SERVER")
	end
	if(command == "END") then
		local score = BallGameManager:getScore()
		for teamName, sc in pairs(score) do
			if(sc == 0) then
				PlayerManager:sendResult("Ball","FAIL", teamName, sc)
			end
		end
		PlayerManager:setAnimation("STOP", "Ball", "ALL")
		if (WholeGameMode.Value) then
			PlayerManager:setPlayers("Playing","Ball","A")
			PlayerManager:setPlayers("Playing","Ball","B")
			BallPlaying = false
			if(not TuhoPlaying) then
				WholeGameStarted = false
			end
		end
		
	end
end


------Tuho Function---------------------------------------------------

local function handleTuhoStatus(command, info)
	if(command == "PREPARE") then
		TuhoGameManager:prepareTuhoGame(PlayerManager:getPlayers("Playing","Tuho","ALL"))
	end
	if(command == "START_READY") then
		TuhoGameStartStop:Fire("START")
		TuhoPlaying = true
	end
	if(command == "TIMER_END") then
		TuhoGameStartStop:Fire("STOP")
	end
	if(command == "SERVER") then
		TuhoGameStartStop:Fire("STOP", command)
		sendClientTimer("STOP", "Playing","Tuho","ALL",0,"SERVER")
	end
	if(command == "END") then
		if (WholeGameMode.Value) then
			PlayerManager:setPlayers("Playing","Tuho","EASY")
			PlayerManager:setPlayers("Playing","Tuho","HARD")
			TuhoPlaying = false
			if(not BallPlaying) then
				WholeGameStarted = false
			end
		end
	end
end


------Rope Function---------------------------------------------------
local function handleClientTriggerRope(player)
	if(not WholeGameMode.Value) then
		RopeGameManager:RopeGameStartRequest()
	end
end


local function handleRopePlayerSet(command)
	if command == "GET_PLAYER" then
		RopeGameSet:Fire("SET_PLAYER", PlayerManager:getPlayers("Queue","Rope","ALL"))
	end
	if command == "ROPE_START" then
		RopeGameSet:Fire("ACTIVATE_FORCE_GET", PlayerManager:getPlayers("Playing","Rope","ALL"))
	end
	if command == "ROPE_STOP" then
		RopeGameSet:Fire("DEACTIVATE_FORCE_GET", PlayerManager:getPlayers("Playing","Rope","ALL"))
	end
	
end

local function handleRopeStatus(command, info)
	if(command == "START_READY") then
		RopeGameStartStop:Fire("START")
	end
	if(command == "WIN") then
		sendClientTimer("STOP", "Playing","Rope","ALL",0,"SUCCESS")
		RopeGameStartStop:Fire("STOP")
		print("win")
		if(info == "A") then
			PlayerManager:sendResult("Rope", "WIN", "A", "WIN")
			PlayerManager:sendResult("Rope", "DEFEAT", "B", "DEFEAT")
		end
		if(info == "B") then
			PlayerManager:sendResult("Rope", "WIN", "B", "WIN")
			PlayerManager:sendResult("Rope", "DEFEAT", "A", "DEFEAT")
		end
		
	end
	if(command == "DRAW") then
		PlayerManager:sendResult("Rope", "DRAW", "B", "DRAW")
		PlayerManager:sendResult("Rope", "DRAW", "A", "DRAW")
	end
	if(command == "SERVER") then
		RopeGameStartStop:Fire("STOP", command)
		sendClientTimer("STOP", "Playing","Rope","ALL",0,"SERVER")
		PlayerManager:sendResult("Rope", "SERVER", "B", "SERVER")
		PlayerManager:sendResult("Rope", "SERVER", "A", "SERVER")
	end
	if(command == "END") then
		if (WholeGameMode.Value) then
			clearWholeGame()
		end
	end
end

------Set GameMode---------------------------------------------------
local function getGameMode(player)
	if(WholeGameMode.Value) then
		ManagerConnection:FireClient(player,"GET_GAME_MODE", "Whole Game Mode")
	else
		ManagerConnection:FireClient(player,"GET_GAME_MODE", "Individual Game Mode")
	end

end

local function changeGameMode(player)
	if(WholeGameMode.Value) then
		WholeGameMode.Value = false
	else
		handleBallStatus("SERVER")
		handleTuhoStatus("SERVER")
		handleRopeStatus("SERVER")
		WholeGameMode.Value = true
	end
	getGameMode(player)
end

local function verifyManager(player)
	for _, managerName in ipairs(MANAGER_LIST) do
		if player.Name == managerName then
			ManagerAuth:FireClient(player,MANAGER_KEY)
		end
	end

end
----------------------------------------------------------------------

local function moveBallTuho()
	BallGameManager:ballGameStartRequest()
	TuhoGameManager:tuhoGameStartRequest()
	WholeGameStarted = true
end



local function handleCommand(player, command)
	if command == "CHANGE_MODE" then
		changeGameMode(player)
	end
	if command == "GET_GAME_MODE" then
		getGameMode(player)
	end
	if command == "WHOLE_GAME_STOP" then
		handleBallStatus("SERVER")
		handleTuhoStatus("SERVER")
		handleRopeStatus("SERVER")
	end
	if command == "WHOLE_GAME_MOVE" then
		if WholeGameMode.Value and not WholeGameStarted then
			if WholeGameStatus == "BALLTUHO" then
				moveBallTuho()
				PlayerManager:exitPage()
			end
			if WholeGameStatus == "ROPE" then
				RopeGameManager:RopeGameStartRequest()
				WholeGameStarted = true
				PlayerManager:exitPage()
			end
		end
	end
	if command == "WHOLE_GAME_START" then
		if WholeGameMode.Value and WholeGameStarted then
			if WholeGameStatus == "BALLTUHO" then
				BallGameManager:prepareTimerStart()
				TuhoGameManager:prepareTimerStart()
				
			end
			if WholeGameStatus == "ROPE" then
				RopeGameManager:prepareTimerStart()
			end
		end
	end
	if command == "CHANGE_BALL_TUHO" then
		if WholeGameMode.Value and not WholeGameStarted then
			PlayerManager:changeTuhoBall()
			PlayerManager:showPage()
		end
	end
	if command == "MOVE_TO_ROPE" then
		if WholeGameMode.Value and not WholeGameStarted then
			PlayerManager:moveToRopeQueue()
			WholeGameStatus = "ROPE"
		end
	end
end


----Game Manager------------------------------------------------------
ManagerAuth.OnServerEvent:Connect(verifyManager)
ManagerConnection.OnServerEvent:Connect(handleCommand)


----------------------------------------------------------------------


----Player Queue------------------------------------------------------
RemoteQueue.OnServerEvent:Connect(handleQueue)
SendTimer.Event:Connect(sendClientTimer)
TeleportPlayer.Event:Connect(handleTeleport)
----------------------------------------------------------------------

----Ball Game---------------------------------------------------------
ClientTriggerBall.OnServerEvent:Connect(handleClientTriggerBall)
BallGameStartStop.Event:Connect(handleBallStatus)
----------------------------------------------------------------------

----Tuho Game---------------------------------------------------------
TuhoGameStartStop.Event:Connect(handleTuhoStatus)
----------------------------------------------------------------------

----Rope Game---------------------------------------------------------
ClientTriggerRope.OnServerEvent:Connect(handleClientTriggerRope)
RopeGameStartStop.Event:Connect(handleRopeStatus)
RopeGameSet.Event:Connect(handleRopePlayerSet)
----------------------------------------------------------------------


