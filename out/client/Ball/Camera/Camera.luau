-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local _services = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services")
local Players = _services.Players
local RunService = _services.RunService
local TweenService = _services.TweenService
local UserInputService = _services.UserInputService
local Workspace = _services.Workspace
local ShiftLock = TS.import(script, script.Parent.Parent.Parent, "utils", "ShiftLock").ShiftLock
local ReplicatedStorage = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services").ReplicatedStorage
local rotating = false
local currentTween
local enabled = nil
local lastFieldOfView = 50
local CameraBall
do
	CameraBall = setmetatable({}, {
		__tostring = function()
			return "CameraBall"
		end,
	})
	CameraBall.__index = CameraBall
	function CameraBall.new(...)
		local self = setmetatable({}, CameraBall)
		return self:constructor(...) or self
	end
	function CameraBall:constructor()
		self.ball = nil
		self.chb = nil
	end
	function CameraBall:removeCrosshair()
		local _result = self.chb
		if _result ~= nil then
			_result:Destroy()
		end
		self.chb = nil
	end
	function CameraBall:mouseIcon(enable)
		UserInputService.MouseIconEnabled = enable
	end
	function CameraBall:setTweenTransparency(frame, state)
		local tweenInfo = TweenInfo.new(0.1)
		local hit = frame:FindFirstChild("Hit")
		local stud = frame:FindFirstChild("Stud")
		local pointer = frame:FindFirstChild("Pointer")
		local border = frame:FindFirstChild("Border")
		if hit == nil or pointer == nil or border == nil or stud == nil then
			return nil
		end
		TweenService:Create(hit, tweenInfo, {
			ImageTransparency = if state then 0 else 1,
		}):Play()
		TweenService:Create(stud, tweenInfo, {
			TextTransparency = if state then 0 else 1,
		}):Play()
		TweenService:Create(pointer, tweenInfo, {
			ImageTransparency = if state then 1 else 0,
		}):Play()
		TweenService:Create(border, tweenInfo, {
			ImageTransparency = if state then 0 else 1,
		}):Play()
	end
	function CameraBall:numLerp(a, b, t)
		return a + (b - a) * t
	end
	function CameraBall:updateFieldOfView(camera, deltaTime)
		local ball = self.ball
		if not ball then
			return nil
		end
		local ballVelocity = ball.PrimaryPart.AssemblyLinearVelocity
		-- Limitation de la magnitude pour le calcul du FOV
		local magnitude = math.min(ballVelocity.Magnitude, 80)
		-- Proportion par rapport à la vitesse maximale
		local proportion = magnitude / 80
		local newFOV = 50 + proportion * (65 - 50)
		-- Mise à jour du FieldOfView avec interpolation
		camera.FieldOfView = self:numLerp(lastFieldOfView, newFOV, math.min(deltaTime * 4, 1))
		lastFieldOfView = camera.FieldOfView
	end
	function CameraBall:setTweenRotation(state, uiElement)
		if state and not rotating then
			rotating = true
			task.spawn(function()
				while rotating do
					local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
					currentTween = TweenService:Create(uiElement, tweenInfo, {
						Rotation = uiElement.Rotation + 180,
					})
					currentTween:Play()
					currentTween.Completed:Wait()
				end
			end)
		else
			rotating = false
			if currentTween then
				currentTween:Cancel()
				currentTween = nil
			end
		end
	end
	function CameraBall:getAllGrappleFolders()
		local grappleFolders = {}
		local descendants = Workspace.World:GetDescendants()
		for _, descendant in descendants do
			if descendant:IsA("Folder") and descendant.Name == "Grapple" then
				table.insert(grappleFolders, descendant)
			end
		end
		return grappleFolders
	end
	function CameraBall:canSimplyHook(camera, root)
		local getCanAttach = Workspace.Grapple:GetChildren()
		local minDist = math.huge
		local closest = nil
		for _, canAttach in getCanAttach do
			if not canAttach:IsA("Part") then
				continue
			end
			local _position = canAttach.Position
			local _position_1 = root.Position
			local toPart = _position - _position_1
			local t = toPart:Dot(camera.LookVector.Unit)
			if t < 0 or t > 200 then
				continue
			end
			local _position_2 = root.Position
			local _arg0 = camera.LookVector.Unit * t
			local closestPoint = _position_2 + _arg0
			local dist = (canAttach.Position - closestPoint).Magnitude
			if dist > 60 then
				continue
			end
			if dist < minDist then
				minDist = dist
				closest = canAttach.Position
			end
		end
		return closest
	end
	function CameraBall:canHook(camera, folder)
		local raycastParams = RaycastParams.new()
		local _array = { Workspace.Grapple }
		local _length = #_array
		table.move(folder, 1, #folder, _length + 1, _array)
		raycastParams.FilterDescendantsInstances = _array
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		local direction = camera.LookVector * 200
		local result = Workspace:Raycast(camera.Position, direction, raycastParams)
		return result
	end
	function CameraBall:speedLine(ball)
		local camera = Workspace.CurrentCamera
		if not camera then
			return nil
		end
		local speedLine = Workspace:FindFirstChild("Speedlines")
		if not speedLine then
			local clone = ReplicatedStorage.Asset.Vfx.Speedlines.Speedlines:Clone()
			clone.Parent = Workspace
			speedLine = clone
		end
		local _result = ball.PrimaryPart
		if _result ~= nil then
			_result = _result.AssemblyLinearVelocity.Magnitude
		end
		local _condition = _result
		if _condition == nil then
			_condition = 0
		end
		local velocity = math.floor(_condition)
		local _position = camera.CFrame.Position
		local _arg0 = camera.CFrame.LookVector * 15.5
		local pos = _position + _arg0
		local y = math.clamp((velocity - 35) * 2, 0, 50)
		speedLine.Attachment.ParticleEmitter.Rate = y
		local _speedLine = speedLine
		local _lookVector = camera.CFrame.LookVector
		_speedLine:PivotTo(CFrame.new(pos, pos + _lookVector))
	end
	function CameraBall:onStepped(dt, chb, ball)
		local camera = Workspace.CurrentCamera
		if camera == nil then
			return nil
		end
		local frame = chb:FindFirstChild("Frame")
		if frame == nil then
			return nil
		end
		local border = frame:FindFirstChild("Border")
		if border == nil then
			return nil
		end
		local stud = frame:FindFirstChild("Stud")
		if stud == nil then
			return nil
		end
		local ballPrimaryPart = ball.PrimaryPart
		if not ballPrimaryPart then
			return nil
		end
		local canHook = CameraBall:canSimplyHook(camera.CFrame, ballPrimaryPart.CFrame)
		if canHook then
			stud.Visible = false
			local isGrappled = Players.LocalPlayer:GetAttribute("isAttached")
			if isGrappled == true then
				self:setTweenRotation(true, border)
			else
				self:setTweenRotation(false, border)
				border.Rotation = 0
			end
			self:setTweenTransparency(frame, true)
		else
			self:setTweenTransparency(frame, false)
		end
	end
	function CameraBall:addCrossHair(chb)
		chb.Enabled = true
	end
	function CameraBall:enable(ball)
		self.chb = ReplicatedStorage.Asset.UI.CrossHairBall:Clone()
		self.chb.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		self:addCrossHair(self.chb)
		enabled = RunService.Heartbeat:Connect(function(dt)
			if self.chb == nil then
				local _result = enabled
				if _result ~= nil then
					_result = _result:Disconnect()
				end
				return _result
			end
			self:speedLine(ball)
			self:onStepped(dt, self.chb, ball)
		end)
		self:mouseIcon(false)
		ShiftLock:Lock(true)
		-- task.wait(1)
		local cam = Workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable
		local currentCFrame = cam.CFrame
		local _arg0 = CFrame.Angles(0, math.rad(90), 0)
		local rotatedCFrame = currentCFrame * _arg0
		cam.CFrame = rotatedCFrame
		task.wait()
		cam.CameraType = Enum.CameraType.Custom
		-- player.CameraMinZoomDistance = 25;
		-- Workspace.Camera.FieldOfView = lastFieldOfView;
	end
	function CameraBall:disable()
		self:removeCrosshair()
		local _result = enabled
		if _result ~= nil then
			_result:Disconnect()
		end
		self:mouseIcon(true)
		ShiftLock:Lock(false)
	end
end
local grappleFolder = CameraBall:getAllGrappleFolders()
return {
	CameraBall = CameraBall,
	grappleFolder = grappleFolder,
}
