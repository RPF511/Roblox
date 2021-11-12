
local UIS = game:GetService("UserInputService")
local character = script.Parent
local keysPressed = UIS:GetKeysPressed()
local lctrl = Enum.KeyCode.LeftControl
local spacebar = Enum.KeyCode.Space
local canslide = true
local slideEnoughSpeed = false

local slideAnimation = Instance.new("Animation")
slideAnimation.AnimationId = "rbxassetid://7727017099"

local function slideStop ()
	keysPressed = UIS:GetKeysPressed()
	local LctrlUp = true
	for _, key in ipairs(keysPressed) do
		if (key.KeyCode == lctrl) then
			LctrlUp = false
		end
		if (key.KeyCode == spacebar) then
			LctrlUp = true
			break
		end
	end
	return LctrlUp
end

local function slide()
	if(not slideEnoughSpeed) then
		return
	end
	canslide = false
	local slideCooldown = 0.3
	local slidingAnim = character.Humanoid:LoadAnimation(slideAnimation)
	slidingAnim:Play()

	local sliding = Instance.new("BodyVelocity")
	sliding.MaxForce = Vector3.new(1,0,1) * 30000
	sliding.Velocity = character.HumanoidRootPart.CFrame.lookVector * 150
	sliding.Parent = character.HumanoidRootPart
	local slideDecel = 0.8
	for count = 1,8 do
		if(character.Humanoid.WalkSpeed == 0) then
			sliding.Velocity = 0
		end
		slideCooldown += 0.1
		wait(0.1)
		--print("decel ",slideDecel - (0.05 * count))
		sliding.Velocity *= slideDecel - (0.05 * count)
		if(slideStop()) then
			break
		end
	end

	slidingAnim:stop()
	sliding:Destroy()
	wait(slideCooldown)
	canslide = true
	return
end

local function keyInput(input, gameprocessed)
	if gameprocessed then return end
	if not canslide then return end
	if input.KeyCode == lctrl then
		slide()
	end
	return
end


UIS.InputBegan:Connect(keyInput)
character.Humanoid.Running:Connect(function(speed)
	if speed > 10 then
		slideEnoughSpeed = true
	else
		slideEnoughSpeed = false
	end
end)