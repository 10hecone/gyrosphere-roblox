-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local BallService = TS.import(script, game:GetService("ServerScriptService"), "TS", "services", "BallService").BallService
local _services = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services")
local CollectionService = _services.CollectionService
local Players = _services.Players
local Workspace = _services.Workspace
local GrappleService = TS.import(script, game:GetService("ServerScriptService"), "TS", "services", "GrappleService").GrappleService
local bs = BallService.new()
GrappleService.new()
Players.PlayerAdded:Connect(function(ply)
	ply.CharacterAdded:Connect(function(char)
		task.wait()
		local _exp = char:GetDescendants()
		-- ▼ ReadonlyArray.forEach ▼
		local _callback = function(descendant)
			if not descendant:IsA("BasePart") then
				return nil
			end
			descendant.CollisionGroup = "Players"
		end
		for _k, _v in _exp do
			_callback(_v, _k - 1, _exp)
		end
		-- ▲ ReadonlyArray.forEach ▲
		local spawnLocation = CollectionService:GetTagged("SpawnLocation")[1]
		if not spawnLocation then
			spawnLocation = Workspace.World.SpawnLocation
		end
		bs:equip(ply, spawnLocation.CFrame)
	end)
end)
Players.PlayerRemoving:Connect(function(ply)
	bs:unequip(ply)
end)
