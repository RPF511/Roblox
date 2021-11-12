local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")

local ToolEquipped = Tool:WaitForChild("Configuration"):WaitForChild("Equipped")
local Heartbeat = game:GetService("RunService").Heartbeat
--print("ToolEquipped ",ToolEquipped.Value)

local client = Tool:WaitForChild("Client")
local Remote = Tool:WaitForChild("Remote")

local Player = Tool.Parent.Parent
local Character = Player.Character
if not Character or not Character.Parent then
	Character = Player.CharacterAdded:wait()
end
local hrp = Character:WaitForChild("HumanoidRootPart")

local humanoid = Character:WaitForChild("Humanoid")
local vel = Tool:WaitForChild("Configuration"):WaitForChild("ThrowVelocity")

local hitbox = {
	A = {
		game.Workspace.TuhoGame.CeramicJar1.CeramicJarHitbox,
		game.Workspace.TuhoGame.CeramicJar2.CeramicJarHitbox
	},
	B = {
		game.Workspace.TuhoGame.CeramicJar3.CeramicJarHitbox,
		game.Workspace.TuhoGame.CeramicJar4.CeramicJarHitbox
	}
}

local ServerStorage = game:GetService("ServerStorage")
local Events = ServerStorage:WaitForChild("Events")
local TuhoHIT = Events:WaitForChild("TuhoHIT")



local darts = {}


function contains(t, v)
	for _, val in pairs(t) do
		if val == v then
			return true
		end
	end
	return false
end

function getPlayer()
	local char = Tool.Parent
	return game:GetService("Players"):GetPlayerFromCharacter(char)
end

--function equippedLoop()
--	--while ToolEquipped.Value do

--	--end
--end

function getDart(spindata)
	local g = Vector3.new(0, -game.Workspace.Gravity, 0);
	local dart = Handle:clone()
	dart.Transparency = 0
	dart.Hit.Pitch = math.random(90, 110)/100

	--local lift = Instance.new("BodyForce")
	--lift.force = Vector3.new(0, 196.2, 0) * knife:GetMass() * 0.8
	--lift.Parent = knife

	local proj = Tool.Projectile:Clone()
	
	
	proj.Disabled = false
	proj.Parent = dart
	dart.Projectile.Spin.Value = spindata
	
	return dart
end

function onLeftUp(unitV0, spindata)
	local v0 = unitV0 * vel.Value
	local x0 = CFrame.new(Handle.Position, unitV0)

	--print(humanoid.CameraOffset)
	--print(Handle.Position)

	--print("v0 ", v0)
	--print("gravity ", game.Workspace.Gravity)

	--local dart = Handle:Clone()
	--dart.Velocity = v0
	--dart.CFrame = CFrame.new(x0);
	--dart.CanCollide = true;
	--dart.Parent = game.Workspace;


	local dart = getDart(spindata)
	
	dart.CFrame = x0
	dart.Velocity = v0
	
	local touched
	touched = dart.Touched:connect(function(part)
		if part:IsDescendantOf(Tool.Parent) then return end
		if contains(darts, part) then return end
		--print(part)
		print("spin ",spindata , " dartlook ", dart.CFrame.LookVector)
		for index, mul in pairs(hitbox) do
			for _, hit in pairs(mul) do
				if part.Parent and part == hit then
					if(dart.CFrame.LookVector.Y < -0.8) then
						if index == "A" then
							if(spindata > 1) then
								TuhoHIT:Fire(Player, 3)
							else
								TuhoHIT:Fire(Player, 2)
							end
						end
						if index == "B" then
							if(spindata > 1) then
								TuhoHIT:Fire(Player, 5)
							else
								TuhoHIT:Fire(Player, 3)
							end
						end
					end
					
				end
			end
		end


		dart.Projectile:Destroy()

		local w = Instance.new("Weld")
		w.Part0 = part
		w.Part1 = dart
		w.C0 = part.CFrame:toObjectSpace(dart.CFrame)
		w.Parent = w.Part0

		touched:disconnect()
	end)
	table.insert(darts, dart)


	dart.Parent = workspace

	game:GetService("Debris"):AddItem(dart, 3)
	delay(2, function()
		dart.Transparency = 1
	end)

	Remote:FireClient(getPlayer(), "PlayAnimation", "Throw")	

	Handle.Throw.Pitch = 0.8
	--Handle.Throw:Play()
end


function onRemote(player, func, ...)
	if player ~= getPlayer() then return end

	if func == "LeftDown" then
		--onLeftDown(...)
		--print("server left down")
	end
	if func == "LeftUp" then
		onLeftUp(...)
		--print("server left up")
	end
end


function onEquip()
	ToolEquipped.Value = true
	--equippedLoop()
	--print(Tool:WaitForChild("Configuration"):WaitForChild("Equipped").Value)
end

function onUnequip()
	ToolEquipped.Value = false
	--print(Tool:WaitForChild("Configuration"):WaitForChild("Equipped").Value)
end

Remote.OnServerEvent:connect(onRemote)
Tool.Equipped:connect(onEquip)
Tool.Unequipped:connect(onUnequip)