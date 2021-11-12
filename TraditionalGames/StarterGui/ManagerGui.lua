-- ProximityPrompts
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventsManager = ReplicatedStorage:WaitForChild("EventsManager")

local ManagerAuth = EventsManager:WaitForChild("ManagerAuth")
local ManagerConnection = EventsManager:WaitForChild("ManagerConnection")


local RemoteQueue = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteQueue")
local RemotePlaying = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemotePlaying")

local UIS = game:GetService("UserInputService")

local managerGUI = script.Parent
local managerPlatform = game.Workspace.Lobby:WaitForChild("WholeGameManager")
local proximityPlay = managerPlatform:WaitForChild("ProximityPrompt")
local ManagerScreen = managerGUI:WaitForChild("ManagerScreen")
local GetManagerGUI = ManagerScreen:WaitForChild("GetManagerGui")
local ManagerMainGUI = ManagerScreen:WaitForChild("ManagerMainGui")
local PlayingQueueGui = ManagerScreen:WaitForChild("PlayingQueueGui")


-- Buttons
local exitBtn = GetManagerGUI:WaitForChild("ExitBtn")
local GetManagerBtn = GetManagerGUI:WaitForChild("GetManager")


-- Manager Buttons
local GameModeLabel = ManagerMainGUI:WaitForChild("GameModeLabel")
local managerExitBtn = ManagerMainGUI:WaitForChild("ExitBtn")
local changeGameModeBtn = ManagerMainGUI:WaitForChild("ChangeModeBtn")
local MoveToGame = ManagerMainGUI:WaitForChild("MoveToGame")
local WholeGameStartBtn = ManagerMainGUI:WaitForChild("WholeGameStartBtn")
local ChangeBallTuhoBtn = ManagerMainGUI:WaitForChild("ChangeBallTuhoBtn")
local QueueToRopeBtn = ManagerMainGUI:WaitForChild("QueueToRopeBtn")
local WholeGameStopBtn = ManagerMainGUI:WaitForChild("WholeGameStopBtn")
local PlayingQueueBtn = ManagerMainGUI:WaitForChild("PlayingQueueBtn")

local ManagerScreenName = "WholeGameManage"
local ManagerKeyBindConnection = nil
local ManagerScreenKey = nil


local individualTXT = "Individual Game Mode"
local wholeTXT = "Whole Game Mode"

--QueueADDtext
local BallAName = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("BallA")
local BallBName = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("BallB")
local TuhoEasyName = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("TuhoEasy")
local TuhoHardName = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("TuhoHard")
local RopeAName = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("RopeA")
local RopeBName = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("RopeB")

--QueueADDBtn
local BallABtn = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("BallABtn")
local BallBBtn = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("BallBBtn")
local TuhoEasyBtn = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("TuhoEasyBtn")
local TuhoHardBtn = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("TuhoHardBtn")
local RopeABtn = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("RopeABtn")
local RopeBBtn = ManagerMainGUI:WaitForChild("QueueADD"):WaitForChild("RopeBBtn")

--Queue
local BallAPlayers = ManagerMainGUI:WaitForChild("BallAQueue"):WaitForChild("TextLabel")
local BallBPlayers = ManagerMainGUI:WaitForChild("BallBQueue"):WaitForChild("TextLabel")
local TuhoEasyPlayers = ManagerMainGUI:WaitForChild("TuhoEasyQueue"):WaitForChild("TextLabel")
local TuhoHardPlayers = ManagerMainGUI:WaitForChild("TuhoHardQueue"):WaitForChild("TextLabel")
local RopeAPlayers = ManagerMainGUI:WaitForChild("RopeAQueue"):WaitForChild("TextLabel")
local RopeBPlayers = ManagerMainGUI:WaitForChild("RopeBQueue"):WaitForChild("TextLabel")

