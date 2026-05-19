--!strict
--[[
	@module      Map02_KuburanMbahBuyut
	@description Common map — kuburan tua angker. Terrain Mud + LeafyGrass mix,
	             30 batu nisan random tilted, 5 pohon dead twisted no leaves,
	             3 cungkup makam (kotak stone + atap rumbia). Lighting metadata
	             NightMisty — actual transition Phase 4+.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map02 = {}

local NISAN_COLOR = Color3.fromRGB(110, 110, 115)
local DEAD_TRUNK_COLOR = Color3.fromRGB(35, 25, 18)
local CUNGKUP_WALL_COLOR = Color3.fromRGB(90, 85, 80)
local CUNGKUP_ROOF_COLOR = Color3.fromRGB(80, 65, 40)

local function buildNisan(position: Vector3, parent: Instance, random: Random, index: number)
	local yaw = math.rad(random:NextNumber(-25, 25))
	local roll = math.rad(random:NextNumber(-8, 8))
	local stone = Instance.new("Part")
	stone.Name = ("Nisan%d"):format(index)
	stone.Size = Vector3.new(1.5, 2, 0.4)
	stone.CFrame = CFrame.new(position + Vector3.new(0, 1, 0)) * CFrame.Angles(0, yaw, roll)
	stone.Anchored = true
	stone.Material = Enum.Material.Slate
	stone.Color = NISAN_COLOR
	stone.Parent = parent
end

local function buildDeadTree(base: Vector3, parent: Instance, index: number, random: Random)
	local model = Instance.new("Model")
	model.Name = ("DeadTree%d"):format(index)

	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(12, 2.5, 2.5)
	trunk.CFrame = CFrame.new(base + Vector3.new(0, 6, 0))
		* CFrame.Angles(0, 0, math.rad(90) + math.rad(random:NextNumber(-5, 5)))
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.Color = DEAD_TRUNK_COLOR
	trunk.Parent = model

	for i = 1, 4 do
		local yaw = random:NextNumber() * 2 * math.pi
		local pitch = math.rad(random:NextNumber(30, 70))
		local len = 3
		local direction = Vector3.new(
			math.cos(yaw) * math.cos(pitch),
			math.sin(pitch),
			math.sin(yaw) * math.cos(pitch)
		)
		local origin = base + Vector3.new(0, 11 + random:NextNumber(-1, 1), 0)
		local twig = Instance.new("Part")
		twig.Name = ("Twig%d"):format(i)
		twig.Size = Vector3.new(0.4, len, 0.4)
		twig.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -len / 2)
		twig.Anchored = true
		twig.Material = Enum.Material.Wood
		twig.Color = DEAD_TRUNK_COLOR
		twig.Parent = model
	end
	model.Parent = parent
end

local function buildCungkup(center: Vector3, parent: Instance, index: number)
	local model = Instance.new("Model")
	model.Name = ("Cungkup%d"):format(index)
	MapHelpers.makePart({
		name = "Walls",
		size = Vector3.new(4, 5, 6),
		position = center + Vector3.new(0, 2.5, 0),
		material = Enum.Material.Slate,
		color = CUNGKUP_WALL_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Roof",
		size = Vector3.new(5, 1, 7),
		position = center + Vector3.new(0, 5.5, 0),
		material = Enum.Material.Fabric,
		color = CUNGKUP_ROOF_COLOR,
		parent = model,
	})
	model.Parent = parent
end

function Map02.build(mapData: MapData, parent: Instance)
	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Mud)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local random = Random.new(202)
	local center = mapData.offset

	local nisanCount = MapHelpers.scaledCount(30)
	for i = 1, nisanCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(15, 140)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildNisan(pos, mapModel, random, i)
	end

	local deadTreeCount = MapHelpers.scaledCount(5)
	for i = 1, deadTreeCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(40, 150)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildDeadTree(pos, mapModel, i, random)
	end

	local cungkupCount = MapHelpers.scaledCount(3)
	for i = 1, cungkupCount do
		local angle = (i / cungkupCount) * 2 * math.pi
		local r = 80
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildCungkup(pos, mapModel, i)
	end

	MapHelpers.buildSpawnMarker(mapData, mapModel)

	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — %d nisan, %d dead trees, %d cungkup."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			nisanCount,
			deadTreeCount,
			cungkupCount
		)
	)
end

return Map02
