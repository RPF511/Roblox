-- ProximityPrompts
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventsTuho = ReplicatedStorage:WaitForChild("EventsTuho")
local RemoteQueue = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteQueue")
local ClientTriggerTuho = EventsTuho:WaitForChild("ClientTriggerTuho")
local ScoreEvent = EventsTuho:WaitForChild("ScoreEvent")

local starterGUI = script.Parent
local tuhoPlatform = game.Workspace.Lobby:WaitForChild("TuhoGame")
local proximityPlay = tuhoPlatform:WaitForChild("ProximityPrompt")
local TuhoGameScreen = starterGUI:WaitForChild("TuhoGameScreen")
local TuhoGUI = TuhoGameScreen:WaitForChild("TuhoGui")
local Points = TuhoGameScreen:WaitForChild("Points")



-- Buttons
local exitBtn = TuhoGUI:WaitForChild("ExitBtn")
local startTuhoBtn = TuhoGUI:WaitForChild("StartTuho")
local startTuhoHardBtn = TuhoGUI:WaitForChild("StartHardTuho")
local StartBtn = TuhoGUI:WaitForChild("StartBtn")
local stopTuholBtn = TuhoGUI:WaitForChild("StopTuho")
local TuhoEasyPlayers = TuhoGUI:WaitForChild("EasyFrame"):WaitForChild("TuhoEasyPlayers")
local TuhoHardPlayers = TuhoGUI:WaitForChild("HardFrame"):WaitForChild("TuhoHardPlayers")
local QueueOut = TuhoGUI:WaitForChild("QueueOut")
local Score = Points:WaitForChild("Score")
local ScoreText = Points:WaitForChild("ScoreText")
local ScoreTextShow = Points:WaitForChild("ScoreTextShow")
local ScoreEnd = Points:WaitForChild("ScoreEnd")


--timer
local Timer = require(ReplicatedStorage.ModuleScripts.Timer)
local scoreTimer = Timer.new()
local endTimer = Timer.new()

local TimerStartStop = ReplicatedStorage:WaitForChild("EventsTimer"):WaitForChild("TimerStartStop")



local gamemode = "EASY"



local function exit()
	TuhoGUI.Visible = false
end

local function openTuhoGUI(exit)
	RemoteQueue:FireServer("GET","Queue","Tuho","ALL")
	TuhoGUI.Visible = true
	exitBtn.Visible = exit
end


local function addPlayer(mode)
	gamemode = mode

	RemoteQueue:FireServer("ADD","Queue","Tuho",mode)

	ClientTriggerTuho:FireServer(gamemode, "START_REQUEST")
end

local function RemovePlayer()
	RemoteQueue:FireServer("REMOVE","Queue","Tuho","ALL")

end

local function updatePlayerShow(info)
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

local function updatePlayer(command,gameName,info)
	if command == "UPDATE" and gameName == "Tuho" then
		updatePlayerShow(info)
	end
end



local function queueUpdate(state, info)
	if(state == "OPEN_GUI") then
		openTuhoGUI(false)
		return
	end
	if(state == "CLOSE_GUI") then
		exit()
		return
	end
	if(state == "TUHOGAME_STARTED") then
		Points.Visible = true
		Score.Visible = true
		ScoreText.Visible = true
	end
	if(state == "TUHOGAME_STOP") then
		Score.Visible = false
		ScoreText.Visible = false
		ScoreTextShow.Visible = false
		--Points.Visible = false
		if(endTimer:isRunning()) then
			endTimer:stop()
		end
		ScoreEnd.Text = "Score " .. Score.Text .."!!"
		ScoreEnd.Visible = true
		endTimer:start(2)
	end
	if(state == "GET_MODE") then
		if(info == "TUHO_SINGLE_PREPARE") then
			exit()
		end
		ClientTriggerTuho:FireServer(gamemode, info)
	end
end

local function removeScoreEndShow()
	if(endTimer:isRunning()) then
		endTimer:stop()
	end
	ScoreEnd.Visible = false
	Score.Text = 0
	Points.Visible = false
end

local function updateScore(score)
	Score.Text += score
	ScoreTextShow.Visible = true
	if(scoreTimer:isRunning()) then
		scoreTimer:stop()
	end
	scoreTimer:start(1)
end

local function removeScoreTextShow()
	if(scoreTimer:isRunning()) then
		scoreTimer:stop()
	end
	ScoreTextShow.Visible = false
end




exitBtn.MouseButton1Click:Connect(exit)
proximityPlay.Triggered:Connect(function()
	openTuhoGUI(true)
end)
startTuhoBtn.MouseButton1Click:Connect(function()
	addPlayer("EASY")
end)
startTuhoHardBtn.MouseButton1Click:Connect(function()
	addPlayer("HARD")
end)
RemoteQueue.OnClientEvent:Connect(updatePlayer)
QueueOut.MouseButton1Click:Connect(RemovePlayer)
scoreTimer.finished:Connect(removeScoreTextShow)
endTimer.finished:Connect(removeScoreEndShow)
ClientTriggerTuho.OnClientEvent:connect(queueUpdate)
--StartBtn.MouseButton1Click:Connect(function()
--	ClientTriggerTuho:FireServer(gamemode)
--	exit()
--end)
ScoreEvent.OnClientEvent:connect(updateScore)
