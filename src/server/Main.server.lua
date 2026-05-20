--!strict
--[[
	@module      Main
	@description Server entry point + orchestrator dengan pcall guard di setiap
	             step. Kalau salah satu step throw, langkah berikutnya tetap
	             jalan (gak cascade-fail) dan error di-warn ke Output. Boot
	             order: AtmosphereSetup.apply -> HubBuilder.build ->
	             NPCSpawner.spawnAll -> GhostSpawner.spawnAll(getVendorList) ->
	             AtmosphereSetup.spawnAmbientParticles -> Players hook.
	@author      Claude Agent (primary coder)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local serverFolder = ServerScriptService:WaitForChild("Server")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")

local servicesFolder = serverFolder:WaitForChild("services")
local Constants = require(sharedFolder:WaitForChild("Constants"))
local AtmosphereSetup = require(serverFolder:WaitForChild("AtmosphereSetup"))
local HubBuilder = require(serverFolder:WaitForChild("HubBuilder"))
local NPCSpawner = require(serverFolder:WaitForChild("NPCSpawner"))
local GhostSpawner = require(serverFolder:WaitForChild("GhostSpawner"))
local MapManager = require(servicesFolder:WaitForChild("MapManager"))
local PortalHub = require(servicesFolder:WaitForChild("PortalHub"))
local CombatService = require(servicesFolder:WaitForChild("CombatService"))
local EnemySpawner = require(serverFolder:WaitForChild("ai"):WaitForChild("EnemySpawner"))
local LootService = require(servicesFolder:WaitForChild("LootService"))

local function safeRun(label: string, fn: () -> any, successMsg: string?): any?
	local ok, result = pcall(fn)
	if not ok then
		warn(("[Main] %s FAILED: %s"):format(label, tostring(result)))
		return nil
	end
	if successMsg then
		print(successMsg)
	end
	return result
end

print(("[Main] %s server start! (v%s)"):format(Constants.GAME_NAME, Constants.VERSION))

safeRun(
	"AtmosphereSetup.apply",
	AtmosphereSetup.apply,
	"[Main] Atmosphere & post-processing applied."
)

safeRun("HubBuilder.build", HubBuilder.build, "[Main] Pasar Gaib hub built with terrain grass.")

local vendors = safeRun("NPCSpawner.spawnAll", NPCSpawner.spawnAll) :: { Model }?
if vendors then
	print(("[Main] %d NPC vendor spawned + kiosks decorated."):format(#vendors))
end

local ghosts = safeRun("GhostSpawner.spawnAll", function()
	return GhostSpawner.spawnAll(NPCSpawner.getVendorList())
end) :: { Model }?
if ghosts then
	print(("[Main] %d ghost companion spawned (flying mode)."):format(#ghosts))
end

print("[Main] Building 12 maps...")
safeRun("MapManager.buildAll", MapManager.buildAll, "[Main] Maps ready.")

print("[Main] Spawning 12 portals at hub...")
safeRun("PortalHub.build", PortalHub.build, "[Main] Portal hub ready.")

safeRun(
	"AtmosphereSetup.spawnAmbientParticles",
	AtmosphereSetup.spawnAmbientParticles,
	"[Main] Ambient particles active."
)

print("[Main] Initializing combat...")
safeRun("CombatService.init", CombatService.init, "[Main] Combat M1 ready.")

print("[Main] Initializing loot system...")
safeRun("LootService.init", LootService.init, "[Main] Loot system ready.")

print("[Main] Spawning enemies across 12 maps...")
safeRun(
	"EnemySpawner.assignEnemiesToAllMaps",
	EnemySpawner.assignEnemiesToAllMaps,
	"[Main] Enemies ready."
)

print("[Main] Boot complete.")

local function onPlayerAdded(player: Player)
	print(("[Main] Player joined: %s"):format(player.Name))
	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		hum.MaxHealth = Constants.COMBAT.playerMaxHealth
		hum.Health = Constants.COMBAT.playerMaxHealth
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
