-- ProximityPrompts
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventsBall = ReplicatedStorage:WaitForChild("EventsBall")

local ClientTriggerBallGame = EventsBall:WaitForChild("ClientTriggerBallGame")
local ClientTriggerBallGameStop = EventsBall:WaitForChild("ClientTriggerBallGameStop")
local RemoteAddPlayer = EventsBall:WaitForChild("RemoteAddPlayer")

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
local AddQueue = BallGUI:WaitForChild("AddQueue")
local RemoveQueue = BallGUI:WaitForChild("RemoveQueue")
local Players = BallGUI:WaitForChild("Players")
local ResultText = GameResultGUI:WaitForChild("ResultText")

local Timer = require(ReplicatedStorage.ModuleScripts.Timer)
local timer = Timer.new()

local function exit()
	BallGUI.Visible = false
end

local function openBallGUI()
	BallGUI.Visible = true
	RemoteAddPlayer:FireServer("GET")
end

local function triggerBall()
	ClientTriggerBallGame:FireServer()
	exit()
end

local function triggerBallStop()
	ClientTriggerBallGameStop:FireServer()
	exit()
end

local function addPlayer()
	RemoteAddPlayer:FireServer("ADD")
end

local function RemovePlayer()
	RemoteAddPlayer:FireServer("REMOVE")
end

local function updatePlayerShow(info)
	local text = ""
	for _, player in ipairs(info) do
		text = text .. player.Name .. "\n"
	end
	Players.Text = text
end

local function updatePlayer(command,info)
	if command == "UPDATE_PLAYER" then
		updatePlayerShow(info)
	end
end

local function showResult(text, color)
	ResultText.Text = text
	ResultText.TextColor3 = color
	GameResultGUI.Visible = true
	
end

local function displayResult(result, duration, info)
	if(result == "SUCCESS") then
		showResult("Success!!", Color3.new(0,255,0))
	end
	if(result == "FAIL") then
		showResult("Failed", Color3.new(255,0,0))
	end
	timer:start(duration)
end

local function removeResult()
	if(timer:isRunning()) then
		timer:stop()
	end
	GameResultGUI.Visible = false
end

exitBtn.MouseButton1Click:Connect(exit)
proximityPlay.Triggered:Connect(openBallGUI)
startBallBtn.MouseButton1Click:Connect(triggerBall)
stopBallBtn.MouseButton1Click:Connect(triggerBallStop)
AddQueue.MouseButton1Click:Connect(addPlayer)
RemoveQueue.MouseButton1Click:Connect(RemovePlayer)
RemoteAddPlayer.OnClientEvent:Connect(updatePlayer)
ClientTriggerBallGameStop.OnClientEvent:Connect(displayResult)
timer.finished:Connect(removeResult)