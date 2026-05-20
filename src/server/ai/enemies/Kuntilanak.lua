--!strict
--[[
	@module      Kuntilanak
	@description Hostile Kuntilanak — SILENT STALKER variant. Slim white body + 6
	             black hair strands. Behavior: kalau player MENGHADAP Kuntilanak
	             (HRP LookVector dot toward Kuntilanak > 0.5) → freeze
	             (WalkSpeed=0). Kalau NOT looking → full chase speed.
	             SIMPLIFICATION: pakai player HRP CFrame.LookVector sebagai
	             proxy karena Camera client-side. Real camera dot product
	             nyusul Phase 4+ via client→server RemoteEvent ping.
	@author      Claude Agent (primary coder)
]]

local ServerScriptService = game:GetService("ServerScriptService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local Kuntilanak = {}

local DRESS_COLOR = Color3.fromRGB(240, 235, 225)
local HAIR_COLOR = Color3.fromRGB(15, 10, 15)
local LOOK_DOT_THRESHOLD = 0.5

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Kuntilanak_Hostile"
	model:SetAttribute("EnemyType", "Kuntilanak")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(2.5, 6, 2.5), model)

	local body = EnemyRigs.makePart({
		name = "Body",
		size = Vector3.new(2.5, 6, 2.5),
		color = DRESS_COLOR,
		material = Enum.Material.Fabric,
		transparency = 0.3,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, body)

	local head = EnemyRigs.makePart({
		name = "Head",
		size = Vector3.new(1.8, 1.8, 1.8),
		color = DRESS_COLOR,
		material = Enum.Material.Fabric,
		transparency = 0.3,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	head.CFrame = hrp.CFrame * CFrame.new(0, 4, 0)
	EnemyRigs.weld(hrp, head)

	for i = 1, 6 do
		local angle = (i / 6) * math.pi - math.pi / 2
		local localX = math.sin(angle) * 0.7
		local localZ = -0.8 + math.cos(angle) * 0.3
		local hair = EnemyRigs.makePart({
			name = ("Hair%d"):format(i),
			size = Vector3.new(0.3, 6, 0.3),
			color = HAIR_COLOR,
			material = Enum.Material.Fabric,
			parent = model,
		})
		hair.CFrame = hrp.CFrame * CFrame.new(localX, 0.5, localZ)
		EnemyRigs.weld(hrp, hair)
	end

	EnemyRigs.makeHumanoid(model, "Kuntilanak")

	return EnemyRigs.finalize(model, hrp, spawnPos)
end

local function startStalkerLoop(model: Model)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return
	end
	local Players = game:GetService("Players")
	task.spawn(function()
		while model.Parent and hum.Health > 0 do
			task.wait(0.2)
			local frozen = false
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				if char then
					local pHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if pHrp then
						local toEnemy = (hrp.Position - pHrp.Position).Unit
						local look = pHrp.CFrame.LookVector
						local dot = toEnemy:Dot(look)
						local dist = (hrp.Position - pHrp.Position).Magnitude
						if dist < 40 and dot > LOOK_DOT_THRESHOLD then
							frozen = true
							break
						end
					end
				end
			end
			if frozen then
				hum.WalkSpeed = 0
			end
		end
	end)
end

function Kuntilanak.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = buildRig(spawnPos)
	model.Parent = parent
	EnemyAI.attach(model, {
		tier = "Rare",
		spawnPos = spawnPos,
		patrolRadius = 30,
	})
	startStalkerLoop(model)
	return model
end

return Kuntilanak
