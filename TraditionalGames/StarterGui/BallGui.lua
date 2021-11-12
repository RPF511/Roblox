-- ProximityPrompts
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteQueue = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteQueue")
local EventsBall = ReplicatedStorage:WaitForChild("EventsBall")
local ClientTriggerBall = EventsBall:WaitForChild("ClientTriggerBall")

local starterGUI = script.Parent
local ballPushPlatform = game.Workspace.Lobby:WaitForChild("Ballgame")
local proximityPlay = ballPushPlatform:WaitForChild("ProximityPrompt")
local BallGameScreen = starterGUI:WaitForChild("BallGameScreen")
local BallGUI = BallGameScreen:WaitForChild("BallGui")
local GameResultGUI = BallGameScreen:WaitForChild("GameResult")



-- Buttons
local exitBtn = BallGUI:WaitForChild("ExitBtn")
local startBallBtn = BallGUI:WaitForChild("EnableBallPush")
local stopBallBtn = BallGUI:WaitForChild("DisableBallPush")
local AddQueueA = BallGUI:WaitForChild("AddQueueA")
local AddQueueB = BallGUI:WaitForChild("AddQueueB")
local RemoveQueueBtn = BallGUI:WaitForChild("RemoveQueue")
local PlayersA = BallGUI:WaitForChild("PlayersAFrame"):WaitForChild("PlayersA")
local PlayersB = BallGUI:WaitForChild("PlayersBFrame"):WaitForChild("PlayersB")
local ResultText = GameResultGUI:WaitForChild("ResultText")

local Timer = require(ReplicatedStorage.ModuleScripts.Timer)
local resultTimer = Timer.new()

local function exit()
	BallGUI.Visible = false
end

local function openBallGUI(exit)
	RemoteQueue:FireServer("GET","Queue","Ball","ALL")
	BallGUI.Visible = true
	exitBtn.Visible = exit
end

local function triggerBall()
	ClientTriggerBall:FireServer()
	exit()
end



local function addPlayer(detail)
	RemoteQueue:FireServer("ADD","Queue","Ball",detail)
end

local function RemovePlayer()
	RemoteQueue:FireServer("REMOVE","Queue","Ball","ALL")
end

local function updatePlayerShow(info)
	local text = ""
	if info["A"] then
		for _, player in ipairs(info["A"]) do
			text = text .. player.Name .. "\n"
		end
	end
	PlayersA.Text = text
	text = ""
	if info["B"] then
		for _, player in ipairs(info["B"]) do
			text = text .. player.Name .. "\n"
		end
	end
	PlayersB.Text = text
end

local function updatePlayer(command,gameName,info)
	if command == "UPDATE" and gameName == "Ball" then
		updatePlayerShow(info)
	end
end

local function showResult(text, color)
	ResultText.Text = text
	ResultText.TextColor3 = color
	GameResultGUI.Visible = true
	
end

local function displayResult(result, duration, score)
	if(result == "OPEN_GUI") then
		openBallGUI(false)
		return
	end
	if(result == "CLOSE_GUI") then
		exit()
		return
	end
	if(result == "SUCCESS") then
		showResult("Success!!", Color3.new(0,255,0))
	end
	if(result == "FAIL") then
		showResult("Failed", Color3.new(255,0,0))
	end
	if(resultTimer:isRunning()) then
		resultTimer:stop()
	end
	resultTimer:start(3)
end

local function removeResult()
	if(resultTimer:isRunning()) then
		resultTimer:stop()
	end
	GameResultGUI.Visible = false
end

exitBtn.MouseButton1Click:Connect(exit)
proximityPlay.Triggered:Connect(function()
	openBallGUI(true)
end)
startBallBtn.MouseButton1Click:Connect(triggerBall)
AddQueueA.MouseButton1Click:Connect(function()
	addPlayer("A")
end)
AddQueueB.MouseButton1Click:Connect(function()
	addPlayer("B")
end)
RemoveQueueBtn.MouseButton1Click:Connect(RemovePlayer)
RemoteQueue.OnClientEvent:Connect(updatePlayer)
ClientTriggerBall.OnClientEvent:Connect(displayResult)
resultTimer.finished:Connect(removeResult)