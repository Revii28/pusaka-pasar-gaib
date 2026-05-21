--!strict
--[[
	@module      EnemyAI
	@description Generic FSM template buat enemy. States: IDLE → PATROL → CHASE →
	             ATTACK → DEATH. Enemy module call EnemyAI.attach(model, config)
	             setelah build rig + Humanoid + HumanoidRootPart. Config supply
	             tier (lookup Constants.ENEMY_TIERS), spawnPos (patrol anchor),
	             optional onAttack/onDeath callbacks buat custom behavior
	             (e.g., projectile, AoE, summon minion).
	@author      Claude Agent (primary coder)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local ENEMY_KILLED_BINDABLE = Remotes.getBindable("EnemyKilled")

local EnemyAI = {}

export type EnemyAIConfig = {
	tier: string,
	spawnPos: Vector3,
	patrolRadius: number?,
	onAttack: ((Player, number) -> ())?,
	onDeath: (() -> ())?,
}

export type EnemyAIState = {
	current: string,
	attackTarget: Player?,
	patrolTarget: Vector3?,
	lastAttackTime: number,
	lastIdleTime: number,
	idleDuration: number,
	spawnPos: Vector3,
	patrolRadius: number,
	tier: Constants.EnemyTierStats,
}

local STATE_IDLE = "IDLE"
local STATE_PATROL = "PATROL"
local STATE_CHASE = "CHASE"
local STATE_ATTACK = "ATTACK"
local STATE_DEATH = "DEATH"

local TICK_INTERVAL = 0.15
local FADE_TIME = 2

function EnemyAI.findNearestPlayer(origin: Vector3, maxRange: number): (Player?, number)
	local nearest: Player? = nil
	local nearestDist = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local d = (hrp.Position - origin).Magnitude
				if d < maxRange and d < nearestDist then
					nearest = player
					nearestDist = d
				end
			end
		end
	end
	return nearest, nearestDist
end

local function pickPatrolPoint(state: EnemyAIState): Vector3
	local angle = math.random() * math.pi * 2
	local r = math.random() * state.patrolRadius
	return state.spawnPos + Vector3.new(math.sin(angle) * r, 0, math.cos(angle) * r)
end

local function applyDamage(config: EnemyAIConfig, target: Player, damage: number)
	if config.onAttack then
		config.onAttack(target, damage)
		return
	end
	local char = target.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:TakeDamage(damage)
	end
end

local function fadeAndDestroy(model: Model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			TweenService:Create(p, TweenInfo.new(FADE_TIME), { Transparency = 1 }):Play()
		end
	end
	task.wait(FADE_TIME)
	model:Destroy()
end

local function tick(model: Model, state: EnemyAIState, config: EnemyAIConfig)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return
	end

	local origin = hrp.Position
	-- Per-enemy locomotion speed scale (set by EnemyRigs.apply*Locomotion).
	local speedMult = (model:GetAttribute("SpeedMultiplier") or 1) :: number
	local nearestPlayer, nearestDist = EnemyAI.findNearestPlayer(origin, state.tier.detectRange * 2)

	if state.current == STATE_IDLE then
		if os.clock() - state.lastIdleTime >= state.idleDuration then
			state.current = STATE_PATROL
			state.patrolTarget = nil
		end
		return
	end

	if state.current == STATE_PATROL then
		hum.WalkSpeed = state.tier.walkSpeed * speedMult
		if nearestPlayer and nearestDist <= state.tier.detectRange then
			state.current = STATE_CHASE
			state.attackTarget = nearestPlayer
			return
		end
		if not state.patrolTarget or (origin - state.patrolTarget).Magnitude < 3 then
			state.patrolTarget = pickPatrolPoint(state)
		end
		hum:MoveTo(state.patrolTarget :: Vector3)
		return
	end

	if state.current == STATE_CHASE then
		hum.WalkSpeed = state.tier.chaseSpeed * speedMult
		if not nearestPlayer or nearestDist > state.tier.detectRange * 1.5 then
			state.current = STATE_PATROL
			state.attackTarget = nil
			state.patrolTarget = nil
			return
		end
		state.attackTarget = nearestPlayer
		if nearestDist <= state.tier.attackRange then
			state.current = STATE_ATTACK
			return
		end
		local target = nearestPlayer.Character
		if target then
			local targetHrp = target:FindFirstChild("HumanoidRootPart") :: BasePart?
			if targetHrp then
				hum:MoveTo(targetHrp.Position)
			end
		end
		return
	end

	if state.current == STATE_ATTACK then
		local target = state.attackTarget
		if not target or not target.Character then
			state.current = STATE_PATROL
			return
		end
		local targetHrp = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not targetHrp then
			state.current = STATE_PATROL
			return
		end
		local d = (targetHrp.Position - origin).Magnitude
		if d > state.tier.attackRange then
			state.current = STATE_CHASE
			return
		end
		local now = os.clock()
		if now - state.lastAttackTime >= state.tier.attackCooldown then
			state.lastAttackTime = now
			applyDamage(config, target, state.tier.damage)
		end
		return
	end
end

function EnemyAI.attach(model: Model, config: EnemyAIConfig): EnemyAIState
	local tier = Constants.ENEMY_TIERS[config.tier]
	assert(tier, ("[EnemyAI] Unknown tier: %s"):format(tostring(config.tier)))

	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then
		hum = Instance.new("Humanoid")
		hum.Parent = model
	end
	hum.MaxHealth = tier.hp
	hum.Health = tier.hp
	hum.WalkSpeed = tier.walkSpeed
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer

	local state: EnemyAIState = {
		current = STATE_IDLE,
		attackTarget = nil,
		patrolTarget = nil,
		lastAttackTime = 0,
		lastIdleTime = os.clock(),
		idleDuration = math.random(2, 4),
		spawnPos = config.spawnPos,
		patrolRadius = config.patrolRadius or 30,
		tier = tier,
	}

	task.spawn(function()
		while hum.Health > 0 and model.Parent do
			task.wait(TICK_INTERVAL)
			local ok, err = pcall(tick, model, state, config)
			if not ok then
				warn(("[EnemyAI] Tick error on %s: %s"):format(model.Name, tostring(err)))
			end
		end
		state.current = STATE_DEATH
		if config.onDeath then
			config.onDeath()
		end
		local enemyType = model:GetAttribute("EnemyType")
		local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local position = if hrp then hrp.Position else model:GetPivot().Position
		local killerUserId = model:GetAttribute("LastAttackerUserId") :: number?
		local killer: Player? = if killerUserId
			then Players:GetPlayerByUserId(killerUserId)
			else nil
		local dropMultiplier = (model:GetAttribute("DropMultiplier") or 1.0) :: number
		local gauntletMap = model:GetAttribute("GauntletMap") :: string?
		local roomTier = model:GetAttribute("RoomTier") :: number?

		ENEMY_KILLED_BINDABLE:Fire(killer, enemyType, position, dropMultiplier)
		Remotes.get("EnemyKilled"):FireAllClients(model.Name, enemyType)

		-- Notify gauntlet kalau enemy belong to gauntlet map → unlock gate
		-- saat room cleared.
		if gauntletMap and roomTier then
			local serverFolder = game:GetService("ServerScriptService"):FindFirstChild("Server")
			local gauntletFolder = serverFolder and serverFolder:FindFirstChild("gauntlet")
			local serviceMS = gauntletFolder and gauntletFolder:FindFirstChild("GauntletService")
			if serviceMS then
				local ok, GauntletService = pcall(require, serviceMS)
				if ok then
					pcall(function()
						(GauntletService :: any).notifyEnemyKilled(gauntletMap, roomTier)
					end)
				end
			end
		end

		fadeAndDestroy(model)
	end)

	return state
end

return EnemyAI
