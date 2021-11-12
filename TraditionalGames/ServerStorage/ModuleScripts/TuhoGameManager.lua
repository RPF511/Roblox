local TuhoGameManager = {} 

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientTriggerTuho = ReplicatedStorage:WaitForChild("EventsTuho"):WaitForChild("ClientTriggerTuho")
local ScoreEvent = ReplicatedStorage:WaitForChild("EventsTuho"):WaitForChild("ScoreEvent")
local TimerStartStop = ReplicatedStorage:WaitForChild("EventsTimer"):WaitForChild("TimerStartStop")
--local Inputable = ReplicatedStorage:WaitForChild("EventsTuho"):WaitForChild("Inputable")

--Server Events
local EventsServer = ServerStorage:WaitForChild("Events")
local TuhoGameStartStop = EventsServer:WaitForChild("TuhoGameStartStop")
local TeleportPlayer = EventsServer:WaitForChild("TeleportPlayer")
local SendTimer = EventsServer:WaitForChild("SendTimer")
local TuhoHIT = EventsServer:WaitForChild("TuhoHIT")
local TuhoGameStartStop = EventsServer:WaitForChild("TuhoGameStartStop")

--GameSettings
local IsGameActive = true
local GameSettings = require(ServerStorage.Configurations.GameSettings)
local QUEUE_TIME_DURATION = GameSettings.QueueTime
local START_TIME_DURATION = GameSettings.GameStartTime
local TUHO_TIME_DURATION = GameSettings.TuhoTime
local WholeGameMode = ServerStorage.Configurations.WholeGameMode

local complexDart = ServerStorage:WaitForChild("Weapons"):WaitForChild("ComplexDart")
local ComplexDartHARD = ServerStorage:WaitForChild("Weapons"):WaitForChild("ComplexDartHARD")

local players = {
	EASY = {},
	HARD = {}
}

local Timer = require(ServerStorage.Classes.Timer)
local TimerTable = {
	QueueTimer = Timer.new(),
	GameStartTimer = Timer.new(),
	GameTimer = Timer.new(),
	EndTimer = Timer.new()
}

local scoreListenConnection = nil

local function equipDart(player, mode)
	local character = player.Character
	if character and character.Humanoid then
		local humanoid = character.Humanoid
		local weaponCopy
		if(mode == "EASY") then
			weaponCopy = complexDart:Clone()
		end
		if(mode == "HARD") then
			weaponCopy = ComplexDartHARD:Clone()
		end
		weaponCopy.Parent = player.Backpack
		humanoid:EquipTool(weaponCopy)
	end
end

local function unequip(player)
	local character = player.Character
	if character and character.Humanoid then
		local humanoid = character.Humanoid
		humanoid:UnequipTools()
		for _, item in ipairs(player.Backpack:GetChildren()) do
			if item.Name == "ComplexDart" then
				item:Destroy()
			end
			if item.Name == "ComplexDartHARD" then
				item:Destroy()
			end
		end
	end
end

local function getPoints(player, point)
	ScoreEvent:FireClient(player, point)
end


local function tuhoListen()
	if(not scoreListenConnection) then
		scoreListenConnection = TuhoHIT.Event:connect(getPoints)
	end
end

local function stopTuhoListen()
	if(scoreListenConnection) then
		scoreListenConnection:Disconnect()
		scoreListenConnection = nil
	end
end

local function sendClientTimerStart(player,command, duration, info)
	TimerStartStop:FireClient(player, command, duration, info)
end


function TuhoGameManager:tuhoGameStartRequestSingle(player,mode)
	if (not WholeGameMode.Value) then
		sendClientTimerStart(player, "TUHO_SINGLE_PREPARE" , QUEUE_TIME_DURATION, "TuhoGame Starting...")
	end
end

local function prepareTuhoGameSingle(player,mode)
	table.insert(players[mode],player)
	TeleportPlayer:Fire("SINGLE", "Queue", "Tuho", "Tuho", mode, player)
	sendClientTimerStart(player, "TUHO_SINGLE_START" , START_TIME_DURATION, "TuhoGame Starts in")
end

local function startTuhoGameSingle(player,mode)
	equipDart(player, mode)
	sendClientTimerStart(player, "TUHO_SINGLE_STARTED" , TUHO_TIME_DURATION, "TuhoGame")
	tuhoListen()
end


local function stopTuhoGameSingle(player)
	unequip(player)
	local index = table.find(players, player)
	if index  then
		table.remove(players, index)
	end
	ClientTriggerTuho:FireClient(player,"TUHOGAME_STOP")
	--Inputable:FireClient(player,"TUHOGAME_STOP")
	sendClientTimerStart(player, "TUHO_SINGLE_END" , START_TIME_DURATION, "TuhoGame Ends in")
end

