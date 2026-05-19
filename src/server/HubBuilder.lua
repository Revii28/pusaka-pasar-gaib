--!strict
--[[
	@module      HubBuilder
	@description Build placeholder Pasar Gaib hub — pivot dari indoor market ke
	             pasar setan outdoor di kebon angker:
	             ground grass 300x300, scatter trees/grass/gravestones di outer
	             ring, SpawnLocation gold di center + petromaks lamp glow orange.
	             Inner Ring (0-25) reserved spawn + leaderboard. Middle Ring
	             (25-60) reserved NPC vendor + kios player. Outer Ring (60-150)
	             dense pohon. Scatter pakai seeded Random (deterministic).
	             Phase 3 Minggu 1 rev2 — diganti terrain artist + custom prop
	             Phase 6+.
	@author      Claude Agent (primary coder)
]]

local HubBuilder = {}

local SCATTER_SEED = 1337

local GROUND_SIZE = Vector3.new(300, 1, 300)
local GROUND_POSITION = Vector3.new(0, -0.5, 0)
local GROUND_COLOR = Color3.fromRGB(60, 75, 50)

local INNER_RING_RADIUS = 25
local MIDDLE_RING_OUTER = 60
local OUTER_RING_OUTER = 150

local TREE_COUNT = 15
local TRUNK_HEIGHT = 15
local TRUNK_DIAMETER = 4
local LEAVES_DIAMETER = 12
local TRUNK_COLOR = Color3.fromRGB(80, 50, 25)
local LEAVES_COLOR = Color3.fromRGB(35, 70, 75)

local GRASS_COUNT = 25
local GRASS_SIZE = Vector3.new(2, 4, 2)
local GRASS_COLOR = Color3.fromRGB(40, 65, 35)

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
local LAMP_LIGHT_BRIGHTNESS = 8
local LAMP_LIGHT_RANGE = 40

local DEFAULT_PART_NAMES: { [string]: boolean } = {
	Baseplate = true,
	SpawnLocation = true,
	Part = true,
}

local function clearDefaultWorld()
	workspace.Terrain:Clear()
	for _, child in workspace:GetChildren() do
		if child:IsA("BasePart") and DEFAULT_PART_NAMES[child.Name] then
			child:Destroy()
		end
	end
	local existingHub = workspace:FindFirstChild("PasarGaibHub")
	if existingHub then
		existingHub:Destroy()
	end
end

local function createGround(parent: Instance): Part
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = GROUND_SIZE
	ground.Position = GROUND_POSITION
	ground.Anchored = true
	ground.Material = Enum.Material.Grass
	ground.Color = GROUND_COLOR
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.BottomSurface = Enum.SurfaceType.Smooth
	ground.Parent = parent
	return ground
end

local function pickOuterRingPosition(random: Random): Vector3
	local angle = random:NextNumber() * 2 * math.pi
	local t = random:NextNumber()
	local radius = MIDDLE_RING_OUTER + math.sqrt(t) * (OUTER_RING_OUTER - MIDDLE_RING_OUTER)
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function pickGrassPosition(random: Random): Vector3
	local angle = random:NextNumber() * 2 * math.pi
	local radius = INNER_RING_RADIUS + random:NextNumber() * (OUTER_RING_OUTER - INNER_RING_RADIUS)
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function buildTree(basePos: Vector3, parent: Instance)
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(TRUNK_HEIGHT, TRUNK_DIAMETER, TRUNK_DIAMETER)
	trunk.CFrame = CFrame.new(basePos.X, TRUNK_HEIGHT / 2, basePos.Z)
		* CFrame.Angles(0, 0, math.rad(90))
	trunk.Anchored = true
	trunk.Material = Enum.Material.WoodPlanks
	trunk.Color = TRUNK_COLOR
	trunk.Parent = parent

	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(LEAVES_DIAMETER, LEAVES_DIAMETER, LEAVES_DIAMETER)
	leaves.Position = Vector3.new(basePos.X, TRUNK_HEIGHT + LEAVES_DIAMETER / 2, basePos.Z)
	leaves.Anchored = true
	leaves.Material = Enum.Material.LeafyGrass
	leaves.Color = LEAVES_COLOR
	leaves.Parent = parent
end

local function buildGrassPatch(basePos: Vector3, parent: Instance)
	local grass = Instance.new("Part")
	grass.Name = "TallGrass"
	grass.Size = GRASS_SIZE
	grass.Position = Vector3.new(basePos.X, GRASS_SIZE.Y / 2, basePos.Z)
	grass.Anchored = true
	grass.CanCollide = false
	grass.Material = Enum.Material.Grass
	grass.Color = GRASS_COLOR
	grass.Parent = parent
end

local function buildGravestone(basePos: Vector3, random: Random, parent: Instance)
	local stone = Instance.new("Part")
	stone.Name = "Gravestone"
	stone.Size = GRAVESTONE_SIZE
	local yawDegrees = random:NextNumber(-20, 20)
	stone.CFrame = CFrame.new(basePos.X, GRAVESTONE_SIZE.Y / 2, basePos.Z)
		* CFrame.Angles(0, math.rad(yawDegrees), math.rad(random:NextNumber(-5, 5)))
	stone.Anchored = true
	stone.Material = Enum.Material.Slate
	stone.Color = GRAVESTONE_COLOR
	stone.Parent = parent
end

local function scatterScene(parent: Instance)
	local random = Random.new(SCATTER_SEED)

	for _ = 1, TREE_COUNT do
		buildTree(pickOuterRingPosition(random), parent)
	end
	for _ = 1, GRASS_COUNT do
		buildGrassPatch(pickGrassPosition(random), parent)
	end
	for _ = 1, GRAVESTONE_COUNT do
		buildGravestone(pickOuterRingPosition(random), random, parent)
	end
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
	light.Brightness = LAMP_LIGHT_BRIGHTNESS
	light.Range = LAMP_LIGHT_RANGE
	light.Parent = lamp
end

function HubBuilder.build(): Model
	clearDefaultWorld()

	local hub = Instance.new("Model")
	hub.Name = "PasarGaibHub"
	hub.Parent = workspace

	createGround(hub)
	scatterScene(hub)
	createSpawn(hub)
	createPetromaks(hub)

	return hub
end

return HubBuilder
