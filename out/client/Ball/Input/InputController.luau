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

----------------------------------------------------------------
-- Tuning constants
-- These values control the physical behavior of the ball movement.
----------------------------------------------------------------

local JUMP_VELOCITY = 70
-- Upward velocity applied when the player performs a jump

local GROUND_CHECK_DISTANCE = 8
-- Vertical raycast distance used to determine if the ball is grounded

local WALL_CHECK_DISTANCE = 7.5
-- Horizontal raycast distance used to detect walls in front of the player

local AIR_ACCELERATION = 100
-- Force multiplier applied to mid-air movement control

local WALL_BOOST_VELOCITY = 30
-- Vertical velocity applied when performing a wall boost

local MIN_WALL_BOOST_SPEED = 1
-- Minimum velocity required to allow a wall boost, prevents jitter activation

----------------------------------------------------------------
-- CameraBall

-- CameraBall:canSimplyHook(cameraCframe: CFrame, PrimaryPartCframe: CFrame) 
-- Allows you to find the closest point to attach to based on the direction of the camera.
-- Returns: Closest instance or nil
----------------------------------------------------------------

local CameraBall = TS.import(
	script,
	script.Parent.Parent,
	"Camera",
	"Camera"
).CameraBall


local player = Players.LocalPlayer

----------------------------------------------------------------
-- InputControls class definition

-- This class manages :
-- the wall climbing system 
-- movement when the ball is in the air to be able to move 
-- attaching and detaching the grappling hook
-- input management for PCs, phones, and consoles

-- Lifecycle :
-- enable()   → binds inputs and RunService
-- onStepped  → runtime validation and physics handling
-- disable()  → unbinds everything and leaves the controller inert
-- The controller may self-disable if prerequisites are lost
----------------------------------------------------------------

local InputControls = {}
InputControls.__index = InputControls

function InputControls.new()
	local self = setmetatable({}, InputControls)
	self:constructor()
	return self
end

function InputControls:constructor()
	self.ball = nil -- Cached ball instance

	self.enabled = false -- Controller activation or not

	self.ballControlsConnection = nil -- RunService connection
end

----------------------------------------------------------------
-- Character / ball helpers
----------------------------------------------------------------

-- Returns the player's Humanoid if valid and alive
function InputControls:getHumanoid()
	local character = Players.LocalPlayer.Character -- Retrieves the local player's character model
	if not character then -- Checks if the character exists
		return nil -- Returns nil if the character is missing
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid") -- Searches for a Humanoid object
	if humanoid == nil or humanoid.Health <= 0 then -- Checks existence and alive state
		return nil -- Returns nil if invalid or dead
	end

	return humanoid -- Returns the valid humanoid instance
end

-- A safer method for retrieving the player's ball
-- Retrieves and caches the ball associated with the player
function InputControls:getBallFromPlayer()
	if self.ball and self.ball.Parent then -- Checks if a cached ball exists and is still in the game
		return self.ball -- Returns the cached ball
	end

	local tagged = CollectionService:GetTagged(tostring(player.UserId)) -- Retrieves all instances tagged with the player's userId
	local ball = tagged[1] -- Takes the first tagged instance as the ball

	self.ball = ball -- Caches the ball reference
	return ball -- Returns the ball instance
end

-- Returns the PrimaryPart of the ball
function InputControls:getPrimaryPart(ball)
	local root = ball.PrimaryPart -- Retrieves the PrimaryPart of the ball model
	if not root then -- Checks if the PrimaryPart exists
		return nil -- Returns nil if missing
	end
	return root -- Returns the PrimaryPart
end

----------------------------------------------------------------
-- Movement mechanics
----------------------------------------------------------------

-- Applies a vertical impulse to the ball (jump)
function InputControls:jumpBoost()
	local ball = self:getBallFromPlayer() -- Retrieves the player's ball
	if not ball then return end -- Stops execution if the ball does not exist

	local root = self:getPrimaryPart(ball) -- Retrieves the ball's PrimaryPart
	if not root then return end -- Stops execution if missing

	local v = root.AssemblyLinearVelocity  -- Stores the current velocity vector
	root.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z) -- Resets the vertical velocity component

	local impulse = Vector3.yAxis * (JUMP_VELOCITY * root.AssemblyMass) -- Computes the impulse force
	root:ApplyImpulse(impulse) -- Applies the impulse to the ball
end

----------------------------------------------------------------
-- Grapple hook input
-- Client-side validation only.
-- Final authority is always enforced server-side.
----------------------------------------------------------------

-- Called when grapple button is pressed
-- This function allows you to check whether you can hook on with your grappling hook. If so, send a server request to hook on.
InputControls.onMouseDown = TS.async(function(self)
	local camera = Workspace.CurrentCamera -- Retrieves the current client camera
	if not camera then return end -- Stops if the camera does not exist

	local ball = self:getBallFromPlayer() -- Retrieves the player's ball
	if not ball then return end -- Stops if no ball exists

	local ballPrimaryPart = self:getPrimaryPart(ball) -- Retrieves the ball's PrimaryPart
	if not ballPrimaryPart then return end -- Stops if missing

	local hookData = CameraBall:canSimplyHook( -- Checks if grappling is possible (client-side)
		camera.CFrame, -- Passes the camera orientation
		ballPrimaryPart.CFrame -- Passes the ball orientation
	)

	if not hookData then return end -- Stops if grappling is not possible

	local success = TS.await( -- Waits for the server response
		Remotes.Client:Get("GrappleHook"):CallServerAsync(hookData) -- Sends grappling request to server
	)

	if not success then return end -- Stops if the server rejected the request
end)

