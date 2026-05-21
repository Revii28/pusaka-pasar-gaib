--!strict
--[[
	@module      SundelBolong
	@description Hostile Sundel Bolong — Rare tier. Tall lady, long black hair,
	             white dress, BACK HOLE Neon red glowing di belakang. BACKSTEP
	             DASH variant: kalau player approach < 3 stud, dash backward
	             15 stud Quad easing 0.5s, then re-engage. Custom onAttack
	             default damage but with backstep retreat check.
	@author      Claude Agent (primary coder)
]]

local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local SundelBolong = {}

local DRESS_COLOR = Color3.fromRGB(240, 235, 225)
local SKIN_COLOR = Color3.fromRGB(220, 200, 180)
local HOLE_COLOR = Color3.fromRGB(180, 20, 20)
local HAIR_COLOR = Color3.fromRGB(15, 10, 15)
local BACKSTEP_DISTANCE = 15
local BACKSTEP_PROXIMITY = 3

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "SundelBolong_Hostile"
	model:SetAttribute("EnemyType", "SundelBolong")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(1.5, 5, 1), model)

	local torso = EnemyRigs.makePart({
		name = "Torso",
		size = Vector3.new(1.5, 4, 1),
		color = DRESS_COLOR,
		material = Enum.Material.Fabric,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, torso)

	local head = EnemyRigs.makePart({
		name = "Head",
		size = Vector3.new(1, 1, 1),
		color = SKIN_COLOR,
		material = Enum.Material.SmoothPlastic,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	head.CFrame = hrp.CFrame * CFrame.new(0, 2.6, 0)
	EnemyRigs.weld(hrp, head)

	local hole = EnemyRigs.makePart({
		name = "BackHole",
		size = Vector3.new(1, 2, 0.3),
		color = HOLE_COLOR,
		material = Enum.Material.Neon,
		parent = model,
	})
	hole.CFrame = hrp.CFrame * CFrame.new(0, 0, 0.6)
	EnemyRigs.weld(hrp, hole)

	for i = 1, 8 do
		local angle = ((i - 1) / 8) * math.pi - math.pi / 2
		local localX = math.sin(angle) * 0.5
		local localZ = -0.5 + math.cos(angle) * 0.2
		local hair = EnemyRigs.makePart({
			name = ("Hair%d"):format(i),
			size = Vector3.new(0.1, 5, 0.1),
			color = HAIR_COLOR,
			material = Enum.Material.Fabric,
			parent = model,
		})
		hair.CFrame = hrp.CFrame * CFrame.new(localX, 1, localZ)
		EnemyRigs.weld(hrp, hair)
	end

	for i, sideX in ipairs({ -1, 1 }) do
		local arm = EnemyRigs.makePart({
			name = ("Arm%d"):format(i),
			size = Vector3.new(0.4, 3, 0.4),
			color = DRESS_COLOR,
			material = Enum.Material.Fabric,
			parent = model,
		})
		arm.CFrame = hrp.CFrame * CFrame.new(sideX, -0.5, 0)
		EnemyRigs.weld(hrp, arm)
	end

	EnemyRigs.makeHumanoid(model, "Sundel Bolong")

	return EnemyRigs.finalize(model, hrp, spawnPos)
end

local function backstepDash(hrp: BasePart, awayFrom: Vector3)
	local direction = (hrp.Position - awayFrom)
	if direction.Magnitude < 0.1 then
		return
	end
	local target = hrp.Position + direction.Unit * BACKSTEP_DISTANCE + Vector3.new(0, 0, 0)
	local origAnchored = hrp.Anchored
	hrp.Anchored = true
	TweenService:Create(
		hrp,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(target, awayFrom) }
	):Play()
	task.delay(0.55, function()
		hrp.Anchored = origAnchored
	end)
end

local function startProximityWatcher(model: Model)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local Players = game:GetService("Players")
	task.spawn(function()
		local lastDashTime = 0
		while model.Parent do
			task.wait(0.25)
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				if char then
					local pHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if pHrp then
						local dist = (pHrp.Position - hrp.Position).Magnitude
						local now = os.clock()
						if dist < BACKSTEP_PROXIMITY and now - lastDashTime > 1.5 then
							lastDashTime = now
							backstepDash(hrp, pHrp.Position)
							break
						end
					end
				end
			end
		end
	end)
end

function SundelBolong.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = EnemyRigs.tryCloneMesh("SundelBolong", spawnPos) or buildRig(spawnPos)
	model.Parent = parent
	EnemyAI.attach(model, {
		tier = "Rare",
		spawnPos = spawnPos,
		patrolRadius = 35,
	})
	startProximityWatcher(model)
	return model
end

return SundelBolong
