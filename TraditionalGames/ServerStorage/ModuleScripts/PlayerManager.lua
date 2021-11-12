local PlayerManager = {}

local PlayerService = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameSettings = require(ServerStorage.Configurations.GameSettings)
local remoteQueue = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteQueue")
local timerStartStop = ReplicatedStorage:WaitForChild("EventsTimer"):WaitForChild("TimerStartStop")

local BallPushAnim = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("BallPushAnim")
local ClientTriggerBall = ReplicatedStorage:WaitForChild("EventsBall"):WaitForChild("ClientTriggerBall")
local ClientTriggerTuho = ReplicatedStorage:WaitForChild("EventsTuho"):WaitForChild("ClientTriggerTuho")
local ClientTriggerRope = ReplicatedStorage:WaitForChild("EventsRope"):WaitForChild("ClientTriggerRope")
local RopeAction = ReplicatedStorage:WaitForChild("EventsRope"):WaitForChild("RopeAction")


--Teleport Locations
local TeleportLocations =  {
	Lobby = game.Workspace.SpawnLocation.CFrame.Position,
	Ball = {
		A = game.Workspace.BallGame.BallFloorStartA.CFrame.Position,
		B = game.Workspace.BallGame.BallFloorStartB.CFrame.Position
	},
	Tuho = {
		EASY = game.Workspace.TuhoGame.CeramicFloorStart.CFrame.Position,
		HARD = game.Workspace.TuhoGame.CeramicFloorStart.CFrame.Position
	},
	Rope = GameSettings.RopeCFrameOrigin
}

--Teleport LookVector - maybe can handle with config
local TeleportLook =  {
	Lobby = game.Workspace.SpawnLocation.Position,
	Ball = {
		A = game.Workspace.SpawnLocation.Position,
		B = game.Workspace.SpawnLocation.Position
	},
	Tuho = {
		EASY = game.Workspace.SpawnLocation.Position,
		HARD = game.Workspace.SpawnLocation.Position
	}
}

local Players = {
	Queue = {
		Ball = {
			A = {},
			B = {}
		},
		Tuho = {
			EASY = {},
			HARD = {}
		},
		Rope = {
			A = {},
			B = {}
		}
	},
	Playing = {
		Ball = {
			A = {},
			B = {}
		},
		Tuho = {
			EASY = {},
			HARD = {}
		},
		Rope = {
			A = {},
			B = {}
		}
	}
}

local PlayerDBFindList = {
	{"Ball","A"},
	{"Ball","B"},
	{"Tuho","EASY"},
	{"Tuho","HARD"},
	{"Rope","A"},
	{"Rope","B"}
}


--RopeSettings
local ROPE_DIRECTION = GameSettings.RopeDirection
local ROPE_PL_BETWEEN = GameSettings.RopePlayerBetween
local ROPE_LEFT_RIGHT = GameSettings.RopePlayerLeftRight
local ROPE_START_DIS = GameSettings.RopePlayerStartDistance

-----Handle Player Queue---------------------------------------------------------
function PlayerManager:getNumberOfPlayer(kinds,gameName,detail)
	if(detail == "ALL") then
		local num = 0
		for _, team in pairs(Players[kinds][gameName]) do
			num += #team
		end
		return num
	else
		return #Players[kinds][gameName][detail]
	end
end

function PlayerManager:getPlayers(kinds,gameName,detail)
	if(detail == "ALL") then
		return Players[kinds][gameName]
	else
		return Players[kinds][gameName][detail]
	end
end

local function findPlayerIndex(player,kinds,gameName,detail)
	return table.find(Players[kinds][gameName][detail], player)
end

local function findPlayerKinds(player, kinds)
	local index = nil
	for _, tb in ipairs(PlayerDBFindList) do
		index = table.find(Players[kinds][tb[1]][tb[2]], player)
		if index then
			return {kinds, tb[1], tb[2], index}
		end
	end
	return nil
end

function PlayerManager:updatePlaying(player,kinds)
	remoteQueue:FireClient(player,"UPDATE_Playing","ALL",Players[kinds])
end

