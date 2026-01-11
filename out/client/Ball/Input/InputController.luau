-- Compiled with roblox-ts v3.0.0

-- Runtime & services imports
local TS = require(game:GetService("ReplicatedStorage")
	:WaitForChild("rbxts_include")
	:WaitForChild("RuntimeLib"))

local Services = TS.import(
	script,
	game:GetService("ReplicatedStorage"),
	"rbxts_include",
	"node_modules",
	"@rbxts",
	"services"
)

local CollectionService     = Services.CollectionService
local ContextActionService  = Services.ContextActionService
local Players               = Services.Players
local RunService            = Services.RunService
local UserInputService      = Services.UserInputService
local Workspace             = Services.Workspace

-- Shared modules
local Remotes = TS.import(
	script,
	game:GetService("ReplicatedStorage"),
	"TS",
	"remotes"
).default

local CameraBall = TS.import(
	script,
	script.Parent.Parent,
	"Camera",
	"Camera"
).CameraBall

local player = Players.LocalPlayer

----------------------------------------------------------------
-- InputControls class definition
----------------------------------------------------------------
local InputControls = {}
InputControls.__index = InputControls

function InputControls.new()
	local self = setmetatable({}, InputControls)
	self:constructor()
	return self
end

function InputControls:constructor()
	-- Cached ball instance
	self.ball = nil

	-- Whether input logic is active
	self.enabled = false

	-- RunService connection
	self.ballControlsConnection = nil

	-- Unused flag (could likely be removed)
	self.canAttach = false
end

----------------------------------------------------------------
-- Character / ball helpers
----------------------------------------------------------------

-- Returns the player's Humanoid if valid and alive
function InputControls:getHumanoid()
	local character = Players.LocalPlayer.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return nil
	end

	return humanoid
end

-- Retrieves and caches the ball associated with the player
function InputControls:getBallFromPlayer()
	if self.ball and self.ball.Parent then
		return self.ball
	end

	local tagged = CollectionService:GetTagged(tostring(player.UserId))
	local ball = tagged[1]

	self.ball = ball
	return ball
end

-- Returns the PrimaryPart of the ball
function InputControls:getPrimaryPart(ball)
	local root = ball.PrimaryPart
	if not root then
		return nil
	end
	return root
end

----------------------------------------------------------------
-- Movement mechanics
----------------------------------------------------------------

-- Applies a vertical impulse to the ball (jump)
function InputControls:jumpBoost()
	local ball = self:getBallFromPlayer()
	if not ball then return end

	local root = self:getPrimaryPart(ball)
	if not root then return end

	-- Reset vertical velocity
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)

	-- Apply impulse upward
	local jumpVelocity = 70
	local impulse = Vector3.yAxis * (jumpVelocity * root.AssemblyMass)
	root:ApplyImpulse(impulse)
end

----------------------------------------------------------------
-- Grapple hook input
----------------------------------------------------------------

-- Called when grapple button is pressed
InputControls.onMouseDown = TS.async(function(self)
	local camera = Workspace.CurrentCamera
	if not camera then return end

	local ball = self:getBallFromPlayer()
	if not ball then return end

	local ballPrimaryPart = self:getPrimaryPart(ball)
	if not ballPrimaryPart then return end

	-- Check if grappling is possible
	local hookData = CameraBall:canSimplyHook(
		camera.CFrame,
		ballPrimaryPart.CFrame
	)

	if not hookData then return end

	-- Ask server to attach grapple
	local success = TS.await(
		Remotes.Client:Get("GrappleHook"):CallServerAsync(hookData)
	)

	if not success then return end
end)

-- Called when grapple button is released
InputControls.onMouseUp = TS.async(function(self)
	local success = TS.await(
		Remotes.Client:Get("UnGrappleHook"):CallServerAsync()
	)

	if not success then return end
end)

----------------------------------------------------------------
-- Environment detection
----------------------------------------------------------------

-- Checks if the ball is airborne (no ground detected below)
function InputControls:isAirborne(root)
	if not root or not root.Parent then
		return false
	end

	local ball = self:getBallFromPlayer()
	if not ball then
		return false
	end

	local rayOrigin = root.Position
	local rayDirection = Vector3.new(0, -8, 0)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { root.Parent, ball }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(rayOrigin, rayDirection, params)
	return result == nil
end

