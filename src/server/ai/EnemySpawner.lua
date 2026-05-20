--!strict
--[[
	@module      EnemySpawner
	@description Orchestrator buat spawn enemy across 12 maps. Iterate
	             Constants.ENEMY_SPAWN_MAP, untuk tiap (mapId, [{type, count}]),
	             require src/server/ai/enemies/<type>.lua, panggil
	             enemyModule.spawn(pos, enemiesFolder) sebanyak count kali.
	             Missing module di-warn dan skipped (graceful degradation —
	             enemy modules ditambahin progressive across commit 2-5).
	             Random scatter pos dalam radius 30..120 dari mapData.offset.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local GauntletConfig =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GauntletConfig"))
local GauntletService = require(
	ServerScriptService:WaitForChild("Server")
		:WaitForChild("gauntlet")
		:WaitForChild("GauntletService")
)

local EnemySpawner = {}

local ENEMIES_FOLDER_NAME = "Enemies"

local function getOrCreateEnemiesFolder(): Folder
	local existing = workspace:FindFirstChild(ENEMIES_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = ENEMIES_FOLDER_NAME
	folder.Parent = workspace
	return folder
end

local function findEnemyModule(enemyType: string): ModuleScript?
	local enemiesFolder =
		ServerScriptService:WaitForChild("Server"):WaitForChild("ai"):WaitForChild("enemies")
	local module = enemiesFolder:FindFirstChild(enemyType)
	if module and module:IsA("ModuleScript") then
		return module
	end
	return nil
end

local function pickSpawnPosition(mapData: Constants.MapData, random: Random): Vector3
	local angle = random:NextNumber() * 2 * math.pi
	local maxR = math.min(mapData.size.X / 2 - 30, 120)
	local r = random:NextNumber(30, math.max(40, maxR))
	return Vector3.new(
		mapData.offset.X + math.sin(angle) * r,
		mapData.offset.Y + 3,
		mapData.offset.Z + math.cos(angle) * r
	)
end

local function tagEnemyForGauntlet(
	enemyModel: Instance,
	mapName: string,
	roomTier: number,
	dropMultiplier: number
)
	if not enemyModel:IsA("Model") then
		return
	end
	enemyModel:SetAttribute("GauntletMap", mapName)
	enemyModel:SetAttribute("RoomTier", roomTier)
	enemyModel:SetAttribute("DropMultiplier", dropMultiplier)
	GauntletService.registerEnemySpawn(mapName, roomTier)
end

local function spawnEnemyInstance(
	enemyType: string,
	enemiesFolder: Folder,
	pos: Vector3,
	gauntletTag: { mapName: string, roomTier: number, dropMultiplier: number }?
): boolean
	local moduleScript = findEnemyModule(enemyType)
	if not moduleScript then
		return false
	end
	local ok, enemyModule = pcall(require, moduleScript)
	if not ok then
		warn(("[EnemySpawner] require %s failed: %s"):format(enemyType, tostring(enemyModule)))
		return false
	end
	local spawnFn = (enemyModule :: any).spawn
	if type(spawnFn) ~= "function" then
		return false
	end

	-- Snapshot enemiesFolder children count to identify the new spawn for tagging.
	local before: { [Instance]: boolean } = {}
	for _, child in ipairs(enemiesFolder:GetChildren()) do
		before[child] = true
	end

	local spawnOk, spawnErr = pcall(spawnFn, pos, enemiesFolder)
	if not spawnOk then
		warn(("[EnemySpawner] spawn %s failed: %s"):format(enemyType, tostring(spawnErr)))
		return false
	end

	if gauntletTag then
		for _, child in ipairs(enemiesFolder:GetChildren()) do
			if not before[child] then
				tagEnemyForGauntlet(
					child,
					gauntletTag.mapName,
					gauntletTag.roomTier,
					gauntletTag.dropMultiplier
				)
			end
		end
	end
	return true
end

local function spawnGauntletEnemies(
	mapData: Constants.MapData,
	gauntletDef: GauntletConfig.MapGauntletConfig,
	enemiesFolder: Folder,
	random: Random
): number
	local total = 0
	for _, room in ipairs(gauntletDef.rooms) do
		local combatPos = mapData.offset + room.combatOffset
		for _, entry in ipairs(room.enemies) do
			for _ = 1, entry.count do
				local jitterX = random:NextNumber(-6, 6)
				local jitterZ = random:NextNumber(-6, 6)
				local pos = combatPos + Vector3.new(jitterX, 3, jitterZ)
				if
					spawnEnemyInstance(entry.type, enemiesFolder, pos, {
						mapName = mapData.id,
						roomTier = room.id,
						dropMultiplier = room.dropMultiplier,
					})
				then
					total += 1
				end
			end
		end
		print(
			("[EnemySpawner] %s Room %d: enemies spawned (x%.1f drop)"):format(
				mapData.id,
				room.id,
				room.dropMultiplier
			)
		)
	end

	-- Boss
	local bossPos = mapData.offset + gauntletDef.bossOffset + Vector3.new(0, 4, 0)
	for _ = 1, gauntletDef.bossEnemy.count do
		if
			spawnEnemyInstance(gauntletDef.bossEnemy.type, enemiesFolder, bossPos, {
				mapName = mapData.id,
				roomTier = 4,
				dropMultiplier = gauntletDef.bossDropMultiplier,
			})
		then
			total += 1
		end
	end
	if gauntletDef.bossEnemy.minions then
		for _, minion in ipairs(gauntletDef.bossEnemy.minions) do
			for _ = 1, minion.count do
				local pos = bossPos
					+ Vector3.new(random:NextNumber(-8, 8), 0, random:NextNumber(-8, 8))
				if
					spawnEnemyInstance(minion.type, enemiesFolder, pos, {
						mapName = mapData.id,
						roomTier = 4,
						dropMultiplier = gauntletDef.bossDropMultiplier,
					})
				then
					total += 1
				end
			end
		end
	end
	print(
		("[EnemySpawner] %s Boss arena: enemies spawned (x%.1f drop)"):format(
			mapData.id,
			gauntletDef.bossDropMultiplier
		)
	)
	return total
end

function EnemySpawner.assignEnemiesToAllMaps()
	local enemiesFolder = getOrCreateEnemiesFolder()
	local totalSpawned = 0
	local random = Random.new(20260520)

	for _, mapData in ipairs(Constants.MAPS) do
		local gauntletDef = GauntletConfig[mapData.id]
		if gauntletDef then
			-- Gauntlet map: spawn per-room (NOT center-of-map default)
			local count = spawnGauntletEnemies(mapData, gauntletDef, enemiesFolder, random)
			totalSpawned += count
			print(
				("[EnemySpawner] %s (gauntlet): %d total enemies spawned."):format(
					mapData.id,
					count
				)
			)
			continue
		end

		-- Non-gauntlet maps: legacy center-of-map scatter from ENEMY_SPAWN_MAP
		local spawnList = Constants.ENEMY_SPAWN_MAP[mapData.id]
		if not spawnList then
			continue
		end

		for _, entry in ipairs(spawnList) do
			local mapSpawnCount = 0
			for _ = 1, entry.count do
				local pos = pickSpawnPosition(mapData, random)
				if spawnEnemyInstance(entry.type, enemiesFolder, pos, nil) then
					mapSpawnCount += 1
					totalSpawned += 1
				end
			end
			print(
				("[EnemySpawner] %s: %d %s spawned."):format(mapData.id, mapSpawnCount, entry.type)
			)
		end
	end

	print(("[EnemySpawner] All map enemies assigned (total %d)."):format(totalSpawned))
end

return EnemySpawner