function PlayerManager:updateAllPlayers(kinds,gameName,detail)
	local AllPlayers = PlayerService:GetPlayers()
	--print(Players)
	if kinds == "Playing" then
		if gameName == "ALL" then
			for _, player in pairs(AllPlayers) do
				remoteQueue:FireClient(player,"UPDATE_Playing",gameName,Players[kinds])
			end
			
		end
	end
	if kinds == "Queue" then
		if detail == "ALL" then
			for _, player in pairs(AllPlayers) do
				remoteQueue:FireClient(player,"UPDATE",gameName,Players[kinds][gameName])
			end
		else
			for _, player in pairs(AllPlayers) do
				remoteQueue:FireClient(player,"UPDATE",gameName,Players[kinds][gameName][detail])
			end
		end
	end
	
end

local function removePlayerByIndex(kinds,gameName,detail,index)
	table.remove(Players[kinds][gameName][detail], index)
	PlayerManager:updateAllPlayers(kinds,gameName,"ALL")
end

local function addPlayerByName(player,kinds,gameName,detail)
	table.insert(Players[kinds][gameName][detail], player)
	PlayerManager:updateAllPlayers(kinds,gameName,"ALL")
end

function PlayerManager:updatePlayerSingle(player,kinds,gameName,detail)
	if (detail == "ALL") then
		--for teamName, team in pairs(Players[kinds][gameName]) do
		--	remoteQueue:FireClient(player,"UPDATE",gameName,Players[kinds][gameName])
		--end
		remoteQueue:FireClient(player,"UPDATE",gameName,Players[kinds][gameName])
	else
		remoteQueue:FireClient(player,"UPDATE",gameName,Players[kinds][gameName])
	end
end

--function PlayerManager:updatePlayers(kinds,gameName,detail)
--	if (detail == "ALL") then
--		for teamName, team in pairs(Players[kinds][gameName]) do
--			for _, player in ipairs(team) do
--				PlayerManager:updatePlayerSingle(player,kinds,gameName,detail)
--			end
--		end
--	else
--		for index, player in pairs(Players[kinds][gameName][detail]) do
--			PlayerManager:updatePlayerSingle(player,kinds,gameName,detail)
--		end
--	end
--end



function PlayerManager:removePlayer(player,kinds,gameName,detail)
	if(detail == "ALL") then
		local findTable = findPlayerKinds(player, kinds)
		if findTable then
			removePlayerByIndex(findTable[1],findTable[2],findTable[3],findTable[4])
		else
			return
		end
	else
		local index = findPlayerIndex(player,kinds,gameName,detail)
		if index then
			removePlayerByIndex(kinds,gameName,detail,index)
		end	
	end
end

function PlayerManager:clearPlayers(kinds,gameName,detail)
	Players[kinds][gameName][detail] = {}
	PlayerManager:updateAllPlayers(kinds,gameName,detail)
end


function PlayerManager:addPlayerQueue(player,gameName,detail)
	local playingCheck = findPlayerKinds(player,"Playing")
	if not playingCheck then
		local findTable = findPlayerKinds(player,"Queue")
		if findTable then
			removePlayerByIndex(findTable[1],findTable[2],findTable[3],findTable[4])
		end
		addPlayerByName(player,"Queue",gameName,detail)
	else
		return
	end
end

--move Single Player Queue <-> Playing
function PlayerManager:setPlayerSingle(player,fromkinds,gameName,detail)
	local findTable = findPlayerKinds(player,fromkinds)
	if findTable and (findTable[2] == gameName) and (findTable[3] == detail) then
		if(fromkinds == "Queue") then
			addPlayerByName(player,"Playing",gameName,detail)
		end
		if(fromkinds == "Playing") then
			addPlayerByName(player,"Queue",gameName,detail)
		end
		removePlayerByIndex(findTable[1],findTable[2],findTable[3],findTable[4])
	else
		return
	end
end

--move Whole Players Queue <-> Playing
function PlayerManager:setPlayers(fromkinds,gameName,detail)
	if(fromkinds == "Queue") then
		Players["Playing"][gameName][detail] = Players["Queue"][gameName][detail]
	end
	if(fromkinds == "Playing") then
		Players["Queue"][gameName][detail] = Players["Playing"][gameName][detail]
	end
	PlayerManager:clearPlayers(fromkinds,gameName,detail)
	PlayerManager:updateAllPlayers("Queue",gameName,detail)
end