-- Checks if the player is facing a wall
function InputControls:isAgainstWall(root)
	if not root or not root.Parent then
		return false
	end

	local ball = self:getBallFromPlayer()
	if not ball then
		return false
	end

	local rayOrigin = root.Position - Vector3.new(0, 1.75, 0)
	local look = root.CFrame.LookVector
	local horizontalLook = Vector3.new(look.X, 0, look.Z)

	if horizontalLook.Magnitude == 0 then
		return false
	end

	local rayDirection = horizontalLook.Unit * 7.5

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { root.Parent, ball }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(rayOrigin, rayDirection, params)

	if result then
		return result.Instance.CanCollide == true
	end

	return false
end

----------------------------------------------------------------
-- Physics handling
----------------------------------------------------------------

-- Handles mid-air directional control using LinearVelocity
function InputControls:handleAirMovement(enabled, ball, humanoid)
	local mass = 1
	if ball.PrimaryPart then
		mass = ball.PrimaryPart:GetMass()
	end

	local lv = ball.Constraints.LinearVelocity

	if enabled then
		local camera = Workspace.CurrentCamera
		if not camera then return end

		local forward = Vector3.new(
			camera.CFrame.LookVector.X,
			0,
			camera.CFrame.LookVector.Z
		).Unit

		local right = Vector3.yAxis:Cross(forward).Unit
		local input = humanoid.MoveDirection

		local moveDir = (forward * -input.Z) + (right * input.X)
		local horizontal = Vector3.new(-moveDir.X, 0, moveDir.Z)

		local accel = 100
		lv.Force = horizontal * (mass * accel)
		lv.Enabled = true
	else
		lv.Force = Vector3.zero
		lv.Enabled = false
	end
end

-- Applies a vertical boost when colliding with a wall
function InputControls:handleWallBoost(ballPrimaryPart)
	ballPrimaryPart.AssemblyLinearVelocity = Vector3.new(
		ballPrimaryPart.AssemblyLinearVelocity.X,
		30,
		ballPrimaryPart.AssemblyLinearVelocity.Z
	)
end

----------------------------------------------------------------
-- Main update loop
----------------------------------------------------------------

function InputControls:onStepped()
	if not self.enabled then
		if self.ballControlsConnection then
			self.ballControlsConnection:Disconnect()
		end
		return
	end

	local humanoid = self:getHumanoid()
	if not humanoid then
		return self:disable()
	end

	local ball = self:getBallFromPlayer()
	if not ball then
		return self:disable()
	end

	local ballPrimaryPart = self:getPrimaryPart(ball)
	if not ballPrimaryPart then
		return
	end

	-- Wall boost logic
	if self:isAgainstWall(humanoid.RootPart)
		and math.floor(ballPrimaryPart.AssemblyLinearVelocity.Magnitude) >= 1
	then
		self:handleWallBoost(ballPrimaryPart)
	end

	-- Air control
	self:handleAirMovement(
		self:isAirborne(humanoid.RootPart),
		ball,
		humanoid
	)
end

----------------------------------------------------------------
-- Enable / Disable
----------------------------------------------------------------

function InputControls:enable(ball)
	task.wait()
	self.enabled = true

	self.ballControlsConnection = RunService.Stepped:Connect(function()
		self:onStepped()
	end)

	local playerGui = player:FindFirstChild("PlayerGui")
	local input = playerGui:FindFirstChild("PlayContext")
	local jump = input:FindFirstChild("Jump")
	local inputGui = playerGui:FindFirstChild("ContextInput")

	local grappleHook = input:FindFirstChild("GrappleHook")
	local hud = playerGui:FindFirstChild("HUD")
	local main = hud:FindFirstChild("FrameMain")
	local help = main:FindFirstChild("FrameHelp")

	-- Auto-disable when ball is destroyed
	ball.Destroying:Connect(function()
		self.enabled = false
		self:disable()
	end)

	if input then
		input.Enabled = true
	end

	if UserInputService.TouchEnabled then
		inputGui.Enabled = true
		help.Visible = false
	else
		help.Visible = true
	end

	grappleHook.Pressed:Connect(function()
		self:onMouseDown()
	end)

	grappleHook.Released:Connect(function()
		self:onMouseUp()
	end)

	jump.Pressed:Connect(function()
		local humanoid = self:getHumanoid()
		if not humanoid then return end

		if not self:isAirborne(humanoid.RootPart) then
			self:jumpBoost()
		end
	end)
end

function InputControls:disable()
	self.enabled = false

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local input = playerGui:FindFirstChild("PlayContext")
	local inputGui = playerGui:FindFirstChild("ContextInput")

	if inputGui then
		inputGui.Enabled = false
	end

	if input then
		input.Enabled = false
	end

	ContextActionService:UnbindAction("GrappleHook")

	if self.ballControlsConnection then
		self.ballControlsConnection:Disconnect()
	end
end

return {
	InputControls = InputControls,
}
