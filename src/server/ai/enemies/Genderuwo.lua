--!strict
--[[
	@module      Genderuwo
	@description Hostile Genderuwo enemy. Uncommon tier. Bulky brown body with
	             red Neon eyes + 2 arms. Slow heavy chase tapi tinggi damage.
	             Eyes Neon glow via PointLight. Slam attack uses default
	             onAttack = Humanoid:TakeDamage.
	@author      Claude Agent (primary coder)
]]

local ServerScriptService = game:GetService("ServerScriptService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local Genderuwo = {}

local BODY_COLOR = Color3.fromRGB(55, 38, 28)
local EYE_COLOR = Color3.fromRGB(255, 30, 0)

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Genderuwo_Hostile"
	model:SetAttribute("EnemyType", "Genderuwo")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(4, 8, 3), model)

	local torso = EnemyRigs.makePart({
		name = "Torso",
		size = Vector3.new(4, 8, 3),
		color = BODY_COLOR,
		material = Enum.Material.Slate,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, torso)

	local head = EnemyRigs.makePart({
		name = "Head",
		size = Vector3.new(3, 3, 3),
		color = Color3.fromRGB(45, 30, 22),
		material = Enum.Material.Slate,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	head.CFrame = hrp.CFrame * CFrame.new(0, 5, 0)
	EnemyRigs.weld(hrp, head)

	for i, sideX in ipairs({ -3, 3 }) do
		local arm = EnemyRigs.makePart({
			name = ("Arm%d"):format(i),
			size = Vector3.new(1.5, 7, 1.5),
			color = Color3.fromRGB(50, 34, 24),
			material = Enum.Material.Slate,
			parent = model,
		})
		arm.CFrame = hrp.CFrame * CFrame.new(sideX, -1, 0)
		EnemyRigs.weld(hrp, arm)
	end

	for i, sideX in ipairs({ -0.7, 0.7 }) do
		local eye = EnemyRigs.makePart({
			name = ("Eye%d"):format(i),
			size = Vector3.new(0.6, 0.6, 0.4),
			color = EYE_COLOR,
			material = Enum.Material.Neon,
			parent = model,
		})
		eye.CFrame = head.CFrame * CFrame.new(sideX, 0.2, -1.4)
		EnemyRigs.weld(head, eye)
		local light = Instance.new("PointLight")
		light.Color = EYE_COLOR
		light.Brightness = 3
		light.Range = 6
		light.Parent = eye
	end

	EnemyRigs.makeHumanoid(model, "Genderuwo")

	return EnemyRigs.finalize(model, hrp, spawnPos)
end

function Genderuwo.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = EnemyRigs.tryCloneMesh("Genderuwo", spawnPos) or buildRig(spawnPos)
	model.Parent = parent
	EnemyRigs.applyStompLocomotion(model)
	EnemyAI.attach(model, {
		tier = "Uncommon",
		spawnPos = spawnPos,
		patrolRadius = 35,
	})
	return model
end

return Genderuwo
