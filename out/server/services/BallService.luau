-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local _services = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services")
local CollectionService = _services.CollectionService
local Players = _services.Players
local ReplicatedStorage = _services.ReplicatedStorage
local Workspace = _services.Workspace
local Remotes = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "remotes").default
local ballOriginel = ReplicatedStorage.Gyro:FindFirstChild("Ball")
local BallService
do
	BallService = setmetatable({}, {
		__tostring = function()
			return "BallService"
		end,
	})
	BallService.__index = BallService
	function BallService.new(...)
		local self = setmetatable({}, BallService)
		return self:constructor(...) or self
	end
	function BallService:constructor()
	end
	function BallService:setCollisionConstraint(ball, character)
		local _result = character
		if _result ~= nil then
			_result = _result:GetDescendants()
		end
		for _, instance in _result do
			if not instance:IsA("BasePart") then
				continue
			end
			local noCollisionConstraint = Instance.new("NoCollisionConstraint")
			noCollisionConstraint.Part0 = ball.Exterior.CollisionBall
			noCollisionConstraint.Part1 = instance
			noCollisionConstraint.Parent = ball.NoCollisionConstraints
		end
	end
	function BallService:getBallFolder()
		local balls = CollectionService:GetTagged("Balls")
		if #balls == 0 then
			balls[1] = Instance.new("Folder")
			balls[1].Name = "Balls"
			balls[1].Parent = Workspace
			balls[1]:AddTag("Balls")
		end
		return balls[1]
	end
	function BallService:createBall(player, spawnCFrame)
		if #CollectionService:GetTagged(tostring(player.UserId)) > 0 then
			return false
		end
		if ballOriginel == nil then
			return false
		end
		local ball = ballOriginel:Clone()
		local balls = self:getBallFolder()
		ball.Name = `Ball_{player.Name}_{player.UserId}`
		ball:AddTag(tostring(player.UserId));
		(ball.PrimaryPart).CollisionGroup = "Players"
		local _exp = ball:GetDescendants()
		-- ▼ ReadonlyArray.forEach ▼
		local _callback = function(descendant)
			if not descendant:IsA("BasePart") then
				return nil
			end
			descendant:SetAttribute("UserId", tostring(player.UserId))
		end
		for _k, _v in _exp do
			_callback(_v, _k - 1, _exp)
		end
		-- ▲ ReadonlyArray.forEach ▲
		if spawnCFrame then
			local rotation = CFrame.Angles(0, math.rad(-90), 0)
			ball:PivotTo(CFrame.new(spawnCFrame.Position) * rotation)
		end
		player:AddTag("Ball")
		ball.Parent = balls
		if ball.PrimaryPart then
			ball.PrimaryPart:SetNetworkOwner(player)
		end
		return ball
	end
	function BallService:hasCharacterAndHumanoid(player)
		local character = player.Character
		if character == nil then
			return false
		end
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return false
		end
		return character
	end
	function BallService:connectSpawner(part)
		part.Touched:Connect(function(part)
			local player = Players:GetPlayerFromCharacter(part.Parent)
			if not player then
				return nil
			end
			self:equip(player)
		end)
	end
	function BallService:equip(player, spawnCFrame)
		local character = self:hasCharacterAndHumanoid(player)
		if character == false then
			return nil
		end
		local humanoid = character.Humanoid
		local ball = self:createBall(player, spawnCFrame)
		if not ball then
			return nil
		end
		local driverSeat = ball.DriverSeat
		if driverSeat.Occupant ~= nil then
			return nil
		end
		driverSeat:Sit(humanoid)
		self:setCollisionConstraint(ball, character)
		humanoid.Died:Once(function()
			self:unequip(player)
		end)
		Remotes.Server:Get("Ball"):SendToPlayer(player, true, ball)
	end
	function BallService:unequip(player)
		Remotes.Server:Get("Ball"):SendToPlayer(player, false, nil)
		player:RemoveTag("Ball")
		local ball = CollectionService:GetTagged(tostring(player.UserId))[1]
		if not ball then
			return nil
		end
		local driverSeat = ball:FindFirstChild("DriverSeat")
		if not driverSeat then
			return nil
		end
		local _unit = driverSeat.CFrame.LookVector.Unit
		local _vector3 = Vector3.new(1, 0, 1)
		local seatDirection = _unit * _vector3
		local stateConnection
		local _stateConnection = driverSeat.Occupant
		if _stateConnection ~= nil then
			_stateConnection = _stateConnection.StateChanged:Once(function(old)
				if old ~= Enum.HumanoidStateType.Seated then
					return nil
				end
				local _result = ball
				if _result ~= nil then
					_result = _result.Parent
				end
				if _result == nil then
					return nil
				end
				local exterior = ball:FindFirstChild("Exterior")
				if exterior then
					local _result_1 = driverSeat.Occupant
					if _result_1 ~= nil then
						_result_1 = _result_1.Parent
					end
					local _cFrame = driverSeat.CFrame
					local _x = ball.Exterior.CollisionBall.Size.X
					local _arg0 = seatDirection * _x
					_result_1:PivotTo(_cFrame - _arg0)
				end
				ball.NoCollisionConstraints:ClearAllChildren()
				local _result_1 = stateConnection
				if _result_1 ~= nil then
					_result_1:Disconnect()
				end
			end)
		end
		stateConnection = _stateConnection
		local seatWeld = driverSeat:FindFirstChild("SeatWeld")
		local _result = seatWeld
		if _result ~= nil then
			_result:Destroy()
		end
		ball:Destroy()
	end
end
return {
	BallService = BallService,
}
