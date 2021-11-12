local RopeGameManager = {}


local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RopeManager = require(ServerStorage.ModuleScripts.RopeManager)

local ClientTriggerRope = ReplicatedStorage:WaitForChild("EventsRope"):WaitForChild("ClientTriggerRope")
local RopeAction = ReplicatedStorage:WaitForChild("EventsRope"):WaitForChild("RopeAction")
local RopeData = ReplicatedStorage:WaitForChild("EventsRope"):WaitForChild("RopeData")

--Server Events
local EventsServer = ServerStorage:WaitForChild("Events")
local SendTimer = EventsServer:WaitForChild("SendTimer")
local RopeGameStartStop = EventsServer:WaitForChild("RopeGameStartStop")
local TeleportPlayer = EventsServer:WaitForChild("TeleportPlayer")
local RopeGameSet = EventsServer:WaitForChild("RopeGameSet")

local IsGameActive = false
local GameSettings = require(ServerStorage.Configurations.GameSettings)
local QUEUE_TIME_DURATION = GameSettings.QueueTime
local START_TIME_DURATION = GameSettings.GameStartTime
local ROPE_PULL_TIME = GameSettings.RopePullTime
local WholeGameMode = ServerStorage.Configurations.WholeGameMode

--Timer
local Timer = require(ServerStorage.Classes.Timer)
local TimerTable = {
	QueueTimer = Timer.new(),
	GameStartTimer = Timer.new(),
	GameTimer = Timer.new(),
	EndTimer = Timer.new()
}
local count = 0

local ropeDataConneciton = nil
local ropeMoveConnection = nil


function RopeGameManager:RopeGameStartRequest()
	-- If game is running, don't let players in
	if IsGameActive then return end

	if not TimerTable["QueueTimer"]:isRunning() then
		SendTimer:Fire("START","Queue","Rope","ALL",QUEUE_TIME_DURATION,"RopeGame Starting....")
		TimerTable["QueueTimer"]:start(QUEUE_TIME_DURATION)
	end
end

function setPlayers(players)

	for i, player in ipairs(players["A"]) do
		-- client setAnim
		RopeAction:FireClient(player, "SET","A")
	end
	for i, player in ipairs(players["B"]) do
		-- client setAnim
		RopeAction:FireClient(player, "SET","B")
	end
	RopeManager:setState(players)
end

function RopeGameManager:prepareTimerStart()
	SendTimer:Fire("START","Playing","Rope","ALL",QUEUE_TIME_DURATION,"RopeGame Starts in")
	TimerTable["GameStartTimer"]:start(START_TIME_DURATION)
end

function RopeGameManager:prepareRopeGame()

	if IsGameActive then return end
	
	RopeGameSet:Fire("GET_PLAYER")
	TeleportPlayer:Fire("TEAM","Queue", "Rope", "Rope", "ALL")
	
	if not TimerTable["GameStartTimer"]:isRunning() and (not WholeGameMode.Value) then
		RopeGameManager:prepareTimerStart()
	end
end

local function handleRopeDATA(player, stat, team)
	RopeManager:updatePlayer(player, stat, team)
end

local function getForce(players)
	for i, player in ipairs(players["A"]) do
		--i : playernumber / 1 : magnification
		--it was ActivateRopeAction:FireClient(player)
		RopeAction:FireClient(player, "ACTIVATE")
	end
	for i, player in ipairs(players["B"]) do
		--i : playernumber / 1 : magnification
		RopeAction:FireClient(player, "ACTIVATE")
	end
end

local function startRopeGame()
	RopeManager:resetRope()
	
	if not IsGameActive  then
		IsGameActive = true
	end
	
	if not TimerTable["GameTimer"]:isRunning() then
		SendTimer:Fire("START","Playing","Rope","ALL",ROPE_PULL_TIME,"RopeGame")
		TimerTable["GameTimer"]:start(ROPE_PULL_TIME)
	end

	ropeDataConneciton = RopeData.OnServerEvent:Connect(handleRopeDATA)

	ropeMoveConnection = game:GetService("RunService").Heartbeat:Connect(function(time)
		if(count == 0) then
			RopeManager:updateNet()
			count+=1
		end
		if(count == 1) then
			RopeManager:updateVelocity()
			count+=1
		end
		if(count >=2) then
			RopeManager:updateMove(time)
			count = 0
		end

	end)
	
	RopeGameSet:Fire("ROPE_START")

end

local function stopForce(players)
	for i, player in ipairs(players["A"]) do
		--i : playernumber / 1 : magnification
		--it was ActivateRopeAction:FireClient(player)
		RopeAction:FireClient(player, "DEACTIVATE")
	end
	for i, player in ipairs(players["B"]) do
		--i : playernumber / 1 : magnification
		RopeAction:FireClient(player, "DEACTIVATE")
	end
end


local function stopRopeGame()

	if (IsGameActive) then
		IsGameActive = false
	end
	
	SendTimer:Fire("STOP","Playing","Rope","ALL",START_TIME_DURATION,"RopeGame Ends in...")
	
	if(ropeDataConneciton) then
		ropeDataConneciton:Disconnect()
		ropeDataConneciton = nil
	end
	if(ropeMoveConnection) then
		ropeMoveConnection:Disconnect()
		ropeMoveConnection = nil
	end

	RopeManager:EndRope()

	count = 0
	RopeGameSet:Fire("ROPE_STOP")
	
	if not TimerTable["EndTimer"]:isRunning() then
		SendTimer:Fire("START","Playing","Rope","ALL",START_TIME_DURATION,"RopeGame Ends in...")
		TimerTable["EndTimer"]:start(START_TIME_DURATION)
	end
	RopeGameStartStop:Fire("END")
end



local function handleRopeSet(command, data)
	if(command == "SET_PLAYER") then
		setPlayers(data)
	end
	if(command == "ACTIVATE_FORCE_GET") then
		getForce(data)
	end
	if(command == "DEACTIVATE_FORCE_GET") then
		stopForce(data)
	end
end

local function handleRopeGame(command)
	if(command == "START") then
		startRopeGame()
	end
	if(command == "STOP") then
		if IsGameActive then
			TimerTable["GameTimer"]:stop()
			stopRopeGame()
		end
	end
end


RopeGameSet.Event:Connect(handleRopeSet)

TimerTable["QueueTimer"].finished:Connect(function()
	TimerTable["QueueTimer"]:stop()
	RopeGameManager:prepareRopeGame()
end)

TimerTable["GameStartTimer"].finished:Connect(function()
	TimerTable["GameStartTimer"]:stop()
	RopeGameStartStop:Fire("START_READY")
end)

TimerTable["GameTimer"].finished:Connect(function()
	TimerTable["GameTimer"]:stop()
	RopeGameStartStop:Fire("DRAW")
end)

TimerTable["EndTimer"].finished:Connect(function()
	TimerTable["EndTimer"]:stop()
	RopeManager:RopeToOrigin()
	TeleportPlayer:Fire("TEAM", "Playing", "Rope", "Lobby", "ALL")
end)

RopeGameStartStop.Event:Connect(handleRopeGame)

return RopeGameManager