--Playing
local BallAPlaying = PlayingQueueGui:WaitForChild("BallAPlaying"):WaitForChild("TextLabel")
local BallBPlaying = PlayingQueueGui:WaitForChild("BallBPlaying"):WaitForChild("TextLabel")
local TuhoEasyPlaying = PlayingQueueGui:WaitForChild("TuhoEasyPlaying"):WaitForChild("TextLabel")
local TuhoHardPlaying = PlayingQueueGui:WaitForChild("TuhoHardPlaying"):WaitForChild("TextLabel")
local RopeAPlaying = PlayingQueueGui:WaitForChild("RopeAPlaying"):WaitForChild("TextLabel")
local RopeBPlaying = PlayingQueueGui:WaitForChild("RopeBPlaying"):WaitForChild("TextLabel")
local PlayingExitBtn = PlayingQueueGui:WaitForChild("ExitBtn")


local function openGetManagerGUI()
	GetManagerGUI.Visible = true
end

local function playingOpen()
	RemoteQueue:FireServer("GET_PLAYING")
	PlayingQueueGui.Visible = true
end


local function exit()
	GetManagerGUI.Visible = false
end

local function getManagerAuth()
	ManagerAuth:FireServer()
	GetManagerGUI.Visible = false
end

local function updatePlayerQueue(info,APlayers,BPlayers)
	local text = ""
	if info["A"] then
		for _, player in ipairs(info["A"]) do
			text = text .. player.Name .. "\n"
		end
	end
	APlayers.Text = text
	text = ""
	if info["B"] then
		for _, player in ipairs(info["B"]) do
			text = text .. player.Name .. "\n"
		end
	end
	BPlayers.Text = text
end

local function updatePlayerTuho(info)
	local text = ""
	if info["EASY"] then
		for _, player in ipairs(info["EASY"]) do
			text = text .. player.Name .. "\n"
		end
	end
	TuhoEasyPlayers.Text = text
	text = ""
	if info["HARD"] then
		for _, player in ipairs(info["HARD"]) do
			text = text .. player.Name .. "\n"
		end
	end
	TuhoHardPlayers.Text = text
end

local function updatePlayerPlaying(info)
	local text = ""
	for _, player in ipairs(info["Ball"]["A"]) do
		text = text .. player.Name .. "\n"
	end
	BallAPlaying.Text = text
	text = ""
	for _, player in ipairs(info["Ball"]["B"]) do
		text = text .. player.Name .. "\n"
	end
	BallBPlaying.Text = text
	for _, player in ipairs(info["Tuho"]["EASY"]) do
		text = text .. player.Name .. "\n"
	end
	TuhoEasyPlaying.Text = text
	text = ""
	for _, player in ipairs(info["Tuho"]["HARD"]) do
		text = text .. player.Name .. "\n"
	end
	TuhoHardPlaying.Text = text
	for _, player in ipairs(info["Rope"]["A"]) do
		text = text .. player.Name .. "\n"
	end
	RopeAPlaying.Text = text
	text = ""
	for _, player in ipairs(info["Rope"]["B"]) do
		text = text .. player.Name .. "\n"
	end
	RopeBPlaying.Text = text
end



local function managerExit()
	ManagerMainGUI.Visible = false
end
local function playingExit()
	
	PlayingQueueGui.Visible = false
end





local function setBtnVisible(stat)
	MoveToGame.Visible = stat
	ChangeBallTuhoBtn.Visible = stat
	QueueToRopeBtn.Visible = stat
	WholeGameStartBtn.Visible = stat
	WholeGameStopBtn.Visible = stat
	BallAName.Visible = stat
	BallBName.Visible = stat
	TuhoEasyName.Visible = stat
	TuhoHardName.Visible = stat
	RopeAName.Visible = stat
	RopeBName.Visible = stat
	BallABtn.Visible = stat
	BallBBtn.Visible = stat
	TuhoEasyBtn.Visible = stat
	TuhoHardBtn.Visible = stat
	RopeABtn.Visible = stat
	RopeBBtn.Visible = stat
end

local function setWholeBtn()
	if(GameModeLabel.Text == "Whole Game Mode") then
		setBtnVisible(true)
	end
	if(GameModeLabel.Text == "Individual Game Mode") then
		setBtnVisible(false)
	end
end

local function changeGameMode()
	ManagerConnection:FireServer("CHANGE_MODE")
end

local function showGameMode(info)
	GameModeLabel.Text = info
	setWholeBtn()
end

