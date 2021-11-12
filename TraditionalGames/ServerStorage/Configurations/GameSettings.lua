local GameSettings = {}

----Manager----
GameSettings.ManagerKey = Enum.KeyCode.T
GameSettings.ManagerAuthorized = {"example1"}

GameSettings.QueueTime = 1
GameSettings.GameStartTime = 1


----BallGame----
--Distance that Player can start push
GameSettings.BallPushDistance = 4
--BallGame LimitTime
GameSettings.BallPushTime = 5
GameSettings.BallSpeedMax = 25


----TuhoGame----
GameSettings.TuhoTime = 5


----RopeGame----
GameSettings.RopeTime = 5
GameSettings.RopeCFrameOrigin = game.Workspace.RopeGame.Rope.CFrame
GameSettings.RopeEndDistance = 10
GameSettings.RopePullTime = 60

--ropeAxis
GameSettings.RopeDirection = "Z"
GameSettings.RopePlayerStartDistance = 2
GameSettings.RopePlayerBetween = 3
GameSettings.RopePlayerLeftRight = 4
GameSettings.RopeEndureMag = 0.8
GameSettings.RopeMaxVel = 10



return GameSettings
