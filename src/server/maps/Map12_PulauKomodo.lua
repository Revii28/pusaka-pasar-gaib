--!strict
--[[
	@module      Map12_PulauKomodo
	@description Legendary map — pulau Komodo mistis pantai vibe. Terrain Sand
	             + Grass + Water sekitar, 1 mountain center (Block rock gray
	             100x50x100), 20 pohon kelapa, 3 hut bambu, 8 batu candi kuno,
	             1 patung naga raksasa placeholder, 5 obor pantai.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map12 = {}

local MOUNTAIN_COLOR = Color3.fromRGB(95, 90, 85)
local TRUNK_COLOR = Color3.fromRGB(90, 60, 30)
local LEAF_COLOR = Color3.fromRGB(50, 130, 70)
local HUT_WALL = Color3.fromRGB(150, 130, 85)
local HUT_ROOF = Color3.fromRGB(180, 150, 80)
local ANCIENT_STONE = Color3.fromRGB(90, 85, 80)
local DRAGON_COLOR = Color3.fromRGB(70, 80, 60)

local function buildMountain(center: Vector3, parent: Instance)
	MapHelpers.makePart({
		name = "Mountain",
		size = Vector3.new(100, 50, 100),
		position = center + Vector3.new(0, 25, 0),
		material = Enum.Material.Rock,
		color = MOUNTAIN_COLOR,
		parent = parent,
	})
end

local function buildCoconut(base: Vector3, parent: Instance, index: number, random: Random)
	local model = Instance.new("Model")
	model.Name = ("Kelapa%d"):format(index)
	local h = random:NextNumber(12, 16)
	local trunk = Instance.new("Part")
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(h, 1.3, 1.3)
	trunk.CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0))
		* CFrame.Angles(0, 0, math.rad(90) + math.rad(random:NextNumber(-5, 5)))
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.Color = TRUNK_COLOR
	trunk.Parent = model
	for i = 1, 4 do
		local angle = math.rad((i - 1) * 90)
		MapHelpers.makePart({
			name = ("Frond%d"):format(i),
			size = Vector3.new(4.5, 4.5, 4.5),
			position = base + Vector3.new(math.cos(angle) * 2.2, h, math.sin(angle) * 2.2),
			shape = Enum.PartType.Ball,
			material = Enum.Material.Grass,
			color = LEAF_COLOR,
			parent = model,
		})
	end
	model.Parent = parent
end

local function buildHut(center: Vector3, parent: Instance, index: number)
	local model = Instance.new("Model")
	model.Name = ("HutBambu%d"):format(index)
	MapHelpers.makePart({
		name = "Walls",
		size = Vector3.new(6, 5, 6),
		position = center + Vector3.new(0, 2.5, 0),
		material = Enum.Material.Wood,
		color = HUT_WALL,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Roof",
		size = Vector3.new(8, 1.5, 8),
		position = center + Vector3.new(0, 5.75, 0),
		material = Enum.Material.Fabric,
		color = HUT_ROOF,
		parent = model,
	})
	model.Parent = parent
end

local function buildAncientStone(base: Vector3, parent: Instance, index: number, random: Random)
	MapHelpers.makePart({
		name = ("CandiKuno%d"):format(index),
		size = Vector3.new(
			random:NextNumber(3, 5),
			random:NextNumber(4, 7),
			random:NextNumber(3, 5)
		),
		position = base + Vector3.new(0, 3, 0),
		material = Enum.Material.Slate,
		color = ANCIENT_STONE,
		parent = parent,
	})
end

local function buildNagaStatue(position: Vector3, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "PatungNagaRaksasa"
	MapHelpers.makePart({
		name = "Body",
		size = Vector3.new(30, 20, 10),
		position = position + Vector3.new(0, 10, 0),
		material = Enum.Material.Slate,
		color = DRAGON_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Head",
		size = Vector3.new(12, 15, 10),
		position = position + Vector3.new(13, 22, 0),
		material = Enum.Material.Slate,
		color = DRAGON_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Tail",
		size = Vector3.new(15, 6, 6),
		position = position + Vector3.new(-20, 8, 0),
		material = Enum.Material.Slate,
		color = DRAGON_COLOR,
		parent = model,
	})
	model.Parent = parent
end

function Map12.build(mapData: MapData, parent: Instance)
	-- Spawn platform FIRST sebelum apa-apa — guarantee solid landing pad.
	MapHelpers.buildSpawnPlatform(mapData.spawnPos, mapData.id, parent)

	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Sand)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local center = mapData.offset
	local random = Random.new(1212)

	-- Bug 2 fix: main island BasePart sebagai backup floor (anti-void-fall).
	-- Stone slab 200x2x200 di Y=-1 (top Y=0) di bawah spawn area, ekspand pulau
	-- visual padat agar player gak jatuh ke void kalau terrain miss.
	MapHelpers.makePart({
		name = "MainIslandBase",
		size = Vector3.new(200, 2, 200),
		position = center + Vector3.new(0, -1, 0),
		material = Enum.Material.Sandstone,
		color = Color3.fromRGB(180, 160, 130),
		parent = mapModel,
	})

	buildMountain(center, mapModel)
	buildNagaStatue(center + Vector3.new(80, 0, 80), mapModel)

	local kelapaCount = MapHelpers.scaledCount(20)
	for i = 1, kelapaCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(100, 230)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildCoconut(pos, mapModel, i, random)
	end

	local hutCount = MapHelpers.scaledCount(3)
	for i = 1, hutCount do
		local angle = math.rad(45 + (i - 1) * 120)
		local r = 130
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildHut(pos, mapModel, i)
	end

	local stoneCount = MapHelpers.scaledCount(8)
	for i = 1, stoneCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(80, 200)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildAncientStone(pos, mapModel, i, random)
	end

	for i = 1, 5 do
		local angle = math.rad((i - 1) * 72)
		local r = 220
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		MapHelpers.buildSimpleTorch(pos, mapModel, Color3.fromRGB(255, 140, 60))
	end

	MapHelpers.buildSpawnMarker(mapData, mapModel)
	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — mountain, dragon statue, %d kelapa, %d hut, %d stone, 5 torch."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			kelapaCount,
			hutCount,
			stoneCount
		)
	)
end

return Map12
