
local UIS = game:GetService("UserInputService")
local character = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RopeData = ReplicatedStorage:WaitForChild("EventsRope"):WaitForChild("RopeData")
local ropeSettings = require(script:WaitForChild("ropeSettings"))
local RopeEnergyEvent = ReplicatedStorage:WaitForChild("EventsRope"):WaitForChild("RopeEnergyEvent")
local RopeAction = ReplicatedStorage:WaitForChild("EventsRope"):WaitForChild("RopeAction")


local pullKey = ropeSettings.pullKey
local releaseKey = ropeSettings.releaseKey
local brokenTime = ropeSettings.brokenTime

local Timer = require(ReplicatedStorage.ModuleScripts.Timer)
local pullStartTimer = Timer.new()
local pullEndTimer = Timer.new()
local brokenTimer = Timer.new()

local isActive = script.IsActive



local endureAnimation = nil
local pullAnimation = nil
local releaseAnimation = nil
local brokenAnimation = nil

local endureAnim = nil
local pullAnim = nil
local releaseAnim = nil
local brokenAnim = nil


local team = nil

local broken = false
local inputable = true

local inputBeganConnection = nil
local inputEndConnection = nil
local pullEndConnection = nil

local energyEnough = true


local function keyInput(input, gameprocessed)
	
	if gameprocessed then return end
	if (not broken) then
		if inputable then
			if (input.KeyCode == pullKey and energyEnough) then
				endureAnim:Stop()
				pullAnim:Play()
				inputable = false
				RopeData:FireServer("pull", team)
				RopeEnergyEvent:Fire("PULL")
				--print("fire 1")
				pullStartTimer:start(0.4)
			end
		
			if input.KeyCode == releaseKey  then
				endureAnim:Stop()
				releaseAnim:Play()
				inputable = false
				RopeData:FireServer("release", team)
				RopeEnergyEvent:Fire("RELEASE_START")
				--print("fire -1")
			end
		end
	else
		if input.KeyCode == pullKey  then
			brokenTimer:reduceDuration(0.1)
		end
	end
	
	
	return
end

local function pullNext()
	RopeData:FireServer("endure", team)
	--print("fire 0")
	pullEndTimer:start(0.3)
end

local function pullEnd()
	inputable = true
end

local function listenServer(stat)
	if (stat == "broken") then
		broken = true
		inputable = false
		if(endureAnim.IsPlaying) then
			endureAnim:Stop()
		end
		if(releaseAnim.IsPlaying) then
			releaseAnim:Stop()
		end
		if(pullAnim.IsPlaying) then
			pullAnim:Stop()
		end
		brokenAnim:Play()
		brokenTimer:start(brokenTime)
		RopeEnergyEvent:Fire("RELEASE_START")
	end
end

local function brokenEnd()
	broken = false
	inputable = true
	if(brokenAnim.IsPlaying) then
		brokenAnim:Stop()
	end
	if(not endureAnim.IsPlaying) then
		endureAnim:Play()
	end
	RopeData:FireServer("endure", team)
	RopeEnergyEvent:Fire("RELEASE_END")
	--print("fire 0")
end


local function keyEnd(input, gameprocessed)
	if gameprocessed then return end
	if(input.KeyCode == releaseKey and releaseAnim.IsPlaying) then
		releaseAnim:Stop()
		if(not endureAnim.IsPlaying) then
			endureAnim:Play()
			RopeData:FireServer("endure", team)
			RopeEnergyEvent:Fire("RELEASE_END")
			--print("fire 0")
		end
		inputable= true
	end
end


