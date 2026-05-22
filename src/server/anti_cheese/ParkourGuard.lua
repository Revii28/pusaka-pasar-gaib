--!strict
--[[
	@module      ParkourGuard
	@description Server-side movement anti-cheese. Per-player Heartbeat sampler
	             (throttled) detects teleport / speed / fly / out-of-bounds and
	             escalates: (1) rubberband to a recent safe pos, (2) teleport to
	             spawn, (3) kick. Portal-aware: PortalService calls
	             notifyLegitTeleport() so legitimate map travel isn't flagged.
	             Config constants at top for easy tuning.
	@author      Claude Agent (primary coder)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ParkourGuard = {}

local POSITION_SAMPLE_INTERVAL = 1.0 -- seconds between samples
local SPEED_THRESHOLD = 100 -- stud/s sustained (2+ samples)
local TELEPORT_DELTA_THRESHOLD = 75 -- stud per single sample = instant TP
local FLY_HEIGHT_THRESHOLD = 50 -- stud above last grounded Y
local FLY_SUSTAINED_DURATION = 2.0 -- seconds airborne above threshold w/o jump
local OUT_OF_BOUNDS_Y_MIN = -500
local OUT_OF_BOUNDS_XZ_ABS = 5000
local SAFE_HISTORY_LEN = 5
local LEGIT_TELEPORT_WINDOW = 2.0 -- whitelist seconds after notifyLegitTeleport

type GuardState = {
	lastPos: Vector3,
	lastGroundedY: number,
	safePosHistory: { Vector3 },
	inAirSince: number?,
	didJump: boolean,
	speedStrikes: number,
	violations: number,
	legitTeleportUntil: number,
	accum: number,
	heartbeatConn: RBXScriptConnection?,
	jumpConn: RBXScriptConnection?,
}

local stateByPlayer: { [Player]: GuardState } = {}

local function getHRP(player: Player): BasePart?
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function handleViolation(player: Player, state: GuardState, vtype: string)
	state.violations += 1
	local v = state.violations
	local hrp = getHRP(player)

	if v == 1 then
		print(("[ParkourGuard] Player %s violation 1: %s"):format(player.Name, vtype))
		if hrp then
			local safe = state.safePosHistory[1] or state.lastPos
			hrp.CFrame = CFrame.new(safe)
		end
	elseif v == 2 then
		print(("[ParkourGuard] Player %s violation 2: %s"):format(player.Name, vtype))
		if hrp then
			local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
			hrp.CFrame = if spawn then spawn.CFrame + Vector3.new(0, 3, 0) else CFrame.new(0, 10, 0)
		end
	else
		print(("[ParkourGuard] Player %s violation 3: %s, KICKING"):format(player.Name, vtype))
		player:Kick("Detected anomalous movement pattern. Contact support if this was a mistake.")
	end
end

local function sample(player: Player, state: GuardState)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return
	end
	local pos = hrp.Position

	-- Whitelist window after a legitimate teleport (portal/respawn).
	if state.legitTeleportUntil > tick() then
		state.lastPos = pos
		state.lastGroundedY = pos.Y
		state.inAirSince = nil
		state.speedStrikes = 0
		return
	end

	-- Out-of-bounds.
	if
		pos.Y < OUT_OF_BOUNDS_Y_MIN
		or math.abs(pos.X) > OUT_OF_BOUNDS_XZ_ABS
		or math.abs(pos.Z) > OUT_OF_BOUNDS_XZ_ABS
	then
		handleViolation(player, state, "bounds")
		state.lastPos = pos
		return
	end

	local delta = (pos - state.lastPos).Magnitude

	-- Instant teleport (single-sample jump).
	if delta > TELEPORT_DELTA_THRESHOLD then
		handleViolation(player, state, "teleport")
		state.lastPos = pos
		state.speedStrikes = 0
		return
	end

	-- Sustained speed (2+ consecutive samples over threshold).
	if delta / POSITION_SAMPLE_INTERVAL > SPEED_THRESHOLD then
		state.speedStrikes += 1
		if state.speedStrikes >= 2 then
			handleViolation(player, state, "speed")
			state.speedStrikes = 0
			state.lastPos = pos
			return
		end
	else
		state.speedStrikes = 0
	end

	-- Fly: airborne above last grounded Y by threshold, sustained, no jump arc.
	local grounded = hum.FloorMaterial ~= Enum.Material.Air
	if grounded then
		state.lastGroundedY = pos.Y
		state.inAirSince = nil
		state.didJump = false
	else
		if state.inAirSince == nil then
			state.inAirSince = tick()
		end
		if
			pos.Y > state.lastGroundedY + FLY_HEIGHT_THRESHOLD
			and (tick() - (state.inAirSince :: number)) >= FLY_SUSTAINED_DURATION
			and not state.didJump
		then
			handleViolation(player, state, "fly")
			state.lastPos = pos
			return
		end
	end

	-- Record safe position (ring buffer).
	table.insert(state.safePosHistory, pos)
	if #state.safePosHistory > SAFE_HISTORY_LEN then
		table.remove(state.safePosHistory, 1)
	end
	state.lastPos = pos
end

function ParkourGuard.start(player: Player)
	ParkourGuard.stop(player)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return
	end

	local state: GuardState = {
		lastPos = hrp.Position,
		lastGroundedY = hrp.Position.Y,
		safePosHistory = { hrp.Position },
		inAirSince = nil,
		didJump = false,
		speedStrikes = 0,
		violations = 0,
		legitTeleportUntil = tick() + LEGIT_TELEPORT_WINDOW, -- grace on spawn
		accum = 0,
		heartbeatConn = nil,
		jumpConn = nil,
	}
	stateByPlayer[player] = state

	state.jumpConn = hum.Jumping:Connect(function(active: boolean)
		if active then
			state.didJump = true
		end
	end)

	state.heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		state.accum += dt
		if state.accum < POSITION_SAMPLE_INTERVAL then
			return
		end
		state.accum = 0
		local ok, err = pcall(sample, player, state)
		if not ok then
			warn(("[ParkourGuard] sample error for %s: %s"):format(player.Name, tostring(err)))
		end
	end)
end

function ParkourGuard.stop(player: Player)
	local state = stateByPlayer[player]
	if not state then
		return
	end
	if state.heartbeatConn then
		state.heartbeatConn:Disconnect()
	end
	if state.jumpConn then
		state.jumpConn:Disconnect()
	end
	stateByPlayer[player] = nil
end

function ParkourGuard.notifyLegitTeleport(player: Player, durationOverride: number?)
	local state = stateByPlayer[player]
	if not state then
		return
	end
	state.legitTeleportUntil = tick() + (durationOverride or LEGIT_TELEPORT_WINDOW)
end

function ParkourGuard.resetViolations(player: Player)
	local state = stateByPlayer[player]
	if state then
		state.violations = 0
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	ParkourGuard.stop(player)
end)

return ParkourGuard
