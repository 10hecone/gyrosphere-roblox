-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local _services = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services")
local UserInputService = _services.UserInputService
local Players = _services.Players
local RunService = _services.RunService
local player = Players.LocalPlayer
local shiftLockEnabled = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return nil
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
		if not playerGui then
			return nil
		end
		local shiftLockGui = playerGui:FindFirstChild("ShiftLock")
		if not shiftLockGui then
			return nil
		end
		local shiftLockButton = shiftLockGui:FindFirstChildWhichIsA("GuiButton")
		if not shiftLockButton then
			return nil
		end
		if shiftLockButton.Modal == false then
			shiftLockButton.Modal = true
			UserInputService.MouseIconEnabled = true
		else
			shiftLockButton.Modal = false
			UserInputService.MouseIconEnabled = false
		end
	end
end)
local ShiftLock
do
	ShiftLock = setmetatable({}, {
		__tostring = function()
			return "ShiftLock"
		end,
	})
	ShiftLock.__index = ShiftLock
	function ShiftLock.new(...)
		local self = setmetatable({}, ShiftLock)
		return self:constructor(...) or self
	end
	function ShiftLock:constructor()
	end
	function ShiftLock:Lock(active)
		local character = player.Character or (player.CharacterAdded:Wait())
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			return nil
		end
		if active then
			shiftLockEnabled = true
			humanoid.CameraOffset = Vector3.new(0, 3.5, -3)
			humanoid.AutoRotate = false
			RunService:BindToRenderStep("ShiftLock", Enum.RenderPriority.Character.Value, function()
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end)
		else
			shiftLockEnabled = false
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
			RunService:UnbindFromRenderStep("ShiftLock")
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			humanoid.AutoRotate = true
		end
	end
end
return {
	ShiftLock = ShiftLock,
}
