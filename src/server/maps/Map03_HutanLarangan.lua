--!strict
--[[
	@module      Map03_HutanLarangan
	@description Uncommon map — hutan padat angker. Terrain Grass dark + LeafyGrass
	             patches mix, 60 pohon padat (trunk + 3-4 leaf cluster sphere),
	             20 semak (sphere green cluster), 8 batu besar moss, trail Mud
	             sempit dari spawn ke center.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map03 = {}

local TRUNK_COLOR = Color3.fromRGB(60, 40, 25)
local LEAF_BASE = Color3.fromRGB(40, 75, 45)
local SEMAK_COLOR = Color3.fromRGB(50, 90, 50)
local ROCK_COLOR = Color3.fromRGB(85, 90, 80)

local function buildForestTree(base: Vector3, parent: Instance, random: Random, index: number)
	local model = Instance.new("Model")
	model.Name = ("Tree%d"):format(index)

	local trunkHeight = random:NextNumber(10, 16)
	local trunkDiameter = random:NextNumber(2, 3.5)
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(trunkHeight, trunkDiameter, trunkDiameter)
	trunk.CFrame = CFrame.new(base + Vector3.new(0, trunkHeight / 2, 0))
		* CFrame.Angles(0, 0, math.rad(90) + math.rad(random:NextNumber(-4, 4)))
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.Color = TRUNK_COLOR
	trunk.Parent = model

	local leafCount = random:NextInteger(3, 4)
	for i = 1, leafCount do
		local diameter = random:NextNumber(6, 9)
		local offsetY = trunkHeight + random:NextNumber(0, 3)
		MapHelpers.makePart({
			name = ("Leaves%d"):format(i),
			size = Vector3.new(diameter, diameter, diameter),
			position = base
				+ Vector3.new(random:NextNumber(-2.5, 2.5), offsetY, random:NextNumber(-2.5, 2.5)),
			shape = Enum.PartType.Ball,
			material = Enum.Material.LeafyGrass,
			color = Color3.new(
				LEAF_BASE.R + random:NextNumber(-0.05, 0.05),
				LEAF_BASE.G + random:NextNumber(-0.08, 0.08),
				LEAF_BASE.B + random:NextNumber(-0.05, 0.05)
			),
			parent = model,
		})
	end
	model.Parent = parent
end

local function buildSemak(base: Vector3, parent: Instance, index: number, random: Random)
	local model = Instance.new("Model")
	model.Name = ("Semak%d"):format(index)
	for i = 1, 3 do
		MapHelpers.makePart({
			name = ("Bush%d"):format(i),
			size = Vector3.new(
				random:NextNumber(2.5, 4),
				random:NextNumber(2, 3),
				random:NextNumber(2.5, 4)
			),
			position = base + Vector3.new(random:NextNumber(-1, 1), 1.5, random:NextNumber(-1, 1)),
			shape = Enum.PartType.Ball,
			material = Enum.Material.LeafyGrass,
			color = SEMAK_COLOR,
			parent = model,
		})
	end
	model.Parent = parent
end

local function buildMossyRock(base: Vector3, parent: Instance, index: number, random: Random)
	MapHelpers.makePart({
		name = ("Rock%d"):format(index),
		size = Vector3.new(
			random:NextNumber(4, 7),
			random:NextNumber(3, 5),
			random:NextNumber(4, 7)
		),
		position = base + Vector3.new(0, 2, 0),
		material = Enum.Material.Rock,
		color = ROCK_COLOR,
		parent = parent,
	})
end

function Map03.build(mapData: MapData, parent: Instance)
	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Grass)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local random = Random.new(303)
	local center = mapData.offset

	local treeCount = MapHelpers.scaledCount(60)
	for i = 1, treeCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(20, 180)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildForestTree(pos, mapModel, random, i)
	end

	local semakCount = MapHelpers.scaledCount(20)
	for i = 1, semakCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(15, 170)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildSemak(pos, mapModel, i, random)
	end

	local rockCount = MapHelpers.scaledCount(8)
	for i = 1, rockCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(40, 150)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildMossyRock(pos, mapModel, i, random)
	end

	MapHelpers.makePart({
		name = "Trail",
		size = Vector3.new(4, 0.2, 130),
		position = center + Vector3.new(0, 0.1, -65),
		material = Enum.Material.Mud,
		color = Color3.fromRGB(80, 55, 35),
		canCollide = false,
		parent = mapModel,
	})

	MapHelpers.buildSpawnMarker(mapData, mapModel)

	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — %d trees, %d semak, %d rocks."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			treeCount,
			semakCount,
			rockCount
		)
	)
end

return Map03