-- This function allows you to disconnect; it does not require any special verification, as the server takes care of it. 
-- Called when grapple button is released
InputControls.onMouseUp = TS.async(function(self)
	local success = TS.await( -- Waits for the server response
		Remotes.Client:Get("UnGrappleHook"):CallServerAsync() -- Sends request to detach the grapple
	)

	if not success then return end -- Stops if the server rejected the request
end)

----------------------------------------------------------------
-- Environment detection
----------------------------------------------------------------

-- Checks if the ball is airborne (no ground detected below)
function InputControls:isAirborne(root)
	if not root or not root.Parent then -- Checks if the root part is valid
		return false -- Returns false if invalid
	end

	local ball = self:getBallFromPlayer() -- Retrieves the player's ball
	if not ball then
		return false -- Returns false if the ball does not exist
	end

	local rayOrigin = root.Position -- Sets the raycast origin position
	local rayDirection = Vector3.new(0, -GROUND_CHECK_DISTANCE, 0) -- Sets the downward ray direction

	local params = RaycastParams.new() -- Creates raycast parameters
	params.FilterDescendantsInstances = { root.Parent, ball } -- Excludes the character and ball
	params.FilterType = Enum.RaycastFilterType.Exclude -- Uses exclusion filtering

	local result = Workspace:Raycast(rayOrigin, rayDirection, params) -- Performs the raycast
	return result == nil -- Returns true if nothing was hit (airborne)
end

-- Checks if the player's ball is facing a wall
function InputControls:isAgainstWall(root)
	if not root or not root.Parent then -- Checks if the root part is valid
		return false -- Returns false if invalid
	end

	local ball = self:getBallFromPlayer() -- Retrieves the player's ball
	if not ball then
		return false -- Returns false if missing
	end

	local rayOrigin = root.Position - Vector3.new(0, 1.75, 0) -- Offsets the ray origin downward
	local look = root.CFrame.LookVector -- Retrieves the forward direction
	local horizontalLook = Vector3.new(look.X, 0, look.Z)    -- Removes vertical component

	if horizontalLook.Magnitude == 0 then -- Checks if direction is valid
		return false -- Returns false if invalid
	end

	local rayDirection = horizontalLook.Unit * WALL_CHECK_DISTANCE -- Sets ray length and direction

	local params = RaycastParams.new() -- Creates raycast parameters
	params.FilterDescendantsInstances = { root.Parent, ball } -- Excludes character and ball
	params.FilterType = Enum.RaycastFilterType.Exclude -- Uses exclusion filtering

	local result = Workspace:Raycast(rayOrigin, rayDirection, params) -- Performs the raycast

	if result then
		return result.Instance.CanCollide == true -- Returns true if the object is collidable
	end

	return false -- Returns false if no wall is detected
end

----------------------------------------------------------------
-- Physics handling
----------------------------------------------------------------

-- Handles mid-air directional control using LinearVelocity
-- The enabled variable depends on whether the ball is in the void or not
function InputControls:handleAirMovement(enabled, ball, humanoid)
	local mass = 1 -- Default mass value
	if ball.PrimaryPart then
		mass = ball.PrimaryPart:GetMass() -- Retrieves the actual ball mass
	end

	local lv = ball.Constraints.LinearVelocity -- Retrieves the LinearVelocity constraint

	if enabled then
		local camera = Workspace.CurrentCamera -- Retrieves the camera
		if not camera then return end -- Stops if missing

		local forward = Vector3.new(
			camera.CFrame.LookVector.X, -- Uses camera forward X component
			0, -- Removes vertical influence
			camera.CFrame.LookVector.Z  -- Uses camera forward Z component
		).Unit

		local right = Vector3.yAxis:Cross(forward).Unit -- Computes right direction vector
		local input = humanoid.MoveDirection            -- Retrieves player input direction

		local moveDir = (forward * -input.Z) + (right * input.X) -- Combines input vectors
		local horizontal = Vector3.new(-moveDir.X, 0, moveDir.Z) -- Converts to world direction

		local accel = AIR_ACCELERATION -- Defines air acceleration constant
		lv.Force = horizontal * (mass * accel) -- Applies force to the constraint
		lv.Enabled = true -- Enables the constraint
	else
		lv.Force = Vector3.zero -- Resets the applied force
		lv.Enabled = false -- Disables the constraint
	end
end

-- This function allows you to apply the boost to climb the wall
-- Applies a vertical boost when colliding with a wall
function InputControls:handleWallBoost(ballPrimaryPart)
	ballPrimaryPart.AssemblyLinearVelocity = Vector3.new(
		ballPrimaryPart.AssemblyLinearVelocity.X, -- Preserves horizontal X velocity
		WALL_BOOST_VELOCITY, -- Sets vertical boost velocity
		ballPrimaryPart.AssemblyLinearVelocity.Z  -- Preserves horizontal Z velocity
	)
