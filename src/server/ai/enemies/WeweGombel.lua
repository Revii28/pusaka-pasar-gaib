--!strict
--[[
	@module      WeweGombel
	@description Hostile Wewe Gombel — Epic tier, tall ghost woman ~9 stud
	             height. Long arms extended down + long black hair. GRAB ATTACK
	             custom onAttack: stun target (WalkSpeed=0) selama 1.5s lalu
	             deal damage. PointLight purple range 20 ambient untuk
	             intimidation aura.
	@author      Claude Agent (primary coder)
]]

local ServerScriptService = game:GetService("ServerScriptService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local WeweGombel = {}

local DRESS_COLOR = Color3.fromRGB(55, 28, 75)
local SKIN_COLOR = Color3.fromRGB(220, 215, 205)
local HAIR_COLOR = Color3.fromRGB(15, 10, 15)
local AURA_COLOR = Color3.fromRGB(140, 80, 200)

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "WeweGombel_Hostile"
	model:SetAttribute("EnemyType", "WeweGombel")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(2, 6, 1.5), model)

	local torso = EnemyRigs.makePart({
		name = "Torso",
		size = Vector3.new(2.5, 6, 1.5),
		color = DRESS_COLOR,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.2,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, torso)

	local head = EnemyRigs.makePart({
		name = "Head",
		size = Vector3.new(1.8, 1.8, 1.8),
		color = SKIN_COLOR,
		material = Enum.Material.SmoothPlastic,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	head.CFrame = hrp.CFrame * CFrame.new(0, 4, 0)
	EnemyRigs.weld(hrp, head)

	for i, sideX in ipairs({ -1.6, 1.6 }) do
		local arm = EnemyRigs.makePart({
			name = ("Arm%d"):format(i),
			size = Vector3.new(0.6, 7, 0.6),
			color = DRESS_COLOR,
			material = Enum.Material.SmoothPlastic,
			transparency = 0.2,
			parent = model,
		})
		arm.CFrame = hrp.CFrame * CFrame.new(sideX, -0.5, 0.5)
		EnemyRigs.weld(hrp, arm)
	end

	for i = 1, 10 do
		local angle = ((i - 1) / 10) * math.pi - math.pi / 2
		local localX = math.sin(angle) * 0.6
		local localZ = -0.7 + math.cos(angle) * 0.2
		local hair = EnemyRigs.makePart({
			name = ("Hair%d"):format(i),
			size = Vector3.new(0.15, 6, 0.15),
			color = HAIR_COLOR,
			material = Enum.Material.Fabric,
			parent = model,
		})
		hair.CFrame = hrp.CFrame * CFrame.new(localX, 1.5, localZ)
		EnemyRigs.weld(hrp, hair)
	end

	local aura = Instance.new("PointLight")
	aura.Color = AURA_COLOR
	aura.Brightness = 3
	aura.Range = 20
	aura.Parent = torso

	EnemyRigs.makeHumanoid(model, "Wewe Gombel")

	return EnemyRigs.finalize(model, hrp, spawnPos)
end

local function grabStunAttack(target: Player, damage: number)
	local char = target.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local originalSpeed = hum.WalkSpeed
	hum.WalkSpeed = 0
	task.delay(1.5, function()
		if hum and hum.Parent then
			hum.WalkSpeed = originalSpeed
			hum:TakeDamage(damage)
		end
	end)
end

function WeweGombel.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = EnemyRigs.tryCloneMesh("WeweGombel", spawnPos) or buildRig(spawnPos)
	model.Parent = parent
	EnemyAI.attach(model, {
		tier = "Epic",
		spawnPos = spawnPos,
		patrolRadius = 35,
		onAttack = function(target, damage)
			grabStunAttack(target, damage)
		end,
	})
	return model
end

return WeweGombel
