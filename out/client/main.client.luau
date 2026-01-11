-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local InputControls = TS.import(script, script.Parent, "Ball", "Input", "InputController").InputControls
local Remotes = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "remotes").default
local CameraBall = TS.import(script, script.Parent, "Ball", "Camera", "Camera").CameraBall
local _services = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services")
local CollectionService = _services.CollectionService
local Players = _services.Players
local Workspace = _services.Workspace
local ballInputControls = InputControls.new()
local cameraBallController = CameraBall.new()
local balls = CollectionService:GetTagged("Balls")[1]
if balls then
	local ball = balls:FindFirstChild(`Ball_{Players.LocalPlayer.Name}_{Players.LocalPlayer.UserId}`)
	if ball then
		ballInputControls:enable(ball)
		cameraBallController:enable(ball)
	end
end
Workspace.DescendantAdded:Connect(function(c)
	if c.Name ~= `Ball_{Players.LocalPlayer.Name}_{Players.LocalPlayer.UserId}` then
		return nil
	end
	ballInputControls:enable(c)
	cameraBallController:enable(c)
end)
Remotes.Client:Get("Ball"):Connect(function(enabled)
	if enabled == false then
		cameraBallController:disable()
		ballInputControls:disable()
		print("No ball found for the player or ball disabled.")
	end
end)
