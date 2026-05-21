--!strict
--[[
	@module      SetanPasar
	@description Mini-boss Pasar Setan — Boss tier (1500HP/60dmg). Multi-limbed
	             floating entity ~10 stud. Visual: red Neon torso + 4 floating
	             head orbiting + 6 spectral arms + 5 spike gold crown. Unique
	             mechanics: SUMMON MINION tiap 15s (2 Tuyul as "weak Pocong"
	             placeholder), MULTI-STRIKE attack (4 hits @ 25% damage each
	             over 0.5s burst = full tier damage 60). HP bar BillboardGui
	             above head, 250 stud visibility.
	@author      Claude Agent (primary coder)
]]

local ServerScriptService = game:GetService("ServerScriptService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))
local TuyulModule = require(aiFolder:WaitForChild("enemies"):WaitForChild("Tuyul"))

local SetanPasar = {}

local TORSO_COLOR = Color3.fromRGB(200, 30, 30)
local CROWN_COLOR = Color3.fromRGB(240, 200, 70)
local ARM_COLOR = Color3.fromRGB(220, 50, 50)
local SUMMON_INTERVAL = 15
local MULTI_STRIKE_HITS = 4
local MULTI_STRIKE_GAP = 0.12

local HEAD_FACE_COLORS = {
	Color3.fromRGB(220, 40, 40),
	Color3.fromRGB(30, 25, 30),
	Color3.fromRGB(160, 60, 220),
	Color3.fromRGB(240, 200, 60),
}

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "SetanPasar_Boss"
	model:SetAttribute("EnemyType", "SetanPasar")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(3, 6, 2), model)

	local torso = EnemyRigs.makePart({
		name = "Torso",
		size = Vector3.new(3, 6, 2),
		color = TORSO_COLOR,
		material = Enum.Material.Neon,
		transparency = 0.3,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, torso)

	for i = 1, 4 do
		local angle = ((i - 1) / 4) * 2 * math.pi
		local head = EnemyRigs.makePart({
			name = ("OrbitHead%d"):format(i),
			size = Vector3.new(1.5, 1.5, 1.5),
			color = HEAD_FACE_COLORS[i],
			material = Enum.Material.Neon,
			transparency = 0.2,
			shape = Enum.PartType.Ball,
			parent = model,
		})
		head.CFrame = hrp.CFrame * CFrame.new(math.cos(angle) * 3, 2, math.sin(angle) * 3)
		EnemyRigs.weld(hrp, head)
	end

	for i = 1, 6 do
		local angle = ((i - 1) / 6) * 2 * math.pi
		local arm = EnemyRigs.makePart({
			name = ("Arm%d"):format(i),
			size = Vector3.new(0.4, 5, 0.4),
			color = ARM_COLOR,
			material = Enum.Material.Neon,
			transparency = 0.4,
			parent = model,
		})
		arm.CFrame = hrp.CFrame
			* CFrame.new(math.cos(angle) * 2, -1, math.sin(angle) * 2)
			* CFrame.Angles(0, angle, math.rad(20))
		EnemyRigs.weld(hrp, arm)
	end

	for i = 1, 5 do
		local angle = ((i - 1) / 5) * 2 * math.pi
		local spike = EnemyRigs.makePart({
			name = ("CrownSpike%d"):format(i),
			size = Vector3.new(0.3, 2, 0.3),
			color = CROWN_COLOR,
			material = Enum.Material.Neon,
			parent = model,
		})
		spike.CFrame = hrp.CFrame * CFrame.new(math.cos(angle) * 0.8, 4, math.sin(angle) * 0.8)
		EnemyRigs.weld(hrp, spike)
	end

	local aura = Instance.new("PointLight")
	aura.Color = TORSO_COLOR
	aura.Brightness = 6
	aura.Range = 30
	aura.Parent = torso

	EnemyRigs.makeHumanoid(model, "Setan Pasar")

	return EnemyRigs.finalize(model, hrp, spawnPos + Vector3.new(0, 6, 0))
end

local function multiStrike(target: Player, totalDamage: number)
	local char = target.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local perHit = totalDamage / MULTI_STRIKE_HITS
	for i = 1, MULTI_STRIKE_HITS do
		if not hum.Parent then
			break
		end
		hum:TakeDamage(perHit)
		if i < MULTI_STRIKE_HITS then
			task.wait(MULTI_STRIKE_GAP)
		end
	end
end

local function startSummonLoop(model: Model, enemiesFolder: Instance)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	task.spawn(function()
		while model.Parent do
			task.wait(SUMMON_INTERVAL)
			if not model.Parent then
				break
			end
			for i = 1, 2 do
				local angle = (i / 2) * math.pi
				local pos = hrp.Position + Vector3.new(math.cos(angle) * 4, 0, math.sin(angle) * 4)
				local ok, err = pcall(TuyulModule.spawn, pos, enemiesFolder)
				if not ok then
					warn(("[SetanPasar] summon failed: %s"):format(tostring(err)))
				end
			end
		end
	end)
end

function SetanPasar.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = EnemyRigs.tryCloneMesh("SetanPasar", spawnPos) or buildRig(spawnPos)
	model.Parent = parent
	EnemyRigs.attachBossHealthBar(model, "Setan Pasar")
	EnemyAI.attach(model, {
		tier = "Boss",
		spawnPos = spawnPos,
		patrolRadius = 40,
		onAttack = function(target, damage)
			multiStrike(target, damage)
		end,
	})
	startSummonLoop(model, parent)
	return model
end

return SetanPasar
