-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local _services = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services")
local CollectionService = _services.CollectionService
local Workspace = _services.Workspace
local Remotes = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "remotes").default
local GrappleService
do
	GrappleService = setmetatable({}, {
		__tostring = function()
			return "GrappleService"
		end,
	})
	GrappleService.__index = GrappleService
	function GrappleService.new(...)
		local self = setmetatable({}, GrappleService)
		return self:constructor(...) or self
	end
	function GrappleService:constructor()
		self.activeGrapples = {}
		Remotes.Server:Get("GrappleHook"):SetCallback(function(player, position)
			return self:grappleHook(player, position)
		end)
		Remotes.Server:Get("UnGrappleHook"):SetCallback(function(player)
			return self:unGrappleHook(player)
		end)
	end
	function GrappleService:getBallFromPlayer(player)
		local ball = CollectionService:GetTagged(tostring(player.UserId))[1]
		return ball
	end
	function GrappleService:createRope(hook, grapple, distance)
		local hookPart = Instance.new("Part")
		hookPart.Anchored = true
		hookPart.CanCollide = false
		hookPart.Transparency = 1
		hookPart.Position = hook
		hookPart.Parent = Workspace
		local attachment0 = Instance.new("Attachment")
		local attachement1 = Instance.new("Attachment")
		attachment0.Parent = hookPart
		attachement1.Parent = grapple
		local rope = Instance.new("RopeConstraint")
		rope.Visible = true
		rope.Length = distance
		rope.Attachment0 = attachment0
		rope.Attachment1 = attachement1
		rope.Parent = hookPart
		return {
			rope = rope,
			hookPart = hookPart,
			attachement1 = attachement1,
		}
	end
	function GrappleService:grappleHook(player, position)
		local _activeGrapples = self.activeGrapples
		local _player = player
		if _activeGrapples[_player] ~= nil then
			return false
		end
		local ball = self:getBallFromPlayer(player)
		if not ball or ball.PrimaryPart == nil then
			return false
		end
		local character = player.Character
		if not character then
			return false
		end
		local _position = position
		local _position_1 = ball.PrimaryPart.Position
		local distanceRope = (_position - _position_1).Magnitude
		if distanceRope > 200 then
			return false
		end
		local grapple = ball.Interior.Rope.Grapple
		local model = ball.Interior.Rope.GrappleModel
		local _position_2 = position
		local _position_3 = grapple.Position
		local distance = (_position_2 - _position_3).Magnitude * 0.9
		local rope = self:createRope(position, grapple, distance)
		local clone = model:Clone()
		clone:ClearAllChildren()
		clone.Anchored = true
		clone.CFrame = CFrame.new(position)
		clone.Parent = Workspace
		model.Transparency = 1
		local token = tostring(player.UserId) .. "_" .. tostring(tick())
		local grappleData = {
			token = token,
			hookPart = rope.hookPart,
			rope = rope.rope,
			attachement = rope.attachement1,
			model = model,
			clone = clone,
		}
		local _activeGrapples_1 = self.activeGrapples
		local _player_1 = player
		_activeGrapples_1[_player_1] = grappleData
		local minLength = 17
		local retractTime = 1.3
		player:SetAttribute("isAttached", true)
		task.spawn(function()
			local startLength = rope.rope.Length
			local elapsed = 0
			while rope and rope.hookPart and elapsed < retractTime do
				local delta = task.wait()
				elapsed += delta
				local alpha = math.clamp(elapsed / retractTime, 0, 1)
				rope.rope.Length = startLength + (minLength - startLength) * alpha
			end
			rope.rope.Length = minLength
		end)
		task.delay(15, function()
			pcall(function()
				local _activeGrapples_2 = self.activeGrapples
				local _player_2 = player
				local _condition = _activeGrapples_2[_player_2] ~= nil
				if _condition then
					local _activeGrapples_3 = self.activeGrapples
					local _player_3 = player
					local _result = _activeGrapples_3[_player_3]
					if _result ~= nil then
						_result = _result.token
					end
					_condition = _result == token
				end
				if _condition then
					self:unGrappleHook(player)
				end
			end)
		end)
		return true
	end
	function GrappleService:unGrappleHook(player)
		local _activeGrapples = self.activeGrapples
		local _player = player
		local grappleData = _activeGrapples[_player]
		player:SetAttribute("isAttached", false)
		if not grappleData then
			return false
		end
		grappleData.attachement:Destroy()
		grappleData.rope:Destroy()
		grappleData.hookPart:Destroy()
		grappleData.clone:Destroy()
		grappleData.model.Transparency = 0
		local _activeGrapples_1 = self.activeGrapples
		local _player_1 = player
		_activeGrapples_1[_player_1] = nil
		return true
	end
end
return {
	GrappleService = GrappleService,
}