function PlayerManager:showPage()
	--for _, tb in ipairs(PlayerDBFindList) do
	--	for _, player in Players["Queue"][tb[1]][tb[2]] do
	--		if (tb[1] == "Ball") then
	--			ClientTriggerBall.FireClient(player,"OPEN_GUI")
	--		end
	--		if (tb[1] == "Tuho") then
	--			ClientTriggerTuho.FireClient(player,"OPEN_GUI")
	--		end
	--		if (tb[1] == "Rope") then
	--			ClientTriggerRope.FireClient(player,"OPEN_GUI")
	--		end
	--	end
	--end
	for teamName, team in pairs(Players["Queue"]["Tuho"]) do
		for index, player in ipairs(team) do
			ClientTriggerTuho:FireClient(player,"OPEN_GUI")
		end
	end
	for teamName, team in pairs(Players["Queue"]["Ball"]) do
		for index, player in ipairs(team) do
			ClientTriggerBall:FireClient(player,"OPEN_GUI")
		end
	end
end

function PlayerManager:exitPage()
	for teamName, team in pairs(Players["Queue"]["Tuho"]) do
		for index, player in ipairs(team) do
			ClientTriggerTuho:FireClient(player,"CLOSE_GUI")
		end
	end
	for teamName, team in pairs(Players["Queue"]["Ball"]) do
		for index, player in ipairs(team) do
			ClientTriggerBall:FireClient(player,"CLOSE_GUI")
		end
	end
end

--Change Tuho <-> Ball (Ball[A] <-> Tuho[EASY]/ Ball[B] <-> Tuho[HARD])
--before changing, change A/B and EASY/HARD due to user input - default = A(EASY)
function PlayerManager:changeTuhoBall()
	local temp = Players["Queue"]["Ball"]["A"]
	Players["Queue"]["Ball"]["A"] = Players["Queue"]["Tuho"]["EASY"]
	Players["Queue"]["Tuho"]["EASY"] = temp
	
	temp = Players["Queue"]["Ball"]["B"]
	Players["Queue"]["Ball"]["B"] = Players["Queue"]["Tuho"]["HARD"]
	Players["Queue"]["Tuho"]["HARD"] = temp
end

--move Ball & Tuho Queue -> Rope Queue
function PlayerManager:moveToRopeQueue()
	for teamName, team in pairs(Players["Queue"]["Tuho"]) do
		for index, player in ipairs(team) do
			addPlayerByName(player,"Queue","Rope","A")
		end
		Players["Queue"]["Tuho"][teamName] = {}
	end
	for teamName, team in pairs(Players["Queue"]["Ball"]) do
		for index, player in ipairs(team) do
			addPlayerByName(player,"Queue","Rope","B")
		end
		Players["Queue"]["Ball"][teamName] = {}
	end
end

---------------------------------------------------------------------------------

-----Send Timer------------------------------------------------------------
function PlayerManager:sendClientTimerSingle(command, player, duration, info)
	timerStartStop:FireClient(player, command, duration, info)
end

function PlayerManager:sendClientsTimer(command, kinds,gameName,detail,duration,info)
	if (detail == "ALL") then
		for teamName, team in pairs(Players[kinds][gameName]) do
			for _, player in ipairs(team) do
				PlayerManager:sendClientTimerSingle(command, player, duration, info)
			end
		end
	else
		for index, player in pairs(Players[kinds][gameName][detail]) do
			PlayerManager:sendClientTimerSingle(command, player, duration, info)
		end
	end
end
---------------------------------------------------------------------------------

-----Teleport Players------------------------------------------------------------
local apartVar = {
	{0,0},{0,1},{-1,0},{-1,-1},{0,-1},{1,-1},{1,0},{1,1},{1,2},{0,2},{-1,2},{-2,2},{-2,1},{-2,0},{-2,-1},{-2,-2},{-1,-2},{0,-2},{1,-2},{2,-2},{2,-1},{2,0},{2,1},{2,2}
}



local function teleportPlayerCFrame(player, target, pos, look)
	-- Make sure the character exists and its HumanoidRootPart exists
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		-- Add an offset of 5 for each character
		player.Character.HumanoidRootPart.CFrame = CFrame.lookAt(target + pos, look)
	end
end

local function getApart(num)
	if(num > 25) then
		num %= 25
	end
	return Vector3.new(apartVar[num][1], 5, apartVar[num][2])
end

local function teleportPlayersCFrame(players, target, look)
	for i, player in ipairs(players) do
		teleportPlayerCFrame(player, target, getApart(i), look)
	end
