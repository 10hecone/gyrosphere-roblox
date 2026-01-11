-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local _services = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services")
local CollectionService = _services.CollectionService
local ContextActionService = _services.ContextActionService
local Players = _services.Players
local RunService = _services.RunService
local UserInputService = _services.UserInputService
local Workspace = _services.Workspace
local Remotes = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "remotes").default
local CameraBall = TS.import(script, script.Parent.Parent, "Camera", "Camera").CameraBall
local player = Players.LocalPlayer

--[[
    InputControls Class
    -------------------
    Handles player input controls for interacting with a ball object.
    
    Responsibilities:
      - Enable and disable ball control.
      - Handle movement, jump, and grappling inputs.
      - Apply physics interactions (impulses, collisions, linear velocity).
      - Detect player states such as airborne or against a wall.
]]
local InputControls
do
    InputControls = setmetatable({}, {
        __tostring = function()
            return "InputControls"
        end,
    })
    InputControls.__index = InputControls

    function InputControls.new(...)
        local self = setmetatable({}, InputControls)
        return self:constructor(...) or self
    end

    -- Constructor initializes state variables
    function InputControls:constructor()
        self.ball = nil                -- Reference to the player's ball
        self.enabled = false           -- Whether input control is active
        local _ = self.ballControlsConnection
        self.canAttach = false         -- Whether the grappling hook can attach
    end

    -- Returns the Humanoid of the local player if it exists and is alive
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

    -- Returns the player's ball if it exists; caches it internally
    function InputControls:getBallFromPlayer()
        if self.ball and self.ball.Parent then
            return self.ball
        end
        local ball = CollectionService:GetTagged(tostring(player.UserId))[1]
        self.ball = ball
        return ball
    end

    -- Returns the PrimaryPart of a ball if it exists
    function InputControls:getPrimaryPart(ball)
        return ball.PrimaryPart or nil
    end

    -- Applies a vertical jump impulse to the ball
    function InputControls:jumpBoost()
        local ball = self:getBallFromPlayer()
        if not ball then
            return nil
        end
        local root = self:getPrimaryPart(ball)
        if not root then
            return nil
        end
        -- Reset vertical velocity component
        local v = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
        -- Apply vertical impulse based on mass
        local jumpVelocity = 70
        local impulse = Vector3.yAxis * (jumpVelocity * root.AssemblyMass)
        root:ApplyImpulse(impulse)
    end

    -- Handles mouse down (attempts grappling hook)
    InputControls.onMouseDown = TS.async(function(self)
        local camera = Workspace.CurrentCamera
        if not camera then return nil end

        local ball = self:getBallFromPlayer()
        if not ball then return nil end

        local ballPrimaryPart = self:getPrimaryPart(ball)
        if not ballPrimaryPart then return nil end

        local hookSimply = CameraBall:canSimplyHook(camera.CFrame, ballPrimaryPart.CFrame)
        if not hookSimply then return nil end

        -- Call server to attempt grappling hook
        local succes = TS.await(Remotes.Client:Get("GrappleHook"):CallServerAsync(hookSimply))
        if not succes then return nil end
    end)

    -- Handles mouse up (release grappling hook)
    InputControls.onMouseUp = TS.async(function(self)
        local succes = TS.await(Remotes.Client:Get("UnGrappleHook"):CallServerAsync())
        if not succes then return nil end
    end)

    -- Checks if the player is in the air
    function InputControls:isAirborne(root)
        if root == nil or root.Parent == nil then
            return false
        end
        local ball = self:getBallFromPlayer()
        if not ball then return false end

        local rayOrigin = root.Position
        local rayDirection = Vector3.new(0, -8, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {root.Parent, ball}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        return result == nil
    end

    -- Checks if the player is against a wall
    function InputControls:isAgainstWall(root)
        if root == nil or root.Parent == nil then
            return false
        end
        local ball = self:getBallFromPlayer()
        if not ball then return false end

        local rayOrigin = root.Position - Vector3.new(0, 1.75, 0)
        local look = root.CFrame.LookVector
        local horizontalLook = Vector3.new(look.X, 0, look.Z)
        if horizontalLook.Magnitude == 0 then return false end

        local rayDirection = horizontalLook.Unit * 7.5
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {root.Parent, ball}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        return if result then result.Instance.CanCollide == true else false
    end

    -- Called each step to apply forces and manage physics
    function InputControls:onStepped()
        if not self.enabled then
            if self.ballControlsConnection then
                self.ballControlsConnection:Disconnect()
            end
            return
        end

        local humanoid = self:getHumanoid()
        if not humanoid then return self:disable() end

        local ball = self:getBallFromPlayer()
        if not ball then return self:disable() end

        local camera = Workspace.CurrentCamera
        if not camera then return nil end

        local ballPrimaryPart = self:getPrimaryPart(ball)
        if not ballPrimaryPart then return nil end

        -- Wall bounce
        if self:isAgainstWall(humanoid.RootPart) and math.floor(ballPrimaryPart.AssemblyLinearVelocity.Magnitude) >= 1 then
            ballPrimaryPart.AssemblyLinearVelocity = Vector3.new(ballPrimaryPart.AssemblyLinearVelocity.X, 30, ballPrimaryPart.AssemblyLinearVelocity.Z)
        end

        local mass = ball.PrimaryPart and ball.PrimaryPart:GetMass() or 1
        local lv = ball.Constraints.LinearVelocity

        -- Apply movement forces if airborne
        if self:isAirborne(humanoid.RootPart) then
            local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
            local right = Vector3.yAxis:Cross(forward).Unit
            local input = humanoid.MoveDirection
            local moveDir = forward * -input.Z + right * input.X
            local horizontal = Vector3.new(-moveDir.X, 0, moveDir.Z)
            local accel = 100
            local force = mass * accel

            lv.Force = horizontal * force
            lv.Enabled = true
        else
            lv.Force = Vector3.new(0, 0, 0)
            lv.Enabled = false
        end
    end

    -- Enables ball control and binds user input
    function InputControls:enable(ball)
        task.wait()
        self.enabled = true
        self.ballControlsConnection = RunService.Stepped:Connect(function() return self:onStepped() end)

        local playerGui = player:FindFirstChild("PlayerGui")
        local input = playerGui:FindFirstChild("PlayContext")
        local inputGui = playerGui:FindFirstChild("ContextInput")
        local jump = input:FindFirstChild("Jump")
        local grappleHook = input:FindFirstChild("GrappleHook")
        local hud = playerGui:FindFirstChild("HUD")
        local main = hud:FindFirstChild("FrameMain")
        local help = main:FindFirstChild("FrameHelp")

        -- Disconnect on ball destruction
        ball.Destroying:Connect(function()
            self.enabled = false
            self:disable()
        end)

        -- Enable UI based on device type
        if input then input.Enabled = true end
        if UserInputService.TouchEnabled then
            inputGui.Enabled = true
            help.Visible = false
        else
            help.Visible = true
        end

        -- Bind actions
        grappleHook.Pressed:Connect(function() return self:onMouseDown() end)
        grappleHook.Released:Connect(function() return self:onMouseUp() end)
        jump.Pressed:Connect(function()
            local humanoid = self:getHumanoid()
            if not humanoid then return nil end
            if not self:isAirborne(humanoid.RootPart) then
                self:jumpBoost()
            end
        end)
    end

    -- Disables ball control and cleans up connections
    function InputControls:disable()
        self.enabled = false

        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return nil end

        local input = playerGui:FindFirstChild("PlayContext")
        local inputGui = playerGui:FindFirstChild("ContextInput")

        if inputGui then inputGui.Enabled = false end
        if input then input.Enabled = false end

        ContextActionService:UnbindAction("GrappleHook")
        if self.ballControlsConnection then
            self.ballControlsConnection:Disconnect()
        end
    end
end

return {
    InputControls = InputControls,
}
