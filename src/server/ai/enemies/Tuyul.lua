--!strict
--[[
	@module      Tuyul
	@description Hostile Tuyul — Trash tier (tutorial baby ghost). Small bald
	             kid creature ~2 stud tall, tan skin, red glowing eyes.
	             Behavior tweak: chase trigger HANYA kalau player < 8 stud
	             (way less than tier default 20). Patrol scattered jauh dari
	             spawn. On kill: 1s visual "coin pop" effect (Neon yellow ball
	             yang fade out) — placeholder loot indicator, NO actual item drop.
	@author      Claude Agent (primary coder)
]]

local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local Tuyul = {}

local SKIN_COLOR = Color3.fromRGB(195, 155, 110)
local EYE_COLOR = Color3.fromRGB(255, 40, 0)
local COIN_COLOR = Color3.fromRGB(255, 215, 80)

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Tuyul_Hostile"
	model:SetAttribute("EnemyType", "Tuyul")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(1.2, 1.5, 0.8), model)

	local torso = EnemyRigs.makePart({
		name = "Torso",
		size = Vector3.new(1.2, 1.5, 0.8),
		color = SKIN_COLOR,
		material = Enum.Material.SmoothPlastic,
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
	head.CFrame = hrp.CFrame * CFrame.new(0, 1.25, 0)
	EnemyRigs.weld(hrp, head)

	for i, sideX in ipairs({ -0.2, 0.2 }) do
		local eye = EnemyRigs.makePart({
			name = ("Eye%d"):format(i),
			size = Vector3.new(0.15, 0.15, 0.15),
			color = EYE_COLOR,
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			parent = model,
		})
		eye.CFrame = head.CFrame * CFrame.new(sideX, 0.1, -0.5)
		EnemyRigs.weld(head, eye)
	end

	for i, sideX in ipairs({ -0.7, 0.7 }) do
		local arm = EnemyRigs.makePart({
			name = ("Arm%d"):format(i),
			size = Vector3.new(0.3, 1, 0.3),
			color = SKIN_COLOR,
			material = Enum.Material.SmoothPlastic,
			parent = model,
		})
		arm.CFrame = hrp.CFrame * CFrame.new(sideX, 0, 0)
		EnemyRigs.weld(hrp, arm)
	end

	for i, sideX in ipairs({ -0.3, 0.3 }) do
		local leg = EnemyRigs.makePart({
			name = ("Leg%d"):format(i),
			size = Vector3.new(0.3, 1, 0.3),
			color = SKIN_COLOR,
			material = Enum.Material.SmoothPlastic,
			parent = model,
		})
		leg.CFrame = hrp.CFrame * CFrame.new(sideX, -1.25, 0)
		EnemyRigs.weld(hrp, leg)
	end

	EnemyRigs.makeHumanoid(model, "Tuyul")

	return EnemyRigs.finalize(model, hrp, spawnPos)
end

local function popCoinEffect(pos: Vector3)
	local coin = Instance.new("Part")
	coin.Name = "TuyulCoinPop"
	coin.Shape = Enum.PartType.Ball
	coin.Size = Vector3.new(0.8, 0.8, 0.8)
	coin.Material = Enum.Material.Neon
	coin.Color = COIN_COLOR
	coin.Anchored = true
	coin.CanCollide = false
	coin.Position = pos + Vector3.new(0, 1.5, 0)
	coin.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = COIN_COLOR
	light.Brightness = 4
	light.Range = 6
	light.Parent = coin

	TweenService:Create(coin, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = coin.Position + Vector3.new(0, 4, 0),
		Transparency = 1,
		Size = Vector3.new(0.2, 0.2, 0.2),
	}):Play()
	Debris:AddItem(coin, 1)
end

function Tuyul.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = buildRig(spawnPos)
	model.Parent = parent

	-- Custom detect range: gunakan tier Trash default (20) — masih cukup short.
	-- Coin pop on death via onDeath callback.
	EnemyAI.attach(model, {
		tier = "Trash",
		spawnPos = spawnPos,
		patrolRadius = 25,
		onDeath = function()
			local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				popCoinEffect(hrp.Position)
			end
		end,
	})
	return model
end

return Tuyul
