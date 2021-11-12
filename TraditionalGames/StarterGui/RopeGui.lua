local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventsRope = ReplicatedStorage:WaitForChild("EventsRope")

local RemoteQueue = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteQueue")
local ClientTriggerRope = EventsRope:WaitForChild("ClientTriggerRope")
local RopeEnergyEvent = EventsRope:WaitForChild("RopeEnergyEvent")
local RopeAction = EventsRope:WaitForChild("RopeAction")


local starterGUI = script.Parent
local ropeGamePlatform = game.Workspace.Lobby:WaitForChild("RopeGame")
local proximityPlay = ropeGamePlatform:WaitForChild("ProximityPrompt")
local RopeGameScreen = starterGUI:WaitForChild("RopeGameScreen")
local RopeQueueGUI = RopeGameScreen:WaitForChild("RopeQueueGui")
local GameResultGUI = RopeGameScreen:WaitForChild("GameResult")
local RopeEnergyGauge = RopeGameScreen:WaitForChild("RopeEnergyGauge")

-- Buttons
local exitBtn = RopeQueueGUI:WaitForChild("ExitBtn")
local SetTeamA = RopeQueueGUI:WaitForChild("SetTeamA")
local SetTeamB = RopeQueueGUI:WaitForChild("SetTeamB")
local StartRope = RopeQueueGUI:WaitForChild("StartRope")
local APlayers = RopeQueueGUI:WaitForChild("APlayersFrame"):WaitForChild("APlayers")
local BPlayers = RopeQueueGUI:WaitForChild("BPlayersFrame"):WaitForChild("BPlayers")
local RemoveQueue = RopeQueueGUI:WaitForChild("RemoveQueue")
local ResultText = GameResultGUI:WaitForChild("ResultText")

local EnergyLeft = RopeEnergyGauge:WaitForChild("EnergyLeft")
local EnergyBar = RopeEnergyGauge:WaitForChild("EnergyBar")

local Energy = 50
local EnergyConnection = nil
local count = 0
local needToFire= false


local Timer = require(ReplicatedStorage.ModuleScripts.Timer)
local resultTimer = Timer.new()

local function exit()
	RopeQueueGUI.Visible = false
end

local function openRopeGUI(exit)
	RemoteQueue:FireServer("GET","Queue","Rope","ALL")
	RopeQueueGUI.Visible = true
	exitBtn.Visible = exit
end

local function triggerRope()
	ClientTriggerRope:FireServer()
	exit()
end

local function setTeam(team)
	RemoteQueue:FireServer("ADD","Queue","Rope",team)
end

local function RemovePlayer()
	RemoteQueue:FireServer("REMOVE","Queue","Rope","ALL")
end

local function updatePlayerShow(info)
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



local function openEnergy()
	RopeEnergyGauge.Visible= true
end
local function closeEnergy()
	RopeEnergyGauge.Visible= false
	Energy = 50
	if(EnergyConnection) then
		EnergyConnection:Disconnect()
		EnergyConnection = nil
	end
	count = 0
	needToFire= false
end


local function gainEnergy(time)
	if(Energy < 50) then
		count += 1
		if(count == 3) then
			Energy += 0.25
			if(EnergyBar.Position.Y.Scale - 0.005 < 0 or EnergyBar.Size.Y.Offset + 1 > 200) then
				EnergyBar:TweenSizeAndPosition(
					UDim2.new(0, EnergyBar.Size.X.Offset, 0, 200),
					UDim2.new(EnergyBar.Position.X.Scale , 0, 0, 0),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Linear,
					time,
					false,
					function()
						EnergyLeft.Text = math.floor(Energy)
					end
				)
			else
				EnergyBar:TweenSizeAndPosition(
					UDim2.new(0, EnergyBar.Size.X.Offset, 0, EnergyBar.Size.Y.Offset + 1),
					UDim2.new(EnergyBar.Position.X.Scale , 0, EnergyBar.Position.Y.Scale - 0.005, 0),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Linear,
					time,
					false,
					function()
						EnergyLeft.Text = math.floor(Energy)
					end
				)
			end
			count = 0
		end
	end
	if(needToFire and Energy > 2) then
		RopeEnergyEvent:Fire("ABLE")
		needToFire = false
	end
end

local function handleEnergy(command)
	if(command == "PULL") then
		if(Energy > 0) then
			Energy -= 1
			EnergyBar:TweenSizeAndPosition(
				UDim2.new(0, EnergyBar.Size.X.Offset, 0, EnergyBar.Size.Y.Offset - 8),
				UDim2.new(EnergyBar.Position.X.Scale , 0, EnergyBar.Position.Y.Scale + 0.04, 0),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Linear,
				0.2,
				false,
				function()
					EnergyLeft.Text = math.floor(Energy)
				end
			)
			Energy -= 1
			EnergyBar:TweenSizeAndPosition(
				UDim2.new(0, EnergyBar.Size.X.Offset, 0, EnergyBar.Size.Y.Offset - 8),
				UDim2.new(EnergyBar.Position.X.Scale , 0, EnergyBar.Position.Y.Scale + 0.04, 0),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Linear,
				0.2,
				false,
				function()
					EnergyLeft.Text = math.floor(Energy)
				end
			)
			print(EnergyBar.Size.Y.Offset)
		end
		if(Energy < 2) then
			RopeEnergyEvent:Fire("UNABLE")
			needToFire = true
		end
	end
	if(command == "RELEASE_START") then
		if(not EnergyConnection) then
			EnergyConnection = game:GetService("RunService").Heartbeat:Connect(gainEnergy)
		end
	end
	if(command == "RELEASE_END") then
		if(EnergyConnection) then
			EnergyConnection:Disconnect()
			EnergyConnection = nil
		end
	end
end

local function handleRopeAction(command)
	if(command == "ACTIVATE") then
		openEnergy()
	end
	if(command == "DEACTIVATE") then
		closeEnergy()
	end
end

local function updatePlayer(command,gameName,info)
	if command == "UPDATE" and gameName == "Rope" then
		updatePlayerShow(info)
	end
end

local function showResult(text, color)
	ResultText.Text = text
	ResultText.TextColor3 = color
	GameResultGUI.Visible = true

end

local function displayResult(result, duration)
	if(result == "OPEN_GUI") then
		openRopeGUI(false)
		return
	end
	if(result == "CLOSE_GUI") then
		exit()
		return
	end
	if(result == "WIN") then
		showResult("Win!!", Color3.new(0,255,0))
	end
	if(result == "DEFEAT") then
		showResult("Defeated...", Color3.new(255,0,0))
	end
	if(result == "SERVER") then
		showResult("Game Ended By Server", Color3.new(255,0,0))
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
	openRopeGUI(true)
end)
SetTeamA.MouseButton1Click:Connect(function()
	setTeam("A")
end)
SetTeamB.MouseButton1Click:Connect(function()
	setTeam("B")
end)
StartRope.MouseButton1Click:Connect(triggerRope)
RemoveQueue.MouseButton1Click:Connect(RemovePlayer)

RopeEnergyEvent.Event:Connect(handleEnergy)
RopeAction.onClientEvent:Connect(handleRopeAction)
RemoteQueue.OnClientEvent:Connect(updatePlayer)
ClientTriggerRope.OnClientEvent:Connect(displayResult)
resultTimer.finished:Connect(removeResult)