local function handleTuhoSingle(player, mode, info)
	if (not WholeGameMode.Value) and (info == "START_REQUEST") then
		TuhoGameManager:tuhoGameStartRequestSingle(player,mode)
	end
	if (info == "TUHO_SINGLE_PREPARE") then
		prepareTuhoGameSingle(player,mode)
	end
	if (info == "TUHO_SINGLE_START") then
		startTuhoGameSingle(player,mode)
		ClientTriggerTuho:FireClient(player,"TUHOGAME_STARTED")
	end
	if (info == "TUHO_SINGLE_END") then
		TeleportPlayer:Fire("SINGLE", "Playing", "Tuho", "Lobby", mode, player)
	end
end

local function listenClientTimer(player, command)
	if(not WholeGameMode.Value) then
		if(command == "TUHO_SINGLE_PREPARE") then
			ClientTriggerTuho:FireClient(player,"GET_MODE", command)
		end
		if(command == "TUHO_SINGLE_START") then
			ClientTriggerTuho:FireClient(player,"GET_MODE",command)
		end
		if(command == "SINGLE_END") then
			stopTuhoGameSingle(player)
		end
		if(command == "TUHO_SINGLE_END") then
			ClientTriggerTuho:FireClient(player,"GET_MODE",command)
		end
	end
end

function TuhoGameManager:tuhoGameStartRequest()
	if not TimerTable["QueueTimer"]:isRunning() then
		SendTimer:Fire("START","Queue","Tuho","ALL",QUEUE_TIME_DURATION,"TuhoGame Starting....")
		TimerTable["QueueTimer"]:start(QUEUE_TIME_DURATION)
	end
end

function TuhoGameManager:prepareTimerStart()
	SendTimer:Fire("START","Playing","Tuho","ALL",QUEUE_TIME_DURATION,"TuhoGame Starts in")
	TimerTable["GameStartTimer"]:start(START_TIME_DURATION)
end


function TuhoGameManager:prepareTuhoGame(Players)
	--print(Players)
	players = Players
	stopTuhoListen()
	TeleportPlayer:Fire("TEAM","Queue", "Tuho", "Tuho", "ALL")
	for _, player in ipairs(players["EASY"]) do
		equipDart(player, "EASY")
	end
	for _, player in ipairs(players["HARD"]) do
		equipDart(player, "HARD")
	end
	if not TimerTable["GameStartTimer"]:isRunning() and (not WholeGameMode.Value) then
		TuhoGameManager:prepareTimerStart()
	end
end


local function startTuhoGame()
	print(players)
	TimerTable["GameStartTimer"]:stop()
	for _, player in ipairs(players["EASY"]) do
		ClientTriggerTuho:FireClient(player,"TUHOGAME_STARTED")
	end
	for _, player in ipairs(players["HARD"]) do
		ClientTriggerTuho:FireClient(player,"TUHOGAME_STARTED")
	end
	
	tuhoListen()
	if TimerTable["GameTimer"]:isRunning() then
		TimerTable["GameTimer"]:stop()
	end
	
	SendTimer:Fire("START","Playing","Tuho","ALL",TUHO_TIME_DURATION,"TuhoGame")
	TimerTable["GameTimer"]:start(TUHO_TIME_DURATION)

	
	

end

local function stopTuhoGame(stat)
	IsGameActive = false
	stopTuhoListen()
	SendTimer:Fire("STOP","Playing","Tuho","ALL",START_TIME_DURATION,"TuhoGame Ends in...")
	for _, player in ipairs(players["EASY"]) do
		unequip(player)
		ClientTriggerTuho:FireClient(player,"TUHOGAME_STOP")
	end
	for _, player in ipairs(players["HARD"]) do
		unequip(player)
		ClientTriggerTuho:FireClient(player,"TUHOGAME_STOP")
	end
	
	
	if not WholeGameMode.Value then
		if not TimerTable["EndTimer"]:isRunning() then
			SendTimer:Fire("START","Playing","Tuho","ALL",START_TIME_DURATION,"TuhoGame Ends in...")
			TimerTable["EndTimer"]:start(START_TIME_DURATION)
		end
	end
	
	TuhoGameStartStop:Fire("END")
end



local function handleTuhoGame(command, info)
	if(command == "START") then
		startTuhoGame()
	end
	if(command == "STOP") then
		TimerTable["GameTimer"]:stop()
		stopTuhoGame(info)
	end
end

TimerTable["QueueTimer"].finished:Connect(function()
	TimerTable["QueueTimer"]:stop()
	TuhoGameStartStop:Fire("PREPARE")
end)

TimerTable["GameStartTimer"].finished:Connect(function()
	TimerTable["GameStartTimer"]:stop()
	TuhoGameStartStop:Fire("START_READY")
end)

TimerTable["GameTimer"].finished:Connect(function()
	TimerTable["GameTimer"]:stop()
	TuhoGameStartStop:Fire("TIMER_END")
end)

TimerTable["EndTimer"].finished:Connect(function()
	TimerTable["EndTimer"]:stop()
	TeleportPlayer:Fire("TEAM", "Playing", "Tuho", "Lobby", "ALL")
end)

TimerStartStop.OnServerEvent:Connect(listenClientTimer)
ClientTriggerTuho.onServerEvent:Connect(handleTuhoSingle)
TuhoGameStartStop.Event:Connect(handleTuhoGame)

return TuhoGameManager
