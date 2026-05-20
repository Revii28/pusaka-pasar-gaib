--!strict
--[[
	@module      GauntletService
	@description Orchestrator gauntlet untuk 6 boss map. buildGauntlet(mapName,
	             mapOffset): iterate GauntletConfig[mapName].rooms, panggil
	             ParkourRoomBuilder per room (parkour + combat platform), spawn
	             gate locked di entry next room. Boss arena di end + boss gate.
	             notifyEnemyKilled(mapName, roomTier): decrement counter, kalau
	             nol → unlock gate next room. registerEnemySpawn untuk track
	             initial enemy count. State per server instance — restart =
	             reset (MVP acceptable).
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GauntletConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GauntletConfig"))
local ParkourRoomBuilder = require(script.Parent:WaitForChild("ParkourRoomBuilder"))
local GateTeleporter = require(script.Parent:WaitForChild("GateTeleporter"))

local GauntletService = {}

type GauntletState = {
	mapName: string,
	mapOffset: Vector3,
	config: GauntletConfig.MapGauntletConfig,
	enemiesAlive: { number },
	gates: { [any]: Part },
}

local activeGauntlets: { [string]: GauntletState } = {}

local GATE_OFFSET_PAST_COMBAT = 30

function GauntletService.buildGauntlet(mapName: string, mapOffset: Vector3)
	local config = GauntletConfig[mapName]
	if not config then
		warn(("[GauntletService] No config for map: %s"):format(mapName))
		return
	end

	local state: GauntletState = {
		mapName = mapName,
		mapOffset = mapOffset,
		config = config,
		enemiesAlive = { 0, 0, 0, 0 },
		gates = {},
	}

	for _, roomDef in ipairs(config.rooms) do
		local parkourPos = mapOffset + roomDef.parkourOffset
		local combatPos = mapOffset + roomDef.combatOffset

		ParkourRoomBuilder.buildParkour(config.theme, parkourPos, roomDef.id)
		ParkourRoomBuilder.buildCombatPlatform(config.theme, combatPos, roomDef.id)

		local gatePos = mapOffset
			+ Vector3.new(0, 0, roomDef.combatOffset.Z + GATE_OFFSET_PAST_COMBAT)
		state.gates[roomDef.id] = GateTeleporter.spawnGate(gatePos, roomDef.id, false)
	end

	local bossPos = mapOffset + config.bossOffset
	ParkourRoomBuilder.buildBossArena(config.theme, bossPos)

	local bossGatePos = mapOffset + Vector3.new(0, 0, config.bossOffset.Z - GATE_OFFSET_PAST_COMBAT)
	state.gates["boss"] = GateTeleporter.spawnGate(bossGatePos, "boss", false)

	activeGauntlets[mapName] = state
	print(("[GauntletService] Built gauntlet for %s (theme=%s)"):format(mapName, config.theme))
end

function GauntletService.registerEnemySpawn(mapName: string, roomTier: number)
	local state = activeGauntlets[mapName]
	if not state then
		return
	end
	state.enemiesAlive[roomTier] = (state.enemiesAlive[roomTier] or 0) + 1
end

function GauntletService.notifyEnemyKilled(mapName: string, roomTier: number)
	local state = activeGauntlets[mapName]
	if not state then
		return
	end
	state.enemiesAlive[roomTier] = math.max(0, state.enemiesAlive[roomTier] - 1)
	if state.enemiesAlive[roomTier] == 0 then
		local gateKey: any = if roomTier == 4 then "boss" else roomTier
		GateTeleporter.unlock(state.gates[gateKey])
		print(("[GauntletService] %s Room %d cleared → gate unlocked"):format(mapName, roomTier))
	end
end

function GauntletService.getMapConfig(mapName: string): GauntletConfig.MapGauntletConfig?
	return GauntletConfig[mapName]
end

function GauntletService.getState(mapName: string): GauntletState?
	return activeGauntlets[mapName]
end

function GauntletService.init()
	print("[GauntletService] Ready (gauntlet config loaded).")
end

return GauntletService