end

local function ropePlayerPosNext(player, pos, ropeD, ropeBet, ropeLR, detail)
	if (detail == "A") then
		if(ropeD == "Z") then
			if(pos.X < TeleportLocations["Rope"].X) then
				RopeAction:FireClient(player, "LEFT")
				return pos + Vector3.new(ropeLR,0,ropeBet)
			else
				RopeAction:FireClient(player, "RIGHT")
				return pos + Vector3.new(-ropeLR,0,ropeBet)
			end
		end
		if(ropeD == "X") then
			if(pos.Z < TeleportLocations["Rope"].Z) then
				RopeAction:FireClient(player, "RIGHT")
				return pos + Vector3.new(ropeBet,0,ropeLR)
			else
				RopeAction:FireClient(player, "LEFT")
				return pos + Vector3.new(ropeBet,0,-ropeLR)
			end
		end
	end
	if (detail == "B") then
		if(ropeD == "Z") then
			if(pos.X < TeleportLocations["Rope"].X) then
				RopeAction:FireClient(player, "RIGHT")
				return pos + Vector3.new(ropeLR,0,-ropeBet)
			else
				RopeAction:FireClient(player, "LEFT")
				return pos + Vector3.new(-ropeLR,0,-ropeBet)
			end
		end
		if(ropeD == "X") then
			if(pos.Z < TeleportLocations["Rope"].Z) then
				RopeAction:FireClient(player, "LEFT")
				return pos + Vector3.new(-ropeBet,0,ropeLR)
			else
				RopeAction:FireClient(player, "RIGHT")
				return pos + Vector3.new(-ropeBet,0,-ropeLR)
			end
		end
	end
end

function PlayerManager:movePlayersToRopeGame()
	if(ROPE_DIRECTION == "Z") then
		local playerPosA = CFrame.lookAt(TeleportLocations["Rope"].Position + Vector3.new(ROPE_LEFT_RIGHT/2, 0, ROPE_START_DIS), TeleportLocations["Rope"].Position + Vector3.new(0,0,-1000))
		local playerPosB = CFrame.lookAt(TeleportLocations["Rope"].Position + Vector3.new(-ROPE_LEFT_RIGHT/2, 0, -ROPE_START_DIS), TeleportLocations["Rope"].Position + Vector3.new(0,0,1000))


		for i, player in ipairs(Players["Queue"]["Rope"]["A"]) do
			playerPosA = ropePlayerPosNext(player, playerPosA, ROPE_DIRECTION, ROPE_PL_BETWEEN, ROPE_LEFT_RIGHT, "A")
			player.Character.Humanoid.WalkSpeed = 0
			player.Character.HumanoidRootPart.CFrame = playerPosA + Vector3.new(0,3,0)
			--player stop move and set team
			RopeAction:FireClient(player, "STOP_MOVE","A")
		end
		for i, player in ipairs(Players["Queue"]["Rope"]["B"]) do
			playerPosB = ropePlayerPosNext(player, playerPosB, ROPE_DIRECTION, ROPE_PL_BETWEEN, ROPE_LEFT_RIGHT, "B")
			player.Character.Humanoid.WalkSpeed = 0
			player.Character.HumanoidRootPart.CFrame = playerPosB + Vector3.new(0,3,0)
			RopeAction:FireClient(player, "STOP_MOVE","B")
		end
	end
	if(ROPE_DIRECTION == "X") then
		local playerPosA = CFrame.lookAt(TeleportLocations["Rope"].Position + Vector3.new(ROPE_START_DIS, 0, -ROPE_LEFT_RIGHT/2), TeleportLocations["Rope"].Position + Vector3.new(-1000,0,0))
		local playerPosB = CFrame.lookAt(TeleportLocations["Rope"].Position + Vector3.new(-ROPE_START_DIS, 0, ROPE_LEFT_RIGHT/2), TeleportLocations["Rope"].Position + Vector3.new(1000,0,0))

		for i, player in ipairs(Players["Queue"]["Rope"]["A"]) do
			playerPosA = ropePlayerPosNext(player, playerPosA, ROPE_DIRECTION, ROPE_PL_BETWEEN, ROPE_LEFT_RIGHT, "A")
			player.Character.Humanoid.WalkSpeed = 0
			player.Character.HumanoidRootPart.CFrame = playerPosA + Vector3.new(0,3,0)
			RopeAction:FireClient(player, "STOP_MOVE","A")
		end
		for i, player in ipairs(Players["Queue"]["Rope"]["B"]) do
			playerPosB = ropePlayerPosNext(player, playerPosB, ROPE_DIRECTION, ROPE_PL_BETWEEN, ROPE_LEFT_RIGHT, "B")
			player.Character.Humanoid.WalkSpeed = 0
			player.Character.HumanoidRootPart.CFrame = playerPosB + Vector3.new(0,3,0)
			RopeAction:FireClient(player, "STOP_MOVE","B")
		end
	end
