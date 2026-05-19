--!strict
--[[
	@module      Main
	@description Server entry point + orchestrator. Boot order Phase 3 Minggu 1
	             rev3 (visual polish pass):
	             (1) AtmosphereSetup.apply() — lighting + post-processing first
	                 supaya sebelum prop spawn, screen color grading udah aktif,
	             (2) HubBuilder.build() — terrain Grass real + scattered layered
	                 trees + spawn pad + petromaks lamp,
	             (3) NPCSpawner.spawnAll() — 4 vendor + kiosk decorated tiap NPC,
	             (4) GhostSpawner.spawnAll(getVendorList()) — 4 hantu terbang,
	             (5) AtmosphereSetup.spawnAmbientParticles() — ground mist +
	                 fireflies + petals workspace-level,
	             (6) wire Players.PlayerAdded hook.
	@author      Claude Agent (primary coder)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local serverFolder = ServerScriptService:WaitForChild("Server")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(sharedFolder:WaitForChild("Constants"))
local AtmosphereSetup = require(serverFolder:WaitForChild("AtmosphereSetup"))
local HubBuilder = require(serverFolder:WaitForChild("HubBuilder"))
local NPCSpawner = require(serverFolder:WaitForChild("NPCSpawner"))
local GhostSpawner = require(serverFolder:WaitForChild("GhostSpawner"))

print(("[Main] %s server start! (v%s)"):format(Constants.GAME_NAME, Constants.VERSION))

AtmosphereSetup.apply()
print("[Main] Atmosphere & post-processing applied.")

HubBuilder.build()
print("[Main] Pasar Gaib hub built with terrain grass.")

local vendors = NPCSpawner.spawnAll()
print(("[Main] %d NPC vendor spawned + kiosks decorated."):format(#vendors))

local ghosts = GhostSpawner.spawnAll(NPCSpawner.getVendorList())
print(("[Main] %d ghost companion spawned (flying mode)."):format(#ghosts))

AtmosphereSetup.spawnAmbientParticles()
print("[Main] Ambient particles active.")

print("[Main] Boot complete.")

local function onPlayerAdded(player: Player)
	print(("[Main] Player joined: %s"):format(player.Name))
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
