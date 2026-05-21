--!strict
--[[
	@module      Banaspati
	@description Hostile Banaspati — Epic tier. Floating fireball entity, no
	             humanoid limbs. Hover mode (Humanoid PlatformStand=true, BodyVelocity
	             zero gravity). RANGE FIREBALL attack: spawn projectile Neon
	             orange Part dengan BodyVelocity toward player, damage on Touch.
	             EnemyAI custom onAttack callback handle projectile.
	@author      Claude Agent (primary coder)
]]

local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local aiFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("ai")
local EnemyAI = require(aiFolder:WaitForChild("EnemyAI"))
local EnemyRigs = require(aiFolder:WaitForChild("EnemyRigs"))

local Banaspati = {}

local CORE_COLOR = Color3.fromRGB(255, 110, 0)
local TENDRIL_COLOR = Color3.fromRGB(255, 200, 60)
local FIREBALL_SPEED = 60
local FIREBALL_LIFETIME = 3
local HOVER_HEIGHT = 5

local function buildRig(spawnPos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Banaspati_Hostile"
	model:SetAttribute("EnemyType", "Banaspati")

	local hrp = EnemyRigs.makeRootPart(Vector3.new(2, 2, 2), model)

	local core = EnemyRigs.makePart({
		name = "Core",
		size = Vector3.new(2, 2, 2),
		color = CORE_COLOR,
		material = Enum.Material.Neon,
		transparency = 0.1,
		shape = Enum.PartType.Ball,
		canCollide = true,
		parent = model,
	})
	EnemyRigs.weld(hrp, core)

	local light = Instance.new("PointLight")
	light.Color = CORE_COLOR
	light.Brightness = 5
	light.Range = 18
	light.Parent = core

	for i = 1, 6 do
		local angle = (i / 6) * 2 * math.pi
		local tendril = EnemyRigs.makePart({
			name = ("Tendril%d"):format(i),
			size = Vector3.new(0.3, 3, 0.3),
			color = TENDRIL_COLOR,
			material = Enum.Material.Neon,
			transparency = 0.3,
			parent = model,
		})
		tendril.CFrame = hrp.CFrame
			* CFrame.new(math.cos(angle) * 1.2, 0, math.sin(angle) * 1.2)
			* CFrame.Angles(math.rad(45), angle, 0)
		EnemyRigs.weld(hrp, tendril)
	end

	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(CORE_COLOR)
	sparks.Lifetime = NumberRange.new(0.6, 1.2)
	sparks.Rate = 30
	sparks.Size = NumberSequence.new(0.4)
	sparks.Speed = NumberRange.new(3)
	sparks.LightEmission = 1
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Parent = core

	local hum = EnemyRigs.makeHumanoid(model, "Banaspati")
	hum.PlatformStand = true

	return EnemyRigs.finalize(model, hrp, spawnPos + Vector3.new(0, HOVER_HEIGHT, 0))
end

local function launchFireball(origin: Vector3, target: Player, damage: number)
	local char = target.Character
	if not char then
		return
	end
	local targetHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetHrp then
		return
	end

	local projectile = Instance.new("Part")
	projectile.Name = "BanaspatiFireball"
	projectile.Shape = Enum.PartType.Ball
	projectile.Size = Vector3.new(1, 1, 1)
	projectile.Material = Enum.Material.Neon
	projectile.Color = CORE_COLOR
	projectile.Anchored = false
	projectile.CanCollide = false
	projectile.Massless = true
	projectile.Position = origin

	local light = Instance.new("PointLight")
	light.Color = CORE_COLOR
	light.Brightness = 4
	light.Range = 10
	light.Parent = projectile

	local direction = (targetHrp.Position - origin).Unit
	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	velocity.Velocity = direction * FIREBALL_SPEED
	velocity.Parent = projectile

	projectile.Parent = workspace

	local hit = false
	projectile.Touched:Connect(function(other)
		if hit then
			return
		end
		local otherChar = other:FindFirstAncestorOfClass("Model")
		if not otherChar or otherChar:GetAttribute("EnemyType") then
			return
		end
		local hum = otherChar:FindFirstChildOfClass("Humanoid")
		if hum and otherChar ~= projectile.Parent then
			hit = true
			hum:TakeDamage(damage)
			projectile:Destroy()
		end
	end)

	Debris:AddItem(projectile, FIREBALL_LIFETIME)
end

local function startHoverLock(model: Model, baseY: number)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	task.spawn(function()
		while model.Parent do
			task.wait(0.1)
			if hrp.Position.Y < baseY - 1 then
				TweenService:Create(
					hrp,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ CFrame = CFrame.new(hrp.Position.X, baseY, hrp.Position.Z) }
				):Play()
			end
		end
	end)
end

function Banaspati.spawn(spawnPos: Vector3, parent: Instance): Model
	local hoverPos = spawnPos + Vector3.new(0, HOVER_HEIGHT, 0)
	local model = EnemyRigs.tryCloneMesh("Banaspati", spawnPos) or buildRig(spawnPos)
	model.Parent = parent
	startHoverLock(model, hoverPos.Y)
	EnemyAI.attach(model, {
		tier = "Epic",
		spawnPos = hoverPos,
		patrolRadius = 40,
		onAttack = function(target, damage)
			local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				launchFireball(hrp.Position, target, damage)
			end
		end,
	})
	return model
end

return Banaspati
