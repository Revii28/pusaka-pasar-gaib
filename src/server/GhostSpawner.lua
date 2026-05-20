--!strict
--[[
	@module      GhostSpawner
	@description Rewrite besar: 4 hantu companion FLYING (gak napak terrain),
	             multi-part rig (bukan kotak satu), per-ghost ParticleEmitter
	             aura + PointLight + Trail attachment + complex animation
	             (Pocong hop tween, Genderuwo breathing+arm sway, Kuntilanak
	             hair sway per-hair phase, Leak figure-8 head orbit + arm
	             oscillate). Pairing kultural unchanged:
	               Mbok Inem    -> Pocong
	               Pak Tukijo   -> Genderuwo
	               Nyai Sumi    -> Kuntilanak
	               Bandar Robux -> Leak
	             Posisi: 6 studs di belakang NPC (calculated from lookDirection),
	             ground level X/Z, hover Y per-ghost. Detail polish & mesh import
	             di Phase art pass.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local MapHelpers = require(
	ServerScriptService:WaitForChild("Server"):WaitForChild("maps"):WaitForChild("MapHelpers")
)

local GhostSpawner = {}

type GhostType = "Pocong" | "Genderuwo" | "Kuntilanak" | "Leak"

type VendorInfo = {
	name: string,
	position: Vector3,
	lookDirection: Vector3,
}

local BEHIND_DISTANCE = 6
local TAG_COLOR = Color3.fromRGB(255, 100, 100)
local TAG_SIZE = UDim2.new(0, 80, 0, 20)

local NPC_TO_GHOST: { [string]: GhostType } = {
	["Mbok Inem"] = "Pocong",
	["Pak Tukijo"] = "Genderuwo",
	["Nyai Sumi"] = "Kuntilanak",
	["Bandar Robux"] = "Leak",
}

local function makePart(props: {
	name: string,
	size: Vector3,
	cframe: CFrame?,
	position: Vector3?,
	material: Enum.Material,
	color: Color3,
	transparency: number?,
	shape: Enum.PartType?,
	parent: Instance,
}): Part
	local part = Instance.new("Part")
	part.Name = props.name
	if props.shape then
		part.Shape = props.shape
	end
	part.Size = props.size
	if props.cframe then
		part.CFrame = props.cframe
	elseif props.position then
		part.Position = props.position
	end
	part.Material = props.material
	part.Color = props.color
	part.Transparency = props.transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent
	return part
end

local function attachNameTag(anchor: BasePart, ghostName: string, offsetY: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GhostNameTag"
	billboard.Size = TAG_SIZE
	billboard.StudsOffset = Vector3.new(0, offsetY, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = anchor
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = ghostName
	label.Font = Enum.Font.Cartoon
	label.TextColor3 = TAG_COLOR
	label.TextScaled = true
	label.Parent = billboard
end

local function attachTrail(host: BasePart, color: Color3, lifetime: number)
	local top = Instance.new("Attachment")
	top.Name = "TrailTop"
	top.Position = Vector3.new(0, host.Size.Y / 2, 0)
	top.Parent = host

	local bottom = Instance.new("Attachment")
	bottom.Name = "TrailBottom"
	bottom.Position = Vector3.new(0, -host.Size.Y / 2, 0)
	bottom.Parent = host

	local trail = Instance.new("Trail")
	trail.Name = "GhostTrail"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Lifetime = lifetime
	trail.Color = ColorSequence.new(color)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.LightEmission = 0.3
	trail.FaceCamera = true
	trail.Parent = host
end

local function attachAura(
	host: BasePart,
	config: {
		color: Color3,
		lifetimeMin: number,
		lifetimeMax: number,
		rate: number,
		sizeMin: number,
		sizeMax: number,
		transparency: number,
		speed: number,
		lightEmission: number?,
	}
)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Aura"
	emitter.Color = ColorSequence.new(config.color)
	emitter.Lifetime = NumberRange.new(config.lifetimeMin, config.lifetimeMax)
	emitter.Rate = config.rate * Constants.PERFORMANCE.GHOST_AURA_PARTICLE_RATE_MULTIPLIER
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, config.sizeMin),
		NumberSequenceKeypoint.new(1, config.sizeMax),
	})
	emitter.Transparency = NumberSequence.new(config.transparency)
	emitter.Speed = NumberRange.new(config.speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.LightEmission = config.lightEmission or 0
	emitter.Parent = host
end

local function attachLight(host: BasePart, color: Color3, brightness: number, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Parent = host
end

local function applyBob(part: BasePart, amplitude: number, period: number, easing: Enum.EasingStyle)
	local info = TweenInfo.new(period, easing, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(part, info, {
		Position = part.Position + Vector3.new(0, amplitude, 0),
	})
	tween:Play()
end

local function buildPocong(base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Pocong"

	local hoverY = 8
	local bodyCenter = base + Vector3.new(0, hoverY, 0)

	local body = makePart({
		name = "Body",
		size = Vector3.new(3, 7, 3),
		position = bodyCenter,
		material = Enum.Material.Fabric,
		color = Color3.fromRGB(220, 215, 200),
		transparency = 0.3,
		parent = model,
	})

	local head = makePart({
		name = "Head",
		size = Vector3.new(1.8, 1.8, 1.8),
		position = bodyCenter + Vector3.new(0, 4, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Fabric,
		color = Color3.fromRGB(220, 215, 200),
		transparency = 0.3,
		parent = model,
	})

	attachAura(body, {
		color = Color3.fromRGB(255, 255, 255),
		lifetimeMin = 2,
		lifetimeMax = 2,
		rate = 5,
		sizeMin = 1,
		sizeMax = 2,
		transparency = 0.7,
		speed = 1,
	})
	attachLight(body, Color3.fromRGB(255, 255, 255), 3, 8)
	attachTrail(body, Color3.fromRGB(255, 255, 255), 1)

	local hopInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(body, hopInfo, { Position = bodyCenter + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(head, hopInfo, { Position = bodyCenter + Vector3.new(0, 9, 0) }):Play()

	model.PrimaryPart = head
	attachNameTag(head, "Pocong", 2)
	return model
end

local function buildGenderuwo(base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Genderuwo"

	local hoverY = 4
	local torsoCenter = base + Vector3.new(0, hoverY, 0)

	local torso = makePart({
		name = "Torso",
		size = Vector3.new(5, 8, 4),
		position = torsoCenter,
		material = Enum.Material.Slate,
		color = Color3.fromRGB(50, 35, 25),
		transparency = 0.15,
		parent = model,
	})

	local head = makePart({
		name = "Head",
		size = Vector3.new(3, 3, 3),
		position = torsoCenter + Vector3.new(0, 5, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Slate,
		color = Color3.fromRGB(40, 30, 20),
		transparency = 0.15,
		parent = model,
	})

	for i, sideX in ipairs({ -3.5, 3.5 }) do
		local arm = makePart({
			name = ("Arm%d"):format(i),
			size = Vector3.new(1.5, 7, 1.5),
			position = torsoCenter + Vector3.new(sideX, -1, 0),
			material = Enum.Material.Slate,
			color = Color3.fromRGB(45, 30, 22),
			transparency = 0.15,
			parent = model,
		})
		attachTrail(arm, Color3.fromRGB(180, 30, 10), 0.8)

		local armBobInfo =
			TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(arm, armBobInfo, { Position = arm.Position + Vector3.new(0, 0.3, 0) })
			:Play()
	end

	for i, sideX in ipairs({ -0.7, 0.7 }) do
		local eye = makePart({
			name = ("Eye%d"):format(i),
			size = Vector3.new(0.6, 0.6, 0.4),
			position = head.Position + Vector3.new(sideX, 0.2, -1.4),
			material = Enum.Material.Neon,
			color = Color3.fromRGB(255, 30, 0),
			parent = model,
		})
		attachLight(eye, Color3.fromRGB(255, 30, 0), 3, 6)
	end

	for i, sideX in ipairs({ -1, 1 }) do
		local horn = makePart({
			name = ("Horn%d"):format(i),
			size = Vector3.new(0.4, 2, 0.4),
			cframe = CFrame.new(head.Position + Vector3.new(sideX, 1.5, 0))
				* CFrame.Angles(0, 0, math.rad(-15 * sideX)),
			shape = Enum.PartType.Cylinder,
			material = Enum.Material.Slate,
			color = Color3.fromRGB(30, 22, 18),
			parent = model,
		})
		horn.CFrame = horn.CFrame * CFrame.Angles(0, 0, math.rad(90))
	end

	attachAura(torso, {
		color = Color3.fromRGB(200, 40, 0),
		lifetimeMin = 1,
		lifetimeMax = 1.5,
		rate = 8,
		sizeMin = 0.5,
		sizeMax = 1,
		transparency = 0.4,
		speed = 1.5,
		lightEmission = 0.8,
	})
	attachLight(torso, Color3.fromRGB(255, 50, 0), 6, 10)

	local breathInfo =
		TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(torso, breathInfo, {
		Size = Vector3.new(torso.Size.X, torso.Size.Y * 1.05, torso.Size.Z),
	}):Play()

	model.PrimaryPart = torso
	attachNameTag(head, "Genderuwo", 3)
	return model
end

local function buildKuntilanak(base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Kuntilanak"

	local hoverY = 5
	local bodyCenter = base + Vector3.new(0, hoverY, 0)

	local body = makePart({
		name = "BodyUpper",
		size = Vector3.new(2, 6, 2),
		position = bodyCenter,
		material = Enum.Material.Fabric,
		color = Color3.fromRGB(245, 240, 235),
		transparency = 0.4,
		parent = model,
	})

	local head = makePart({
		name = "Head",
		size = Vector3.new(1.8, 1.8, 1.8),
		position = bodyCenter + Vector3.new(0, 4, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Fabric,
		color = Color3.fromRGB(245, 240, 235),
		transparency = 0.4,
		parent = model,
	})

	local gown = makePart({
		name = "GownFlare",
		size = Vector3.new(4, 5, 4),
		position = bodyCenter + Vector3.new(0, -5.5, 0),
		material = Enum.Material.Fabric,
		color = Color3.fromRGB(240, 230, 220),
		transparency = 0.5,
		parent = model,
	})

	local hairCount = 6
	for i = 1, hairCount do
		local angle = (i / hairCount) * math.pi - math.pi / 2
		local localX = math.sin(angle) * 0.7
		local localZ = -0.8 + math.cos(angle) * 0.3
		local hair = makePart({
			name = ("Hair%d"):format(i),
			size = Vector3.new(0.3, 7, 0.3),
			position = bodyCenter + Vector3.new(localX, 0.5, localZ),
			material = Enum.Material.Fabric,
			color = Color3.fromRGB(15, 10, 15),
			parent = model,
		})

		local originalCFrame = hair.CFrame
		local periodSec = 2 + (i % 3) * 0.3
		local delaySeconds = (i / hairCount) * 0.5
		local swayInfo = TweenInfo.new(
			periodSec,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true,
			delaySeconds
		)
		TweenService:Create(hair, swayInfo, {
			CFrame = originalCFrame * CFrame.Angles(0, 0, math.rad(5)),
		}):Play()
	end

	attachAura(body, {
		color = Color3.fromRGB(255, 200, 210),
		lifetimeMin = 3,
		lifetimeMax = 3,
		rate = 4,
		sizeMin = 0.5,
		sizeMax = 1.5,
		transparency = 0.7,
		speed = 0.5,
		lightEmission = 0.5,
	})
	attachLight(body, Color3.fromRGB(255, 220, 230), 4, 8)
	attachTrail(gown, Color3.fromRGB(255, 230, 240), 1.5)

	applyBob(body, 1, 2.5, Enum.EasingStyle.Sine)
	applyBob(head, 1, 2.5, Enum.EasingStyle.Sine)
	applyBob(gown, 1, 2.5, Enum.EasingStyle.Sine)

	model.PrimaryPart = head
	attachNameTag(head, "Kuntilanak", 2)
	return model
end

local function buildLeak(base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Leak"

	local hoverY = 5
	local torsoCenter = base + Vector3.new(0, hoverY, 0)

	local torso = makePart({
		name = "TorsoLower",
		size = Vector3.new(3, 4, 3),
		position = torsoCenter,
		material = Enum.Material.Glass,
		color = Color3.fromRGB(140, 30, 30),
		transparency = 0.35,
		parent = model,
	})

	local headBase = torsoCenter + Vector3.new(0, 4, 0)
	local head = makePart({
		name = "Head",
		size = Vector3.new(2.5, 2.5, 2.5),
		position = headBase,
		shape = Enum.PartType.Ball,
		material = Enum.Material.Glass,
		color = Color3.fromRGB(140, 30, 30),
		transparency = 0.35,
		parent = model,
	})

	local arms: { Part } = {}
	for i, sideX in ipairs({ -2.5, 2.5 }) do
		local arm = makePart({
			name = ("Arm%d"):format(i),
			size = Vector3.new(1, 3, 1),
			position = torsoCenter + Vector3.new(sideX, 0.5, 0),
			material = Enum.Material.Glass,
			color = Color3.fromRGB(140, 30, 30),
			transparency = 0.35,
			parent = model,
		})
		table.insert(arms, arm)
	end

	for i = 1, 4 do
		local angle = (i / 4) * 2 * math.pi
		local organ = makePart({
			name = ("Organ%d"):format(i),
			size = Vector3.new(0.4, 3, 0.4),
			position = headBase + Vector3.new(math.cos(angle) * 0.6, -2, math.sin(angle) * 0.6),
			material = Enum.Material.Neon,
			color = Color3.fromRGB(180, 20, 20),
			transparency = 0.5,
			parent = model,
		})
		attachLight(organ, Color3.fromRGB(255, 30, 30), 1, 3)
	end

	makePart({
		name = "Tongue",
		size = Vector3.new(0.5, 0.5, 2),
		position = headBase + Vector3.new(0, -0.4, -1.5),
		material = Enum.Material.Neon,
		color = Color3.fromRGB(200, 50, 50),
		parent = model,
	})

	attachAura(torso, {
		color = Color3.fromRGB(180, 20, 20),
		lifetimeMin = 2,
		lifetimeMax = 2,
		rate = 12,
		sizeMin = 0.3,
		sizeMax = 1,
		transparency = 0.5,
		speed = 2,
		lightEmission = 1,
	})
	attachLight(torso, Color3.fromRGB(255, 20, 20), 8, 14)
	attachTrail(head, Color3.fromRGB(255, 30, 30), 1.2)

	local orbitConnection: RBXScriptConnection
	local t = 0
	local armT = 0
	orbitConnection = RunService.Heartbeat:Connect(function(dt: number)
		if not head.Parent then
			orbitConnection:Disconnect()
			return
		end
		t += dt * 0.8
		armT += dt
		head.Position = headBase
			+ Vector3.new(math.sin(t) * 2, math.sin(t * 2) * 0.5, math.cos(t) * 1.5)

		for i, arm in ipairs(arms) do
			local phase = (i - 1) * math.pi
			local sideX = (i == 1) and -2.5 or 2.5
			arm.Position = torsoCenter + Vector3.new(sideX + math.sin(armT + phase) * 0.3, 0.5, 0)
		end
	end)

	model.PrimaryPart = head
	attachNameTag(head, "Leak", 2)
	return model
end

local BUILDERS: { [GhostType]: (Vector3) -> Model } = {
	Pocong = buildPocong,
	Genderuwo = buildGenderuwo,
	Kuntilanak = buildKuntilanak,
	Leak = buildLeak,
}

function GhostSpawner.spawnAll(vendorList: { VendorInfo }): { Model }
	local spawned: { Model } = {}
	for _, vendor in ipairs(vendorList) do
		local ghostType = NPC_TO_GHOST[vendor.name]
		if not ghostType then
			warn(("[GhostSpawner] no ghost mapping for vendor %s"):format(vendor.name))
			continue
		end

		local builder = BUILDERS[ghostType]
		local behindOffset = -vendor.lookDirection * BEHIND_DISTANCE
		local ghostX = vendor.position.X + behindOffset.X
		local ghostZ = vendor.position.Z + behindOffset.Z
		local terrainY = MapHelpers.getTerrainY(ghostX, ghostZ)
		local groundPos = Vector3.new(ghostX, terrainY, ghostZ)

		print(
			("[GhostSpawner] Spawning %s (companion of %s) at (%.0f, %.0f, %.0f)..."):format(
				ghostType,
				vendor.name,
				groundPos.X,
				groundPos.Y,
				groundPos.Z
			)
		)

		local ok, ghostOrErr = pcall(builder, groundPos)
		if not ok then
			warn(("[GhostSpawner] %s build FAILED: %s"):format(ghostType, tostring(ghostOrErr)))
			continue
		end

		local ghost = ghostOrErr :: Model
		ghost.Parent = workspace
		table.insert(spawned, ghost)
		print(("[GhostSpawner] %s spawned."):format(ghostType))
	end
	return spawned
end

return GhostSpawner
