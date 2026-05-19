--!strict
--[[
	@module      Main
	@description Server entry point + orchestrator. Boot order:
	             (1) destroy default Baseplate & build PasarGaibHub via HubBuilder,
	             (2) spawn 4 NPC vendor via NPCSpawner,
	             (3) wire Players.PlayerAdded hook.
	             Phase 3 Minggu 1 scaffold.
	@author      Claude Agent (primary coder)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local serverFolder = ServerScriptService:WaitForChild("Server")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(sharedFolder:WaitForChild("Constants"))
local HubBuilder = require(serverFolder:WaitForChild("HubBuilder"))
local NPCSpawner = require(serverFolder:WaitForChild("NPCSpawner"))

print(("[Main] %s server start! (v%s)"):format(Constants.GAME_NAME, Constants.VERSION))

HubBuilder.build()
print("[Main] Pasar Gaib hub built.")

local vendors = NPCSpawner.spawnAll()
print(("[Main] %d NPC vendor spawned."):format(#vendors))

print("[Main] Boot complete.")

local function onPlayerAdded(player: Player)
	print(("[Main] Player joined: %s"):format(player.Name))
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