local function managerScreen(key, gameprocessed)
	if gameprocessed then return end
	if key.KeyCode == ManagerScreenKey then
		if(ManagerMainGUI.Visible) then
			ManagerMainGUI.Visible = false
			PlayingQueueGui.Visible = false
		else
			RemoteQueue:FireServer("GET","Queue","Rope","ALL")
			RemoteQueue:FireServer("GET","Queue","Tuho","ALL")
			RemoteQueue:FireServer("GET","Queue","Rope","ALL")
			ManagerMainGUI.Visible = true
			ManagerConnection:FireServer("GET_GAME_MODE")
			--setWholeBtn()
		end
	end
end
local function setManage(key)
	ManagerScreenKey = key
	ManagerKeyBindConnection = UIS.InputBegan:Connect(managerScreen)
end

local function listenCommand(command, info)
	if command == "GET_GAME_MODE" then
		showGameMode(info)
	end
end

local function wholeGameStop()
	ManagerConnection:FireServer("WHOLE_GAME_STOP")
end

local function wholeGameStart()
	ManagerConnection:FireServer("WHOLE_GAME_START")
end

local function updatePlayer(command,gameName,info)
	if command == "UPDATE" and gameName == "Rope" then
		updatePlayerQueue(info,RopeAPlayers,RopeBPlayers)
	end
	if command == "UPDATE" and gameName == "Tuho" then
		updatePlayerTuho(info)
	end
	if command == "UPDATE" and gameName == "Ball" then
		updatePlayerQueue(info,BallAPlayers,BallBPlayers)
	end
	if command == "UPDATE_Playing" and gameName == "ALL" then
		updatePlayerPlaying(info)
	end
end


proximityPlay.Triggered:Connect(openGetManagerGUI)
exitBtn.MouseButton1Click:Connect(exit)
GetManagerBtn.MouseButton1Click:Connect(getManagerAuth)
ManagerAuth.OnClientEvent:Connect(setManage)
managerExitBtn.MouseButton1Click:Connect(managerExit)
PlayingQueueBtn.MouseButton1Click:Connect(playingOpen)
PlayingExitBtn.MouseButton1Click:Connect(playingExit)
changeGameModeBtn.MouseButton1Click:Connect(changeGameMode)
ManagerConnection.OnClientEvent:Connect(listenCommand)
WholeGameStopBtn.MouseButton1Click:Connect(wholeGameStop)
WholeGameStartBtn.MouseButton1Click:Connect(wholeGameStart)

RemoteQueue.OnClientEvent:Connect(updatePlayer)
BallABtn.MouseButton1Click:Connect(function()
	RemoteQueue:FireServer("ADD_SERVER","Queue","Ball","A",BallAName.Text)
end)
BallBBtn.MouseButton1Click:Connect(function()
	RemoteQueue:FireServer("ADD_SERVER","Queue","Ball","B",BallBName.Text)
end)
TuhoEasyBtn.MouseButton1Click:Connect(function()
	RemoteQueue:FireServer("ADD_SERVER","Queue","Tuho","EASY",TuhoEasyName.Text)
end)
TuhoHardBtn.MouseButton1Click:Connect(function()
	RemoteQueue:FireServer("ADD_SERVER","Queue","Tuho","HARD",TuhoHardName.Text)
end)
RopeABtn.MouseButton1Click:Connect(function()
	RemoteQueue:FireServer("ADD_SERVER","Queue","Rope","A",RopeAName.Text)
end)
RopeBBtn.MouseButton1Click:Connect(function()
	RemoteQueue:FireServer("ADD_SERVER","Queue","Rope","B",RopeBName.Text)
end)


MoveToGame.MouseButton1Click:Connect(function()
	ManagerConnection:FireServer("WHOLE_GAME_MOVE")
end)
WholeGameStartBtn.MouseButton1Click:Connect(function()
	ManagerConnection:FireServer("WHOLE_GAME_START")
end)
ChangeBallTuhoBtn.MouseButton1Click:Connect(function()
	ManagerConnection:FireServer("CHANGE_BALL_TUHO")
end)
QueueToRopeBtn.MouseButton1Click:Connect(function()
	ManagerConnection:FireServer("MOVE_TO_ROPE")
end)
WholeGameStopBtn.MouseButton1Click:Connect(function()
	ManagerConnection:FireServer("WHOLE_GAME_STOP")
end)