end

----------------------------------------------------------------
-- Main update loop
----------------------------------------------------------------

function InputControls:onStepped()

	----------------------------------------------------------------
	-- Checks
	----------------------------------------------------------------
		
	if not self.enabled then -- Checks if the controller is disabled
		if self.ballControlsConnection then
			self.ballControlsConnection:Disconnect() -- Disconnects the update loop
		end
		return -- Stops execution
	end

	local humanoid = self:getHumanoid() -- Retrieves the humanoid
	if not humanoid then
		return self:disable() -- Disables the controller if invalid
	end

	local ball = self:getBallFromPlayer() -- Retrieves the ball
	if not ball then
		return self:disable() -- Disables the controller if missing
	end

	local ballPrimaryPart = self:getPrimaryPart(ball) -- Retrieves the ball root
	if not ballPrimaryPart then
		return -- Stops execution if missing
	end

	----------------------------------------------------------------
	-- Physical Handling
	----------------------------------------------------------------

	if self:isAgainstWall(humanoid.RootPart)
		and math.floor(ballPrimaryPart.AssemblyLinearVelocity.Magnitude) >= MIN_WALL_BOOST_SPEED
	then
		self:handleWallBoost(ballPrimaryPart) -- Applies wall boost
	end

	self:handleAirMovement(
		self:isAirborne(humanoid.RootPart), -- Checks airborne state
		ball, -- Passes the ball
		humanoid -- Passes the humanoid
	)
end

----------------------------------------------------------------
-- Enable / Disable
----------------------------------------------------------------

function InputControls:enable(ball)
	task.wait() -- Delays execution by one frame to ensure required instances are initialized
	self.enabled = true -- Marks the input controller as active

	self.ballControlsConnection = RunService.Stepped:Connect(function() -- Connects logic to the physics step
		self:onStepped() -- Executes the per-frame update logic
	end)

	-- Auto-disable when ball is destroyed
	ball.Destroying:Connect(function() -- Listens for the ball being destroyed
		self.enabled = false -- Marks the controller as inactive
		self:disable() -- Fully disables the input controller and cleans up connections
	end)

	local playerGui = player:FindFirstChild("PlayerGui") -- Retrieves the PlayerGui container

	local input = playerGui:FindFirstChild("PlayContext") -- Retrieves the main input UI container
	local jump = input:FindFirstChild("Jump") -- Retrieves the jump input button
	local grappleHook = input:FindFirstChild("GrappleHook") -- Retrieves the grapple hook input button

	local inputGui = playerGui:FindFirstChild("ContextInput") -- Retrieves the contextual input GUI

	local hud = playerGui:FindFirstChild("HUD") -- Retrieves the HUD container
	local main = hud:FindFirstChild("FrameMain") -- Retrieves the main HUD frame
	local help = main:FindFirstChild("FrameHelp") -- Retrieves the help panel frame

	if input then -- Checks if the input UI exists
		input.Enabled = true -- Enables the input UI
	end

	if UserInputService.TouchEnabled then -- Checks if the player is using a touch device
		inputGui.Enabled = true -- Enables the touch input GUI
		help.Visible = false -- Hides the help panel for touch devices
	else
		help.Visible = true -- Shows the help panel for non-touch devices
	end

	grappleHook.Pressed:Connect(function() -- Binds logic to grapple button press
		self:onMouseDown() -- Handles grapple activation
	end)

	grappleHook.Released:Connect(function() -- Binds logic to grapple button release
		self:onMouseUp() -- Handles grapple release
	end)

	jump.Pressed:Connect(function() -- Binds logic to jump button press
		local humanoid = self:getHumanoid() -- Retrieves the player's humanoid
		if not humanoid then return end -- Stops if the humanoid is invalid

		-- This condition prevents the player from performing infinite jumps.
		if not self:isAirborne(humanoid.RootPart) then -- Checks if the player is grounded
			self:jumpBoost() -- Applies a jump impulse to the ball
		end
	end)
end

function InputControls:disable()
	self.enabled = false -- Marks the input controller as inactive

	local playerGui = player:FindFirstChild("PlayerGui") -- Retrieves the PlayerGui container
	if not playerGui then return end -- Stops if PlayerGui does not exist

	local input = playerGui:FindFirstChild("PlayContext") -- Retrieves the main input UI container
	local inputGui = playerGui:FindFirstChild("ContextInput") -- Retrieves the contextual input GUI

	if inputGui then -- Checks if the contextual input GUI exists
		inputGui.Enabled = false -- Disables the contextual input GUI
	end

	if input then -- Checks if the input UI exists
		input.Enabled = false -- Disables the input UI
	end

	ContextActionService:UnbindAction("GrappleHook") -- Unbinds the grapple input action

	if self.ballControlsConnection then -- Checks if a RunService connection exists
		self.ballControlsConnection:Disconnect() -- Disconnects the physics update loop
	end
end

return {
	InputControls = InputControls,
}
