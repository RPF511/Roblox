local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

local timerStartStop = Events:WaitForChild("TimerStartStop")

local starterGUI = script.Parent
local TimerScreen = starterGUI:WaitForChild("TimerScreen")
local timerGUI = TimerScreen:WaitForChild("TimerGui")

local TextInfo = timerGUI:WaitForChild("TextInfo")
local Minute = timerGUI:WaitForChild("Minute")
local Second = timerGUI:WaitForChild("Second")

local Timer = require(ReplicatedStorage.ModuleScripts.Timer)
local timer = Timer.new()
local timerConnection = nil
local callback = nil


local function updateTime(time)
	Minute.Text = math.floor(time / 60)
	Second.Text = math.floor(time) % 60
	--print(type(time),typeof(time))
end

local function startTimer(duration, info)
	TextInfo.Text = info
	timerGUI.Visible = true
	timer:start(duration)
	timerConnection = game:GetService("RunService").Heartbeat:Connect(function()
		updateTime(timer:getTimeLeft())
	end)
end

local function resetTimer()
	Minute.Text = 00
	Second.Text = 00
	timerGUI.Visible = false
	if(timer:isRunning()) then
		timer:stop()
	end
	if(timerConnection) then
		timerConnection:Disconnect()
		timerConnection = nil
	end
	callback = nil
end

local function stopTimer()
	if(callback == "TUHO_SINGLE_PREPARE") then
		timerStartStop:FireServer(callback)
	end
	if(callback == "TUHO_SINGLE_START") then
		timerStartStop:FireServer(callback)
	end
	if(callback == "TUHO_SINGLE_STARTED") then
		timerStartStop:FireServer("SINGLE_END")
	end
	if(callback == "TUHO_SINGLE_END") then
		timerStartStop:FireServer("TUHO_SINGLE_END")
	end
	resetTimer()
end

local function timerShow(command, duration, info)
	if(command == "START") then
		if(timer:isRunning()) then
			stopTimer()
		end
		startTimer(duration, info)
	end
	if(command == "STOP") then
		stopTimer()
	end
	if(command == "TUHO_SINGLE_PREPARE") then
		callback = "TUHO_SINGLE_PREPARE"
		if(timer:isRunning()) then
			stopTimer()
		end
		startTimer(duration, info)
	end
	if(command == "TUHO_SINGLE_START") then
		callback = "TUHO_SINGLE_START"
		if(timer:isRunning()) then
			stopTimer()
		end
		startTimer(duration, info)
	end
	if(command == "TUHO_SINGLE_STARTED") then
		callback = "TUHO_SINGLE_STARTED"
		if(timer:isRunning()) then
			stopTimer()
		end
		startTimer(duration, info)
	end
	if(command == "TUHO_SINGLE_END") then
		callback = "TUHO_SINGLE_END"
		if(timer:isRunning()) then
			stopTimer()
		end
		startTimer(duration, info)
	end
end




timerStartStop.OnClientEvent:connect(timerShow)
timer.finished:Connect(stopTimer)