end

--handle TuhoSingle with teleportPlayerCFrame
function PlayerManager:teleportPlayers(fromKinds, fromGameName, destination, detail)
	if(destination == "Lobby") then
		if(detail == "ALL") then
			for teamName, team in pairs(Players[fromKinds][fromGameName]) do
				teleportPlayersCFrame(Players[fromKinds][fromGameName][teamName], TeleportLocations[destination], TeleportLook[destination])
			end
		else
			teleportPlayersCFrame(Players[fromKinds][fromGameName][detail], TeleportLocations[destination], TeleportLook[destination])
		end
	else
		if(destination == "Rope") then
			PlayerManager:movePlayersToRopeGame()
		else
			if(detail == "ALL") then
				for teamName, team in pairs(Players[fromKinds][fromGameName]) do
					teleportPlayersCFrame(Players[fromKinds][fromGameName][teamName], TeleportLocations[destination][teamName], TeleportLook[destination][teamName])
				end
			else
				teleportPlayersCFrame(Players[fromKinds][fromGameName][detail], TeleportLocations[destination][detail], TeleportLook[destination][detail])
			end
		end
	end
end


---------------------------------------------------------------------------------

-----Handle Players--------------------------------------------------------------

function PlayerManager:moveAndUpdateGame(fromKinds, fromGameName, destination, detail)
	if(detail == "ALL") then
		for teamName, team in pairs(Players[fromKinds][fromGameName]) do
			PlayerManager:teleportPlayers(fromKinds, fromGameName, destination, teamName)
			if(destination == "Lobby") then
				PlayerManager:clearPlayers(fromKinds,fromGameName,teamName)
			else
				PlayerManager:setPlayers(fromKinds,fromGameName,teamName)
			end
		end
	else
		PlayerManager:teleportPlayers(fromKinds, fromGameName, destination, detail)
		if(destination == "Lobby") then
			PlayerManager:clearPlayers(fromKinds,fromGameName,detail)
		else
			PlayerManager:setPlayers(fromKinds,fromGameName,detail)
		end
	end
end

function PlayerManager:moveAndUpdateSingle(player, fromKinds, fromGameName, destination, detail)
	if(destination == "Lobby") then
		teleportPlayerCFrame(player, TeleportLocations[destination], getApart(1), TeleportLook[destination])
		PlayerManager:removePlayer(player,fromKinds,fromGameName,detail)
	else
		teleportPlayerCFrame(player, TeleportLocations[destination][detail], getApart(1), TeleportLook[destination][detail])
		PlayerManager:setPlayerSingle(player,fromKinds,fromGameName,detail)
	end
end

function PlayerManager:setAnimation(command, gameName, detail)
	if(gameName == "Ball") then
		if(detail == "ALL") then
			for teamName, team in pairs(Players["Playing"]["Ball"]) do
				for _, player in pairs(team) do
					BallPushAnim:FireClient(player, command, GameSettings.BallPushDistance, GameSettings.BallSpeedMax, teamName)
				end
			end
		else
			for i, player in ipairs(Players["Playing"]["Ball"][detail]) do
				BallPushAnim:FireClient(player, command, GameSettings.BallPushDistance, GameSettings.BallSpeedMax, detail)
			end
		end
	end
end

function PlayerManager:sendResult(gameName,result, detail, info)
	if(gameName == "Ball") then
		for i, player in ipairs(Players["Playing"]["Ball"][detail]) do
			ClientTriggerBall:FireClient(player, result, 3)
		end
	end
	if(gameName == "Rope") then
		for i, player in ipairs(Players["Playing"]["Rope"][detail]) do
			ClientTriggerRope:FireClient(player, result, 3)
		end
	end
end


return PlayerManager
