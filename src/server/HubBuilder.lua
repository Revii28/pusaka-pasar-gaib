--!strict
--[[
	@module      HubBuilder
	@description Build Pasar Setan kebon: Roblox Terrain real (FillBlock Grass
	             400x10x400 base + scattered Mud edge patches + LeafyGrass outer
	             ring belts), Decoration=true + GrassLength=1.5 untuk auto rumput
	             blade. Layered trees outer ring (3-segment trunk dengan tilt
	             random per segment + bark ridge sim + 2-3 thin branches +
	             4-6 sphere leaves cluster); 25% chance jadi pohon mati twisted.
	             Trunk base dibungkus ParticleEmitter mist tipis. Gravestones
	             Slate dengan tilt random. Center punya SpawnLocation gold +
	             petromaks lamp glow orange.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local HubBuilder = {}

local SCATTER_SEED = 1337

local TERRAIN_BLOCK_CFRAME = CFrame.new(0, -5, 0)
local TERRAIN_BLOCK_SIZE = Vector3.new(400, 10, 400)
local TERRAIN_GRASS_LENGTH = 1.5

local MUD_PATCH_MIN = 8
local MUD_PATCH_MAX = 12
local MUD_PATCH_RADIUS_MIN = 110
local MUD_PATCH_RADIUS_MAX = 180
local MUD_PATCH_HALF = Vector3.new(15, 1.5, 15)

local LEAFY_PATCH_MIN = 3
local LEAFY_PATCH_MAX = 4
local LEAFY_PATCH_RADIUS_MIN = 80
local LEAFY_PATCH_RADIUS_MAX = 140
local LEAFY_PATCH_HALF = Vector3.new(30, 1.5, 30)

local MIDDLE_RING_OUTER = 60
local OUTER_RING_OUTER = 150

local TREE_COUNT = 15
local DEAD_TREE_CHANCE = 0.25

local TRUNK_BASE_COLOR = Color3.fromRGB(80, 55, 30)
local TRUNK_DEAD_COLOR = Color3.fromRGB(40, 30, 20)
local LEAF_BASE_COLORS: { Color3 } = {
	Color3.fromRGB(35, 75, 45),
	Color3.fromRGB(45, 85, 50),
	Color3.fromRGB(40, 70, 45),
	Color3.fromRGB(50, 80, 55),
}

local GRAVESTONE_COUNT = 6
local GRAVESTONE_SIZE = Vector3.new(2, 3, 1)
local GRAVESTONE_COLOR = Color3.fromRGB(120, 120, 125)

local SPAWN_SIZE = Vector3.new(8, 1, 8)
local SPAWN_POSITION = Vector3.new(0, 0.5, 0)
local SPAWN_COLOR = Color3.fromRGB(212, 175, 55)

local LAMP_SIZE = Vector3.new(3, 1, 1)
local LAMP_POSITION = Vector3.new(0, 12, 0)
local LAMP_COLOR = Color3.fromRGB(100, 70, 30)
local LAMP_LIGHT_COLOR = Color3.fromRGB(255, 180, 80)
local LAMP_LIGHT_BRIGHTNESS_NIGHT = 8
local LAMP_LIGHT_BRIGHTNESS_DAY = 2
local LAMP_LIGHT_RANGE = 40

local DEFAULT_PART_NAMES: { [string]: boolean } = {
	Baseplate = true,
	SpawnLocation = true,
	Part = true,
}

local function clearDefaultWorld()
	workspace.Terrain:Clear()
	print("[HubBuilder] Terrain cleared.")
	for _, child in workspace:GetChildren() do
		if child:IsA("BasePart") and DEFAULT_PART_NAMES[child.Name] then
			child:Destroy()
		end
	end
	local existingHub = workspace:FindFirstChild("PasarGaibHub")
	if existingHub then
		existingHub:Destroy()
	end
	print("[HubBuilder] Default world cleared.")
end

local function buildTerrainBase(random: Random)
	local terrain = workspace.Terrain
	terrain:FillBlock(TERRAIN_BLOCK_CFRAME, TERRAIN_BLOCK_SIZE, Enum.Material.Grass)
	print("[HubBuilder] Terrain filled with grass (400x10x400).")

	local mudCount = random:NextInteger(MUD_PATCH_MIN, MUD_PATCH_MAX)
	local mudSuccess = 0
	for _ = 1, mudCount do
		local angle = random:NextNumber() * 2 * math.pi
		local radius = random:NextNumber(MUD_PATCH_RADIUS_MIN, MUD_PATCH_RADIUS_MAX)
		local center = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local region = Region3.new(center - MUD_PATCH_HALF, center + MUD_PATCH_HALF)
		local ok, err = pcall(function()
			terrain:FillRegion(region:ExpandToGrid(4), 4, Enum.Material.Mud)
		end)
		if ok then
			mudSuccess += 1
		else
			warn(("[HubBuilder] Mud FillRegion failed: %s"):format(tostring(err)))
		end
	end
	print(("[HubBuilder] %d/%d mud patches scattered."):format(mudSuccess, mudCount))

	local leafyCount = random:NextInteger(LEAFY_PATCH_MIN, LEAFY_PATCH_MAX)
	local leafySuccess = 0
	for _ = 1, leafyCount do
		local angle = random:NextNumber() * 2 * math.pi
		local radius = random:NextNumber(LEAFY_PATCH_RADIUS_MIN, LEAFY_PATCH_RADIUS_MAX)
		local center = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local region = Region3.new(center - LEAFY_PATCH_HALF, center + LEAFY_PATCH_HALF)
		local ok, err = pcall(function()
			terrain:FillRegion(region:ExpandToGrid(4), 4, Enum.Material.LeafyGrass)
		end)
		if ok then
			leafySuccess += 1
		else
			warn(("[HubBuilder] Leafy FillRegion failed: %s"):format(tostring(err)))
		end
	end
	print(("[HubBuilder] %d/%d leafy patches scattered."):format(leafySuccess, leafyCount))

	local decoOk, decoErr = pcall(function()
		terrain.Decoration = true
		terrain.GrassLength = TERRAIN_GRASS_LENGTH
	end)
	if decoOk then
		print(
			("[HubBuilder] Auto-grass decoration enabled (length %.1f)."):format(
				TERRAIN_GRASS_LENGTH
			)
		)
	else
		warn(
			("[HubBuilder] Terrain.Decoration/GrassLength not supported — skipped: %s"):format(
				tostring(decoErr)
			)
		)
	end
end

local function jitterColor(base: Color3, random: Random, amount: number): Color3
	local r = math.clamp(base.R + random:NextNumber(-amount, amount), 0, 1)
	local g = math.clamp(base.G + random:NextNumber(-amount, amount), 0, 1)
	local b = math.clamp(base.B + random:NextNumber(-amount, amount), 0, 1)
	return Color3.new(r, g, b)
end

local function buildTrunkSegment(
	parent: Instance,
	name: string,
	length: number,
	diameter: number,
	centerPos: Vector3,
	tiltDegrees: number,
	color: Color3
)
	local segment = Instance.new("Part")
	segment.Name = name
	segment.Shape = Enum.PartType.Cylinder
	segment.Size = Vector3.new(length, diameter, diameter)
	segment.CFrame = CFrame.new(centerPos)
		* CFrame.Angles(0, 0, math.rad(90) + math.rad(tiltDegrees))
	segment.Anchored = true
	segment.Material = Enum.Material.Wood
	segment.Color = color
	segment.TopSurface = Enum.SurfaceType.Smooth
	segment.BottomSurface = Enum.SurfaceType.Smooth
	segment.Parent = parent
end

local function buildBarkRidges(
	parent: Instance,
	trunkCenter: Vector3,
	trunkHalfHeight: number,
	trunkRadius: number,
	color: Color3,
	random: Random
)
	local ridgeCount = random:NextInteger(2, 3)
	for i = 1, ridgeCount do
		local angle = random:NextNumber() * 2 * math.pi
		local ridgePos = trunkCenter
			+ Vector3.new(
				math.cos(angle) * (trunkRadius - 0.1),
				random:NextNumber(-trunkHalfHeight * 0.5, trunkHalfHeight * 0.5),
				math.sin(angle) * (trunkRadius - 0.1)
			)
		local ridge = Instance.new("Part")
		ridge.Name = ("BarkRidge%d"):format(i)
		ridge.Size = Vector3.new(0.5, 3, 0.5)
		ridge.CFrame = CFrame.new(ridgePos)
		ridge.Anchored = true
		ridge.Material = Enum.Material.Wood
		ridge.Color = color
		ridge.Parent = parent
	end
end

local function buildBranch(
	parent: Instance,
	branchOrigin: Vector3,
	random: Random,
	color: Color3,
	index: number
)
	local yaw = random:NextNumber() * 2 * math.pi
	local pitch = math.rad(random:NextNumber(20, 60))
	local length = 4
	local direction = Vector3.new(
		math.cos(yaw) * math.cos(pitch),
		math.sin(pitch),
		math.sin(yaw) * math.cos(pitch)
	)

	local branch = Instance.new("Part")
	branch.Name = ("Branch%d"):format(index)
	branch.Shape = Enum.PartType.Cylinder
	branch.Size = Vector3.new(length, 1.5, 1.5)
	branch.CFrame = CFrame.lookAt(branchOrigin, branchOrigin + direction)
		* CFrame.new(0, 0, -length / 2)
		* CFrame.Angles(0, math.rad(90), 0)
	branch.Anchored = true
	branch.Material = Enum.Material.Wood
	branch.Color = color
	branch.Parent = parent
end

local function buildLeafCluster(parent: Instance, trunkX: number, trunkZ: number, random: Random)
	local maxLeaves = math.max(4, math.min(6, Constants.PERFORMANCE.TREE_LEAF_COUNT_MAX))
	local sphereCount = random:NextInteger(4, maxLeaves)
	for i = 1, sphereCount do
		local diameter = random:NextNumber(6, 10)
		local offsetX = random:NextNumber(-3, 3)
		local offsetZ = random:NextNumber(-3, 3)
		local offsetY = random:NextNumber(12, 16)
		local color = LEAF_BASE_COLORS[((i - 1) % #LEAF_BASE_COLORS) + 1]

		local leafSphere = Instance.new("Part")
		leafSphere.Name = ("Leaves%d"):format(i)
		leafSphere.Shape = Enum.PartType.Ball
		leafSphere.Size = Vector3.new(diameter, diameter, diameter)
		leafSphere.Position = Vector3.new(trunkX + offsetX, offsetY, trunkZ + offsetZ)
		leafSphere.Anchored = true
		leafSphere.Material = Enum.Material.LeafyGrass
		leafSphere.Color = jitterColor(color, random, 0.05)
		leafSphere.Parent = parent
	end
end

local function buildDeadBranches(
	parent: Instance,
	trunkX: number,
	trunkZ: number,
	random: Random,
	color: Color3
)
	local branchCount = random:NextInteger(4, 5)
	for i = 1, branchCount do
		local yaw = random:NextNumber() * 2 * math.pi
		local pitch = math.rad(random:NextNumber(30, 80))
		local length = 3
		local origin = Vector3.new(trunkX, 13 + random:NextNumber(-1, 2), trunkZ)
		local direction = Vector3.new(
			math.cos(yaw) * math.cos(pitch),
			math.sin(pitch),
			math.sin(yaw) * math.cos(pitch)
		)

		local twig = Instance.new("Part")
		twig.Name = ("DeadTwig%d"):format(i)
		twig.Size = Vector3.new(0.5, length, 0.5)
		twig.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -length / 2)
		twig.Anchored = true
		twig.Material = Enum.Material.Wood
		twig.Color = color
		twig.Parent = parent
	end
end

local function attachTrunkMist(parent: Part)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "TrunkMist"
	emitter.Color = ColorSequence.new(Color3.fromRGB(220, 215, 230))
	emitter.Lifetime = NumberRange.new(2, 4)
	emitter.Rate = 2
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 3),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Speed = NumberRange.new(0.3)
	emitter.SpreadAngle = Vector2.new(120, 120)
	emitter.Parent = parent
end

local function generateTree(position: Vector3, isDead: boolean, parent: Instance, random: Random)
	local model = Instance.new("Model")
	model.Name = if isDead then "DeadTree" else "Tree"

	local trunkColor = if isDead then TRUNK_DEAD_COLOR else TRUNK_BASE_COLOR
	local bottomColor = jitterColor(trunkColor, random, 0.04)
	local middleColor = jitterColor(trunkColor, random, 0.04)
	local topColor = jitterColor(trunkColor, random, 0.04)

	local bottomCenter = position + Vector3.new(0, 3, 0)
	local middleCenter = position + Vector3.new(0, 8.5, 0)
	local topCenter = position + Vector3.new(0, 13, 0)

	buildTrunkSegment(model, "TrunkBottom", 6, 4, bottomCenter, 0, bottomColor)
	buildTrunkSegment(
		model,
		"TrunkMiddle",
		5,
		3.5,
		middleCenter,
		random:NextNumber(-8, 8),
		middleColor
	)
	buildTrunkSegment(model, "TrunkTop", 4, 3, topCenter, random:NextNumber(-10, 10), topColor)
	buildBarkRidges(model, bottomCenter, 3, 2, jitterColor(trunkColor, random, 0.06), random)

	local trunkRoot = model:FindFirstChild("TrunkBottom") :: Part?
	if trunkRoot then
		attachTrunkMist(trunkRoot)
	end

	if isDead then
		buildDeadBranches(model, position.X, position.Z, random, topColor)
	else
		local branchCount = random:NextInteger(2, 3)
		for i = 1, branchCount do
			local branchOrigin = position + Vector3.new(0, random:NextNumber(9, 13), 0)
			buildBranch(model, branchOrigin, random, middleColor, i)
		end
		buildLeafCluster(model, position.X, position.Z, random)
	end

	model.Parent = parent
end

local function pickOuterRingPosition(random: Random): Vector3
	local angle = random:NextNumber() * 2 * math.pi
	local t = random:NextNumber()
	local radius = MIDDLE_RING_OUTER + math.sqrt(t) * (OUTER_RING_OUTER - MIDDLE_RING_OUTER)
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function buildGravestone(basePos: Vector3, random: Random, parent: Instance)
	local stone = Instance.new("Part")
	stone.Name = "Gravestone"
	stone.Size = GRAVESTONE_SIZE
	local yawDegrees = random:NextNumber(-20, 20)
	local rollDegrees = random:NextNumber(-5, 5)
	stone.CFrame = CFrame.new(basePos.X, GRAVESTONE_SIZE.Y / 2, basePos.Z)
		* CFrame.Angles(0, math.rad(yawDegrees), math.rad(rollDegrees))
	stone.Anchored = true
	stone.Material = Enum.Material.Slate
	stone.Color = GRAVESTONE_COLOR
	stone.Parent = parent
end

local function scatterScene(parent: Instance, random: Random)
	local treeSuccess = 0
	local deadTreeCount = 0
	for i = 1, TREE_COUNT do
		local pos = pickOuterRingPosition(random)
		local isDead = random:NextNumber() < DEAD_TREE_CHANCE
		local ok, err = pcall(function()
			generateTree(pos, isDead, parent, random)
		end)
		if ok then
			treeSuccess += 1
			if isDead then
				deadTreeCount += 1
			end
		else
			warn(("[HubBuilder] Tree %d generation failed: %s"):format(i, tostring(err)))
		end
	end
	print(
		("[HubBuilder] %d/%d trees scattered (%d dead variants)."):format(
			treeSuccess,
			TREE_COUNT,
			deadTreeCount
		)
	)

	local graveSuccess = 0
	for i = 1, GRAVESTONE_COUNT do
		local ok, err = pcall(function()
			buildGravestone(pickOuterRingPosition(random), random, parent)
		end)
		if ok then
			graveSuccess += 1
		else
			warn(("[HubBuilder] Gravestone %d failed: %s"):format(i, tostring(err)))
		end
	end
	print(("[HubBuilder] %d/%d gravestones scattered."):format(graveSuccess, GRAVESTONE_COUNT))
end

local function createSpawn(parent: Instance): SpawnLocation
	local spawnPad = Instance.new("SpawnLocation")
	spawnPad.Name = "HubSpawn"
	spawnPad.Size = SPAWN_SIZE
	spawnPad.Position = SPAWN_POSITION
	spawnPad.Anchored = true
	spawnPad.Material = Enum.Material.Wood
	spawnPad.Color = SPAWN_COLOR
	spawnPad.TopSurface = Enum.SurfaceType.Smooth
	spawnPad.BottomSurface = Enum.SurfaceType.Smooth
	spawnPad.Neutral = true
	spawnPad.Parent = parent
	return spawnPad
end

local function createPetromaks(parent: Instance)
	local lamp = Instance.new("Part")
	lamp.Name = "Petromaks"
	lamp.Shape = Enum.PartType.Cylinder
	lamp.Size = LAMP_SIZE
	lamp.CFrame = CFrame.new(LAMP_POSITION) * CFrame.Angles(0, 0, math.rad(90))
	lamp.Anchored = true
	lamp.CanCollide = false
	lamp.Material = Enum.Material.Metal
	lamp.Color = LAMP_COLOR
	lamp.Parent = parent

	local light = Instance.new("PointLight")
	light.Name = "PetromaksGlow"
	light.Color = LAMP_LIGHT_COLOR
	light.Brightness = if Constants.LIGHTING_PRESET == "MYSTIC_NIGHT"
		then LAMP_LIGHT_BRIGHTNESS_NIGHT
		else LAMP_LIGHT_BRIGHTNESS_DAY
	light.Range = LAMP_LIGHT_RANGE
	light.Parent = lamp
end

local function safeStep(label: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		warn(("[HubBuilder] %s FAILED: %s"):format(label, tostring(err)))
	end
end

function HubBuilder.build(): Model
	safeStep("clearDefaultWorld", clearDefaultWorld)

	local random = Random.new(SCATTER_SEED)
	safeStep("buildTerrainBase", function()
		buildTerrainBase(random)
	end)

	local hub = Instance.new("Model")
	hub.Name = "PasarGaibHub"
	hub.Parent = workspace

	safeStep("scatterScene", function()
		scatterScene(hub, random)
	end)
	safeStep("createSpawn", function()
		createSpawn(hub)
		print("[HubBuilder] SpawnLocation placed at (0, 0.5, 0).")
	end)
	safeStep("createPetromaks", function()
		createPetromaks(hub)
		local brightnessLabel = if Constants.LIGHTING_PRESET == "MYSTIC_NIGHT"
			then "night/8"
			else "day/2"
		print(("[HubBuilder] Petromaks lit (%s)."):format(brightnessLabel))
	end)

	print(("[HubBuilder] Hub model assembled with %d descendants."):format(#hub:GetDescendants()))
	return hub
end

return HubBuilder
