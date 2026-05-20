--!strict
--[[
	@module      NagaKomodo
	@description Legendary boss Pulau Komodo — 3000HP/90dmg. Giant dragon ~30
	             stud length. HOVER mode (Humanoid PlatformStand). FIRE BREATH
	             AoE periodic tiap 8s: 1.5s windup head Y+2, then emit fire
	             ParticleEmitter cone 15 stud forward (rate 200, duration 1s),
	             damage 90 ke all players dalam cone radius. Standard tier
	             onAttack handles melee. HP bar BillboardGui.
	@author      Claude Agent (primary coder)
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local NagaKomodo = {}

local SCALE_COLOR = Color3.fromRGB(40, 80, 40)
local BELLY_COLOR = Color3.fromRGB(120, 140, 80)
local SPIKE_COLOR = Color3.fromRGB(255, 130, 30)
local FIRE_COLOR = Color3.fromRGB(255, 110, 0)
local HOVER_HEIGHT = 4
local FIRE_BREATH_INTERVAL = 8
local FIRE_CONE_LENGTH = 15
local FIRE_CONE_RADIUS = 6

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "NagaKomodo_Boss"
	model:SetAttribute("EnemyType", "NagaKomodo")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(5, 4, 8), model)

	local body = EnemyRigs.makePart({
		name = "Body",
		size = Vector3.new(6, 4, 18),
		color = SCALE_COLOR,
		material = Enum.Material.SmoothPlastic,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, body)

	local belly = EnemyRigs.makePart({
		name = "Belly",
		size = Vector3.new(4, 1, 16),
		color = BELLY_COLOR,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	belly.CFrame = hrp.CFrame * CFrame.new(0, -2, 0)
	EnemyRigs.weld(hrp, belly)

	local head = EnemyRigs.makePart({
		name = "Head",
		size = Vector3.new(4, 3, 5),
		color = SCALE_COLOR,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	head.CFrame = hrp.CFrame * CFrame.new(0, 1, -11)
	EnemyRigs.weld(hrp, head)

	for i, sideX in ipairs({ -0.8, 0.8 }) do
		local horn = EnemyRigs.makePart({
			name = ("Horn%d"):format(i),
			size = Vector3.new(0.5, 3, 0.5),
			color = SPIKE_COLOR,
			material = Enum.Material.Neon,
			parent = model,
		})
		horn.CFrame = head.CFrame * CFrame.new(sideX, 2, 0)
		EnemyRigs.weld(head, horn)
	end

	for i, posSpec in ipairs({
		Vector3.new(-2, -2, 5),
		Vector3.new(2, -2, 5),
		Vector3.new(-2, -2, -5),
		Vector3.new(2, -2, -5),
	}) do
		local leg = EnemyRigs.makePart({
			name = ("Leg%d"):format(i),
			size = Vector3.new(1.5, 4, 1.5),
			color = SCALE_COLOR,
			material = Enum.Material.SmoothPlastic,
			parent = model,
		})
		leg.CFrame = hrp.CFrame * CFrame.new(posSpec.X, posSpec.Y, posSpec.Z)
		EnemyRigs.weld(hrp, leg)
	end

	for i, tailZ in ipairs({ 11, 14, 17 }) do
		local segSize = 3 - (i - 1) * 0.5
		local seg = EnemyRigs.makePart({
			name = ("TailSeg%d"):format(i),
			size = Vector3.new(segSize, 2, 3),
			color = SCALE_COLOR,
			material = Enum.Material.SmoothPlastic,
			parent = model,
		})
		seg.CFrame = hrp.CFrame * CFrame.new(0, 0, tailZ)
		EnemyRigs.weld(hrp, seg)
	end

	for i = 1, 10 do
		local spike = EnemyRigs.makePart({
			name = ("Spike%d"):format(i),
			size = Vector3.new(0.5, 1, 0.5),
			color = SPIKE_COLOR,
			material = Enum.Material.Neon,
			parent = model,
		})
		spike.CFrame = hrp.CFrame * CFrame.new(0, 2.5, -8 + (i - 1) * 2)
		EnemyRigs.weld(hrp, spike)
	end

	local hum = EnemyRigs.makeHumanoid(model, "Naga Komodo")
	hum.PlatformStand = true

	return EnemyRigs.finalize(model, hrp, spawnPos + Vector3.new(0, HOVER_HEIGHT, 0))
end

local function fireBreathCone(headPart: BasePart, damage: number)
	local origin = headPart.Position
	local forward = -headPart.CFrame.LookVector
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "FireBreath"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 100)),
		ColorSequenceKeypoint.new(0.5, FIRE_COLOR),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 30, 20)),
	})
	emitter.Lifetime = NumberRange.new(0.8)
	emitter.Rate = 200
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 4),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Speed = NumberRange.new(20, 30)
	emitter.LightEmission = 1
	emitter.SpreadAngle = Vector2.new(20, 20)
	emitter.EmissionDirection = Enum.NormalId.Front
	emitter.Parent = headPart

	task.delay(1, function()
		emitter.Enabled = false
		Debris:AddItem(emitter, 1)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local pHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if pHrp then
				local toPlayer = pHrp.Position - origin
				local dist = toPlayer.Magnitude
				if dist <= FIRE_CONE_LENGTH then
					local dot = forward:Dot(toPlayer.Unit)
					if dot > 0.7 and math.abs(toPlayer.Y) < FIRE_CONE_RADIUS then
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum then
							hum:TakeDamage(damage)
						end
					end
				end
			end
		end
	end
end

local function startFireBreathLoop(model: Model)
	task.spawn(function()
		while model.Parent do
			task.wait(FIRE_BREATH_INTERVAL)
			if not model.Parent then
				break
			end
			local head = model:FindFirstChild("Head") :: BasePart?
			local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not head or not hrp then
				continue
			end
			local origCFrame = head.CFrame
			head.Anchored = true
			TweenService:Create(
				head,
				TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = origCFrame * CFrame.new(0, 2, 0) }
			):Play()
			task.wait(1.5)
			fireBreathCone(head, 90)
			task.wait(0.5)
			head.CFrame = origCFrame
			head.Anchored = false
		end
	end)
end

function NagaKomodo.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = buildRig(spawnPos)
	model.Parent = parent
	EnemyRigs.attachBossHealthBar(model, "Naga Komodo")
	EnemyAI.attach(model, {
		tier = "Legendary",
		spawnPos = spawnPos + Vector3.new(0, HOVER_HEIGHT, 0),
		patrolRadius = 50,
	})
	startFireBreathLoop(model)
	return model
end

return NagaKomodo
