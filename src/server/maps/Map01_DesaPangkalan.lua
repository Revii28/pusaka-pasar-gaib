--!strict
--[[
	@module      Map01_DesaPangkalan
	@description Starter map — desa Jawa kuno tradisional. Grass flat, 8 rumah
	             joglo placeholder (BasePart brown + atap segitiga rumbia kuning),
	             5 pohon kelapa (trunk cylinder + 4 sphere leaves), 1 sumur tua
	             tengah (cylinder stone + ember). Vibe peaceful tutorial.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map01 = {}

local HOUSE_WALL_COLOR = Color3.fromRGB(120, 80, 50)
local HOUSE_ROOF_COLOR = Color3.fromRGB(200, 170, 80)
local TRUNK_COLOR = Color3.fromRGB(90, 60, 30)
local LEAF_COLOR = Color3.fromRGB(40, 110, 60)
local WELL_COLOR = Color3.fromRGB(110, 110, 110)
local WELL_WATER_COLOR = Color3.fromRGB(60, 110, 160)

local function buildHouse(center: Vector3, parent: Instance, index: number)
	local model = Instance.new("Model")
	model.Name = ("Joglo%d"):format(index)
	MapHelpers.makePart({
		name = "Wall",
		size = Vector3.new(12, 10, 12),
		position = center + Vector3.new(0, 5, 0),
		material = Enum.Material.Wood,
		color = HOUSE_WALL_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Roof",
		size = Vector3.new(14, 6, 14),
		position = center + Vector3.new(0, 13, 0),
		material = Enum.Material.Fabric,
		color = HOUSE_ROOF_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Door",
		size = Vector3.new(2.5, 5, 0.4),
		position = center + Vector3.new(0, 2.5, 6.1),
		material = Enum.Material.Wood,
		color = Color3.fromRGB(60, 35, 18),
		parent = model,
	})
	model.Parent = parent
end

local function buildCoconutTree(base: Vector3, parent: Instance, index: number)
	local model = Instance.new("Model")
	model.Name = ("Coconut%d"):format(index)

	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(14, 1.5, 1.5)
	trunk.CFrame = CFrame.new(base + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.Color = TRUNK_COLOR
	trunk.Parent = model

	for i = 1, 4 do
		local angle = math.rad((i - 1) * 90)
		local frondPos = base + Vector3.new(math.cos(angle) * 2.5, 14, math.sin(angle) * 2.5)
		MapHelpers.makePart({
			name = ("Frond%d"):format(i),
			size = Vector3.new(5, 5, 5),
			position = frondPos,
			shape = Enum.PartType.Ball,
			material = Enum.Material.Grass,
			color = LEAF_COLOR,
			parent = model,
		})
	end
	model.Parent = parent
end

local function buildWell(center: Vector3, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Sumur"

	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(3, 5, 5)
	ring.CFrame = CFrame.new(center + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.Material = Enum.Material.Slate
	ring.Color = WELL_COLOR
	ring.Parent = model

	MapHelpers.makePart({
		name = "Water",
		size = Vector3.new(4, 0.2, 4),
		position = center + Vector3.new(0, 2.5, 0),
		material = Enum.Material.Water,
		color = WELL_WATER_COLOR,
		canCollide = false,
		parent = model,
	})
	model.Parent = parent
end

function Map01.build(mapData: MapData, parent: Instance)
	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Grass)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local random = Random.new(101)
	local center = mapData.offset
	local houseCount = MapHelpers.scaledCount(8)
	for i = 1, houseCount do
		local angle = (i / houseCount) * 2 * math.pi
		local r = 50 + random:NextNumber(0, 20)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildHouse(pos, mapModel, i)
	end

	local treeCount = MapHelpers.scaledCount(5)
	for i = 1, treeCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(80, 130)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildCoconutTree(pos, mapModel, i)
	end

	buildWell(center, mapModel)

	MapHelpers.buildSpawnMarker(mapData, mapModel)

	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — %d houses, %d trees."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			houseCount,
			treeCount
		)
	)
end

return Map01
