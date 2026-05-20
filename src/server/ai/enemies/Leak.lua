--!strict
--[[
	@module      Leak
	@description Hostile Leak — Rare tier. Glass red squat body + detached head
	             floating above + dangling organ cylinders. Unique HEAD DETACH
	             ATTACK: saat ATTACK state trigger via onAttack callback, head
	             TweenService Position toward player max 10 stud lunge (0.4s
	             out + 0.4s return), damage on apex, body stays still glow red
	             Neon during attack.
	@author      Claude Agent (primary coder)
]]

local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local Leak = {}

local FLESH_COLOR = Color3.fromRGB(150, 35, 35)
local ORGAN_COLOR = Color3.fromRGB(190, 25, 25)

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Leak_Hostile"
	model:SetAttribute("EnemyType", "Leak")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(3, 4, 3), model)

	local body = EnemyRigs.makePart({
		name = "Body",
		size = Vector3.new(3, 4, 3),
		color = FLESH_COLOR,
		material = Enum.Material.Glass,
		transparency = 0.3,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, body)

	-- Head DETACHED visually (sits 4 studs above body), welded to HRP so it
	-- follows the body for movement but tweens separately during attack.
	local head = EnemyRigs.makePart({
		name = "Head",
		size = Vector3.new(2.5, 2.5, 2.5),
		color = FLESH_COLOR,
		material = Enum.Material.Glass,
		transparency = 0.3,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	head.CFrame = hrp.CFrame * CFrame.new(0, 4, 0)
	-- Note: head NOT welded — we manipulate via Tween. Anchored on attack.

	for i = 1, 4 do
		local angle = (i / 4) * 2 * math.pi
		local organ = EnemyRigs.makePart({
			name = ("Organ%d"):format(i),
			size = Vector3.new(0.4, 3, 0.4),
			color = ORGAN_COLOR,
			material = Enum.Material.Neon,
			transparency = 0.4,
			parent = model,
		})
		organ.CFrame = head.CFrame * CFrame.new(math.cos(angle) * 0.6, -2, math.sin(angle) * 0.6)
		EnemyRigs.weld(hrp, organ)
	end

	EnemyRigs.makeHumanoid(model, "Leak")

	return EnemyRigs.finalize(model, hrp, spawnPos)
end

local function lungeHead(head: BasePart, target: Player, damage: number)
	local char = target.Character
	if not char then
		return
	end
	local targetHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetHrp then
		return
	end

	head.Anchored = true
	local origin = head.Position
	local direction = (targetHrp.Position - origin)
	local distance = math.min(direction.Magnitude, 10)
	local apex = origin + direction.Unit * distance

	local out = TweenService:Create(
		head,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = apex }
	)
	out:Play()
	out.Completed:Wait()

	local targetHum = char:FindFirstChildOfClass("Humanoid")
	if targetHum and (head.Position - targetHrp.Position).Magnitude <= 4 then
		targetHum:TakeDamage(damage)
	end

	local back = TweenService:Create(
		head,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = origin }
	)
	back:Play()
	back.Completed:Wait()
	head.Anchored = false
end

function Leak.spawn(spawnPos: Vector3, parent: Instance): Model
	local model = buildRig(spawnPos)
	model.Parent = parent

	EnemyAI.attach(model, {
		tier = "Rare",
		spawnPos = spawnPos,
		patrolRadius = 30,
		onAttack = function(target, damage)
			local head = model:FindFirstChild("Head") :: BasePart?
			if not head then
				return
			end
			lungeHead(head, target, damage)
		end,
	})
	return model
end

return Leak
