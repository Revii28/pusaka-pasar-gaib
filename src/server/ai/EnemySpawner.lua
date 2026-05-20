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

function EnemySpawner.assignEnemiesToAllMaps()
	local enemiesFolder = getOrCreateEnemiesFolder()
	local totalSpawned = 0
	local random = Random.new(20260520)

	for _, mapData in ipairs(Constants.MAPS) do
		local spawnList = Constants.ENEMY_SPAWN_MAP[mapData.id]
		if not spawnList then
			continue
		end

		for _, entry in ipairs(spawnList) do
			local moduleScript = findEnemyModule(entry.type)
			if not moduleScript then
				warn(
					("[EnemySpawner] %s: module %s not found, skipped (count=%d)"):format(
						mapData.id,
						entry.type,
						entry.count
					)
				)
				continue
			end

			local ok, enemyModule = pcall(require, moduleScript)
			if not ok then
				warn(
					("[EnemySpawner] %s: require %s failed: %s"):format(
						mapData.id,
						entry.type,
						tostring(enemyModule)
					)
				)
				continue
			end

			local spawnFn = (enemyModule :: any).spawn
			if type(spawnFn) ~= "function" then
				warn(
					("[EnemySpawner] %s: %s.spawn() not a function"):format(mapData.id, entry.type)
				)
				continue
			end

			local mapSpawnCount = 0
			for _ = 1, entry.count do
				local pos = pickSpawnPosition(mapData, random)
				local spawnOk, spawnErr = pcall(spawnFn, pos, enemiesFolder)
				if spawnOk then
					mapSpawnCount += 1
					totalSpawned += 1
				else
					warn(
						("[EnemySpawner] %s: spawn %s failed: %s"):format(
							mapData.id,
							entry.type,
							tostring(spawnErr)
						)
					)
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
