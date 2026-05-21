--!strict
--[[
	@module      BuddhaWraith
	@description Legendary raid boss Borobudur Bawah Tanah — 3000HP/90dmg.
	             Floating Buddha statue ghost ~10 stud. TELEPORT + AoE NOVA tiap
	             10s: pcall HRP CFrame jump to random pos 15 stud away (visual
	             shatter Neon gold particle 0.3s), kemudian release AoE nova
	             ring expand outward radius 20 in 1s (Cylinder Part Neon
	             expanding), damage 90 ke all players dalam ring expansion.
	             Stationary lotus pose antara teleport. PlatformStand true.
	@author      Claude Agent (primary coder)
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local BuddhaWraith = {}

local GOLD_COLOR = Color3.fromRGB(220, 180, 70)
local NOVA_COLOR = Color3.fromRGB(255, 220, 120)
local HALO_COLOR = Color3.fromRGB(255, 240, 150)
local OFFERING_COLOR = Color3.fromRGB(250, 250, 250)
local TELEPORT_INTERVAL = 10
local TELEPORT_RANGE = 15
local NOVA_RADIUS = 20

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "BuddhaWraith_Boss"
	model:SetAttribute("EnemyType", "BuddhaWraith")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(3, 8, 3), model)

	local body = EnemyRigs.makePart({
		name = "Body",
		size = Vector3.new(4, 8, 3),
		color = GOLD_COLOR,
		material = Enum.Material.Neon,
		transparency = 0.25,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, body)

	local head = EnemyRigs.makePart({
		name = "Head",
		size = Vector3.new(2.5, 2.5, 2.5),
		color = GOLD_COLOR,
		material = Enum.Material.Neon,
		transparency = 0.25,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	head.CFrame = hrp.CFrame * CFrame.new(0, 5, 0)
	EnemyRigs.weld(hrp, head)

	local halo = Instance.new("Part")
	halo.Name = "Halo"
	halo.Shape = Enum.PartType.Cylinder
	halo.Size = Vector3.new(0.3, 6, 6)
	halo.CFrame = hrp.CFrame * CFrame.new(0, 5, 0.5) * CFrame.Angles(0, 0, math.rad(90))
	halo.Anchored = false
	halo.CanCollide = false
	halo.Massless = true
	halo.Material = Enum.Material.Neon
	halo.Color = HALO_COLOR
	halo.Transparency = 0.4
	halo.Parent = model
	EnemyRigs.weld(hrp, halo)

	for i = 1, 6 do
		local angle = ((i - 1) / 6) * 2 * math.pi
		local arm = EnemyRigs.makePart({
			name = ("Arm%d"):format(i),
			size = Vector3.new(0.5, 4, 0.5),
			color = GOLD_COLOR,
			material = Enum.Material.Neon,
			transparency = 0.4,
			parent = model,
		})
		arm.CFrame = hrp.CFrame
			* CFrame.new(math.cos(angle) * 2.5, 0, math.sin(angle) * 2.5)
			* CFrame.Angles(0, angle, math.rad(30))
		EnemyRigs.weld(hrp, arm)
	end

	for i = 1, 3 do
		local angle = ((i - 1) / 3) * 2 * math.pi
		local offering = EnemyRigs.makePart({
			name = ("Offering%d"):format(i),
			size = Vector3.new(0.5, 0.5, 0.5),
			color = OFFERING_COLOR,
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			parent = model,
		})
		offering.CFrame = hrp.CFrame * CFrame.new(math.cos(angle) * 5, 3, math.sin(angle) * 5)
		EnemyRigs.weld(hrp, offering)
	end

	local aura = Instance.new("PointLight")
	aura.Color = GOLD_COLOR
	aura.Brightness = 8
	aura.Range = 35
	aura.Parent = body

	local hum = EnemyRigs.makeHumanoid(model, "Buddha Wraith")
	hum.PlatformStand = true

	return EnemyRigs.finalize(model, hrp, spawnPos + Vector3.new(0, 4, 0))
end

local function novaRingDamage(origin: Vector3, damage: number)
	local ring = Instance.new("Part")
	ring.Name = "BuddhaNova"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.5, 2, 2)
	ring.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = NOVA_COLOR
	ring.Transparency = 0.2
	ring.Parent = workspace

	TweenService:Create(ring, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.5, NOVA_RADIUS * 2, NOVA_RADIUS * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 1.2)

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local pHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if pHrp and (pHrp.Position - origin).Magnitude <= NOVA_RADIUS then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(damage)
				end
			end
		end
	end
end

local function teleportShatter(pos: Vector3)
	local burst = Instance.new("Part")
	burst.Name = "TeleportBurst"
	burst.Size = Vector3.new(1, 1, 1)
	burst.Anchored = true
	burst.CanCollide = false
	burst.Transparency = 1
	burst.Position = pos
	burst.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(GOLD_COLOR)
	emitter.Lifetime = NumberRange.new(0.3)
	emitter.Rate = 0
	emitter.Size = NumberSequence.new(0.5)
	emitter.Speed = NumberRange.new(8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.LightEmission = 1
	emitter.Parent = burst
	emitter:Emit(40)
	Debris:AddItem(burst, 1)
end

local function startTeleportLoop(model: Model)
	task.spawn(function()
		while model.Parent do
			task.wait(TELEPORT_INTERVAL)
			if not model.Parent then
				break
			end
			local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				continue
			end
			local origin = hrp.Position
			teleportShatter(origin)
			local angle = math.random() * math.pi * 2
			local newPos = origin
				+ Vector3.new(math.cos(angle) * TELEPORT_RANGE, 0, math.sin(angle) * TELEPORT_RANGE)
			model:PivotTo(CFrame.new(newPos))
			teleportShatter(newPos)
			task.wait(0.3)
			novaRingDamage(newPos, 90)
		end
	end)
end

function BuddhaWraith.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = EnemyRigs.tryCloneMesh("BuddhaWraith", spawnPos) or buildRig(spawnPos)
	model.Parent = parent
	EnemyRigs.applyMeditationLocomotion(model)
	EnemyRigs.attachBossHealthBar(model, "Buddha Wraith")
	EnemyAI.attach(model, {
		tier = "Legendary",
		spawnPos = spawnPos + Vector3.new(0, 4, 0),
		patrolRadius = 30,
	})
	startTeleportLoop(model)
	return model
end

return BuddhaWraith
