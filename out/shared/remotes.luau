-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local Net = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "net", "out")
local _binding = Net.Definitions
local Create = _binding.Create
local Remotes = Create({
	Ball = Net.Definitions.ServerToClientEvent(),
	GrappleHook = Net.Definitions.ServerAsyncFunction(),
	UnGrappleHook = Net.Definitions.ServerAsyncFunction(),
})
local default = Remotes
return {
	default = default,
}
