local Projectile = script.Parent
local Heartbeat = game:GetService("RunService").Heartbeat


local count = 0
while Heartbeat:wait() do
	Projectile.CFrame = CFrame.new(Projectile.Position, Projectile.Position + Projectile.Velocity)
	Projectile.CFrame = Projectile.CFrame* CFrame.fromEulerAnglesXYZ(-(script.Spin.Value*count), 0 , 0 )*CFrame.new(0,0,0)
	count += 0.1
end
