--!strict
--[[
	@module      ButoIjo
	@description Hostile Buto Ijo — Epic tier, giant green ogre ~12 stud height.
	             Bulky torso + 2 arms + club weapon. SLAM ATTACK custom: AoE
	             damage 35 (tier default) ke all players dalam 6 stud radius
	             dari slam point. Visual shockwave ring particles.
	@author      Claude Agent (primary coder)
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local ButoIjo = {}

local BODY_COLOR = Color3.fromRGB(50, 125, 50)
local HEAD_COLOR = Color3.fromRGB(35, 90, 35)
local CLUB_COLOR = Color3.fromRGB(85, 55, 30)
local EYE_COLOR = Color3.fromRGB(255, 30, 0)
local FANG_COLOR = Color3.fromRGB(245, 240, 220)
local SLAM_RADIUS = 6

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "ButoIjo_Hostile"
	model:SetAttribute("EnemyType", "ButoIjo")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(5, 8, 3), model)

	local torso = EnemyRigs.makePart({
		name = "Torso",
		size = Vector3.new(5, 8, 3),
		color = BODY_COLOR,
		material = Enum.Material.SmoothPlastic,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, torso)

	local head = EnemyRigs.makePart({
		name = "Head",
		size = Vector3.new(3, 3, 3),
		color = HEAD_COLOR,
		material = Enum.Material.SmoothPlastic,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	head.CFrame = hrp.CFrame * CFrame.new(0, 5, 0)
	EnemyRigs.weld(hrp, head)

	for i, sideX in ipairs({ -0.7, 0.7 }) do
		local eye = EnemyRigs.makePart({
			name = ("Eye%d"):format(i),
			size = Vector3.new(0.5, 0.5, 0.3),
			color = EYE_COLOR,
			material = Enum.Material.Neon,
			parent = model,
		})
		eye.CFrame = head.CFrame * CFrame.new(sideX, 0.3, -1.4)
		EnemyRigs.weld(head, eye)
	end

	for i, sideX in ipairs({ -0.5, 0.5 }) do
		local fang = EnemyRigs.makePart({
			name = ("Fang%d"):format(i),
			size = Vector3.new(0.3, 1.5, 0.3),
			color = FANG_COLOR,
			material = Enum.Material.SmoothPlastic,
			parent = model,
		})
		fang.CFrame = head.CFrame * CFrame.new(sideX, -1.2, -1)
		EnemyRigs.weld(head, fang)
	end

	for i, sideX in ipairs({ -3, 3 }) do
		local arm = EnemyRigs.makePart({
			name = ("Arm%d"):format(i),
			size = Vector3.new(1.2, 6, 1.2),
			color = BODY_COLOR,
			material = Enum.Material.SmoothPlastic,
			parent = model,
		})
		arm.CFrame = hrp.CFrame * CFrame.new(sideX, -0.5, 0)
		EnemyRigs.weld(hrp, arm)
	end

	local club = EnemyRigs.makePart({
		name = "Club",
		size = Vector3.new(1, 5, 1),
		color = CLUB_COLOR,
		material = Enum.Material.Wood,
		parent = model,
	})
	club.CFrame = hrp.CFrame * CFrame.new(3.5, -3, 0)
	EnemyRigs.weld(hrp, club)

	EnemyRigs.makeHumanoid(model, "Buto Ijo")

	return EnemyRigs.finalize(model, hrp, spawnPos)
end

local function slamShockwave(origin: Vector3, damage: number)
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local dist = (hrp.Position - origin).Magnitude
				if dist <= SLAM_RADIUS then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum:TakeDamage(damage)
					end
				end
			end
		end
	end

	local ring = Instance.new("Part")
	ring.Name = "SlamShockwave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.4, SLAM_RADIUS * 2, SLAM_RADIUS * 2)
	ring.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(200, 220, 180)
	ring.Transparency = 0.5
	ring.Parent = workspace
	game:GetService("Debris"):AddItem(ring, 0.4)
end

function ButoIjo.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = EnemyRigs.tryCloneMesh("ButoIjo", spawnPos) or buildRig(spawnPos)
	model.Parent = parent
	EnemyRigs.applyStrideLocomotion(model)
	EnemyAI.attach(model, {
		tier = "Epic",
		spawnPos = spawnPos,
		patrolRadius = 35,
		onAttack = function(_, damage)
			local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				slamShockwave(hrp.Position, damage)
			end
		end,
	})
	return model
end

return ButoIjo