local function setLR(LR)
	character.Humanoid.WalkSpeed = 0
	endureAnimation = Instance.new("Animation")
	pullAnimation = Instance.new("Animation")
	releaseAnimation = Instance.new("Animation")
	brokenAnimation = Instance.new("Animation")
	if(LR == "LEFT") then
		endureAnimation.AnimationId = "rbxassetid://7846584726"
		pullAnimation.AnimationId = "rbxassetid://7846668355"
		releaseAnimation.AnimationId = "rbxassetid://7846736939"
		brokenAnimation.AnimationId = "rbxassetid://7846758622"
	end
	if(LR == "RIGHT") then
		endureAnimation.AnimationId = "rbxassetid://7846543146"
		pullAnimation.AnimationId = "rbxassetid://7846671436"
		releaseAnimation.AnimationId = "rbxassetid://7846694006"
		brokenAnimation.AnimationId = "rbxassetid://7846756615"
	end
end

local function setAnim(teamV)
	if(not isActive.Value) then
		isActive.Value = true
		team = teamV

		--stop move
		character.Humanoid.WalkSpeed = 0
		endureAnim = character.Humanoid:LoadAnimation(endureAnimation)
		endureAnim.Looped = true
		pullAnim = character.Humanoid:LoadAnimation(pullAnimation)
		pullAnim.Looped = false
		releaseAnim = character.Humanoid:LoadAnimation(releaseAnimation)
		releaseAnim.Looped = true
		brokenAnim = character.Humanoid:LoadAnimation(brokenAnimation)
		brokenAnim.Looped = true
		pullEndConnection = pullAnim.Stopped:Connect(function()
			if((not endureAnim.IsPlaying) and not broken) then
				endureAnim:Play()
			end
		end)
		
		endureAnim:Play()
	end
	
	--wait(2)
	--listenServer("Broken")
	--wait(4)
	--listenServer("Broken")
end

local function ropePullStart()
	inputBeganConnection = UIS.InputBegan:Connect(keyInput)
	inputEndConnection = UIS.InputEnded:Connect(keyEnd)
end

local function clearAnimation()
	if(endureAnim.IsPlaying) then
		endureAnim:Stop()
	end
	if(releaseAnim.IsPlaying) then
		releaseAnim:Stop()
	end
	if(pullAnim.IsPlaying) then
		pullAnim:Stop()
	end
	if(brokenAnim.IsPlaying) then
		brokenAnim:Stop()
	end
	endureAnimation = nil
	pullAnimation = nil
	releaseAnimation = nil
	brokenAnimation = nil
end

local function endConnection()
	if(inputBeganConnection) then
		inputBeganConnection:Disconnect()
		inputBeganConnection = nil
	end
	if(inputEndConnection) then
		inputEndConnection:Disconnect()
		inputEndConnection = nil
	end
	if(pullEndConnection) then
		pullEndConnection:Disconnect()
		pullEndConnection = nil
	end
end

local function ropePullStop()
	if(isActive.Value) then
		isActive.Value = false
		character.Humanoid.WalkSpeed = 16
		endConnection()
		clearAnimation()
		energyEnough = true
		team = nil
		broken = false
		inputable = true
	end
	
end


local function handleEnergy(stat)
	if(stat == "ABLE") then
		energyEnough = true
	end
	if(stat == "UNABLE") then
		energyEnough = false
	end
end

local function handleRopeAction(command,info)
	if(command == "LEFT") then
		setLR("LEFT")
	end
	if(command == "RIGHT") then
		setLR("RIGHT")
	end
	if(command == "STOP_MOVE") then
		setAnim(info)
	end
	if(command == "ACTIVATE") then
		ropePullStart()
	end
	if(command == "DEACTIVATE") then
		ropePullStop()
	end
end


pullStartTimer.finished:Connect(pullNext)
pullEndTimer.finished:Connect(pullEnd)
brokenTimer.finished:Connect(brokenEnd)
RopeAction.onClientEvent:Connect(handleRopeAction)
RopeData.OnClientEvent:Connect(listenServer)

RopeEnergyEvent.Event:Connect(handleEnergy)



--endureleft : 7846543146
--endureright : 7846584726
--pullleft : 7846671436
--pullright : 7846668355
--releaseleft :7846694006
--releaseright : 7846736939
--brokenleft :7846756615
--brokenright : 7846758622