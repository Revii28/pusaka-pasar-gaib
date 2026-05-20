--!strict
--[[
	@module      Pocong
	@description Hostile Pocong enemy. Common tier. Wrapped body + simpul head.
	             Prefer Blender-generated MeshPart asset (ReplicatedStorage.
	             EnemyMeshes.PocongMesh) — falls back to primitive part build
	             when mesh template absent (defensive: user imports asset
	             manually via Studio UI, code keeps shipping either way).
	             Decorative hop animation TweenService Y+2 every ~3s — visual
	             cosmetic, gak ngaruh combat (Humanoid:MoveTo() FSM yang
	             handle pergerakan). PatrolRadius 30. Standard EnemyAI default
	             onAttack = Humanoid:TakeDamage.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local Pocong = {}

local FABRIC_COLOR = Color3.fromRGB(225, 220, 205)
local POCONG_BODY_SIZE = Vector3.new(3, 7, 3)
local MESH_FOLDER_NAME = "EnemyMeshes"
local MESH_NAME = "PocongMesh"

-- Try to clone Blender-imported PocongMesh from ReplicatedStorage.EnemyMeshes.
-- Returns Clone (BasePart or Model) on success, nil on miss. Non-blocking —
-- uses FindFirstChild bukan WaitForChild supaya kalau folder/mesh belum
-- di-import, fallback primitive langsung kepake tanpa stall thread.
local function tryClonePocongMesh(): Instance?
	local folder = ReplicatedStorage:FindFirstChild(MESH_FOLDER_NAME)
	if not folder then
		return nil
	end
	local template = folder:FindFirstChild(MESH_NAME)
	if not template then
		return nil
	end
	if not template:IsA("BasePart") and not template:IsA("Model") then
		return nil
	end
	return template:Clone()
end

-- Mesh rig: HRP (invisible, sized to POCONG_BODY_SIZE so Humanoid collision
-- bounds tetep konsisten across variant) + cloned mesh welded as visual.
-- Handle both MeshPart (single part) and Model (multi-part Blender export).
local function buildMeshRig(template: Instance, spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Pocong_Hostile"
	model:SetAttribute("EnemyType", "Pocong")
	model:SetAttribute("RigVariant", "Mesh")

	local hrp = EnemyRigs.makeRootPart(POCONG_BODY_SIZE, model)

	if template:IsA("BasePart") then
		template.Name = "Body"
		template.Anchored = false
		template.CanCollide = true
		template.Massless = true
		template.Parent = model
		template.CFrame = hrp.CFrame
		EnemyRigs.weld(hrp, template)
	else
		template.Parent = model
		if template:IsA("Model") and template.PrimaryPart then
			template:PivotTo(hrp.CFrame)
		end
		for _, desc in ipairs(template:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = false
				desc.Massless = true
				EnemyRigs.weld(hrp, desc)
			end
		end
	end

	EnemyRigs.makeHumanoid(model, "Pocong")
	return EnemyRigs.finalize(model, hrp, spawnPos)
end

-- Primitive rig (legacy): fabric body cylinder + simpul head ball welded
-- to HRP. Preserved sebagai fallback kalau MeshPart belum di-import ke
-- ReplicatedStorage.EnemyMeshes — game tetep playable tanpa asset.
local function buildPrimitiveRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Pocong_Hostile"
	model:SetAttribute("EnemyType", "Pocong")
	model:SetAttribute("RigVariant", "Primitive")

	local hrp = EnemyRigs.makeRootPart(POCONG_BODY_SIZE, model)

	local body = EnemyRigs.makePart({
		name = "Body",
		size = POCONG_BODY_SIZE,
		color = FABRIC_COLOR,
		material = Enum.Material.Fabric,
		transparency = 0.25,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, body)

	local head = EnemyRigs.makePart({
		name = "Head",
		size = Vector3.new(1.8, 1.8, 1.8),
		color = FABRIC_COLOR,
		material = Enum.Material.Fabric,
		transparency = 0.25,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	head.CFrame = hrp.CFrame * CFrame.new(0, 4, 0)
	EnemyRigs.weld(hrp, head)

	EnemyRigs.makeHumanoid(model, "Pocong")

	return EnemyRigs.finalize(model, hrp, spawnPos)
end

local function buildRig(spawnPos: Vector3): Model
	local template = tryClonePocongMesh()
	if template then
		return buildMeshRig(template, spawnPos)
	end
	return buildPrimitiveRig(spawnPos)
end

local function playHopLoop(model: Model)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	task.spawn(function()
		while model.Parent do
			local up = TweenService:Create(
				hrp,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = hrp.Position + Vector3.new(0, 2, 0) }
			)
			up:Play()
			task.wait(2.6)
			if not hrp.Parent then
				break
			end
		end
	end)
end

function Pocong.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = buildRig(spawnPos)
	model.Parent = parent
	playHopLoop(model)
	EnemyAI.attach(model, {
		tier = "Common",
		spawnPos = spawnPos,
		patrolRadius = 30,
	})
	return model
end

return Pocong
