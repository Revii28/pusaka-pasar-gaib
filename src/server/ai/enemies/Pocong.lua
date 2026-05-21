--!strict
--[[
	@module      Pocong
	@description Hostile Pocong enemy. Common tier. Wrapped body + simpul head.
	             Visual: prefer Open Cloud mesh via EnemyRigs.tryCloneMesh
	             ("Pocong") (InsertService:LoadAsset, server-side, cached) —
	             fallback ke primitive fabric body + head ball kalau asset gak
	             ke-load. Decorative hop animation TweenService Y+2 every ~3s —
	             visual cosmetic, gak ngaruh combat (Humanoid:MoveTo() FSM yang
	             handle pergerakan). PatrolRadius 30. Standard EnemyAI default
	             onAttack = Humanoid:TakeDamage.
	@author      Claude Agent (primary coder)
]]

local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local Pocong = {}

local FABRIC_COLOR = Color3.fromRGB(225, 220, 205)
local POCONG_BODY_SIZE = Vector3.new(3, 7, 3)

-- Primitive rig (fallback): fabric body cylinder + simpul head ball welded
-- to HRP. Dipakai kalau Open Cloud mesh asset gak ke-load (LoadAsset gagal /
-- server-only / ID kosong) — game tetep playable tanpa asset.
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
	local model = EnemyRigs.tryCloneMesh("Pocong", spawnPos) or buildPrimitiveRig(spawnPos)
	model.Parent = parent
	EnemyRigs.applyHopLocomotion(model)
	playHopLoop(model)
	EnemyAI.attach(model, {
		tier = "Common",
		spawnPos = spawnPos,
		patrolRadius = 30,
	})
	return model
end

return Pocong
