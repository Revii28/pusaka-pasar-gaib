--!strict
--[[
	@module      Main
	@description Server entry point. Boot log + player join hook.
	             Phase 2 scaffold — sistem inti (DataStore, leaderboard, marketplace,
	             RemoteEvent handler) menyusul di Phase 3+.
	@author      Claude Agent (primary coder)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

print(("%s server start! (v%s)"):format(Constants.GAME_NAME, Constants.VERSION))

local function onPlayerAdded(player: Player)
	print(("Player joined: %s"):format(player.Name))
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
