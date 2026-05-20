--!strict
--[[
	@module      CombatService
	@description Server-side M1 melee handler. Listen RemoteEvent "CombatM1" dari
	             client (LMB pressed), enforce cooldown per-player (anti-spam),
	             scan nearest enemy dalam Constants.COMBAT.m1Range, panggil
	             Humanoid:TakeDamage(m1Damage). Increment kill counter per-player
	             per-enemyType in-memory (datastore Phase 4+). Workspace.Enemies
	             folder = single source of truth buat scan target.
	@author      Claude Agent (primary coder)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local CombatService = {}

local playerCooldowns: { [number]: number } = {}
local killCounts: { [number]: { [string]: number } } = {}

local function findNearestEnemyInRange(
	playerPos: Vector3,
	range: number
): (Model?, Humanoid?, number)
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		return nil, nil, math.huge
	end

	local nearestModel: Model? = nil
	local nearestHum: Humanoid? = nil
	local nearestDist = math.huge

	for _, child in ipairs(enemiesFolder:GetChildren()) do
		if child:IsA("Model") then
			local hum = child:FindFirstChildOfClass("Humanoid")
			local hrp = child:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hum and hrp and hum.Health > 0 then
				local d = (hrp.Position - playerPos).Magnitude
				if d <= range and d < nearestDist then
					nearestModel = child
					nearestHum = hum
					nearestDist = d
				end
			end
		end
	end

	return nearestModel, nearestHum, nearestDist
end

function CombatService.handleM1(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local playerHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not playerHrp then
		return
	end

	local now = os.clock()
	local last = playerCooldowns[player.UserId] or 0
	if now - last < Constants.COMBAT.m1Cooldown then
		return
	end
	playerCooldowns[player.UserId] = now

	local enemyModel, enemyHum =
		findNearestEnemyInRange(playerHrp.Position, Constants.COMBAT.m1Range)
	if not enemyModel or not enemyHum then
		return
	end

	enemyHum:TakeDamage(Constants.COMBAT.m1Damage)
	local enemyType = (enemyModel:GetAttribute("EnemyType") or "Unknown") :: string
	print(
		("[CombatService] %s hit %s (-%d HP, remaining %d)"):format(
			player.Name,
			enemyType,
			Constants.COMBAT.m1Damage,
			math.floor(enemyHum.Health)
		)
	)

	if enemyHum.Health <= 0 then
		killCounts[player.UserId] = killCounts[player.UserId] or {}
		local userKills = killCounts[player.UserId]
		userKills[enemyType] = (userKills[enemyType] or 0) + 1
		print(
			("[CombatService] %s killed %s! Total %s: %d"):format(
				player.Name,
				enemyType,
				enemyType,
				userKills[enemyType]
			)
		)
	end
end

function CombatService.getKillCount(player: Player, enemyType: string): number
	local userKills = killCounts[player.UserId]
	if not userKills then
		return 0
	end
	return userKills[enemyType] or 0
end

function CombatService.init()
	Players.PlayerRemoving:Connect(function(player)
		playerCooldowns[player.UserId] = nil
		killCounts[player.UserId] = nil
	end)

	local remote = Remotes.get("CombatM1")
	remote.OnServerEvent:Connect(function(player)
		CombatService.handleM1(player)
	end)
	-- Pre-create EnemyKilled remote so client scripts can subscribe at boot
	Remotes.get("EnemyKilled")
	print(
		("[CombatService] M1 remote listening, cooldown %.2fs, range %d, damage %d."):format(
			Constants.COMBAT.m1Cooldown,
			Constants.COMBAT.m1Range,
			Constants.COMBAT.m1Damage
		)
	)
end

return CombatService
