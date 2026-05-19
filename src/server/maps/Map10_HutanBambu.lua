--!strict
--[[
	@module      Map10_HutanBambu
	@description Epic map — hutan bambu mystical hijau. Terrain Grass + Mud, 100
	             bambu tinggi (cylinder light green tall), 8 patung wewe gombel
	             samar transparent putih, 3 mata air kecil (water plane biru).
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map10 = {}

local BAMBU_COLOR = Color3.fromRGB(130, 180, 110)
local BAMBU_DARK = Color3.fromRGB(80, 120, 75)
local WEWE_COLOR = Color3.fromRGB(240, 240, 240)
local SPRING_COLOR = Color3.fromRGB(80, 150, 180)

local function buildBambu(base: Vector3, parent: Instance, index: number, random: Random)
	local height = random:NextNumber(16, 24)
	local bambu = Instance.new("Part")
	bambu.Name = ("Bambu%d"):format(index)
	bambu.Shape = Enum.PartType.Cylinder
	bambu.Size = Vector3.new(height, 0.8, 0.8)
	local tilt = math.rad(random:NextNumber(-3, 3))
	bambu.CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0))
		* CFrame.Angles(tilt, 0, math.rad(90))
	bambu.Anchored = true
	bambu.Material = Enum.Material.Wood
	bambu.Color = if random:NextNumber() > 0.7 then BAMBU_DARK else BAMBU_COLOR
	bambu.Parent = parent
end

local function buildWewe(base: Vector3, parent: Instance, index: number)
	local model = Instance.new("Model")
	model.Name = ("WeweGombel%d"):format(index)
	MapHelpers.makePart({
		name = "Body",
		size = Vector3.new(2.5, 6, 1.8),
		position = base + Vector3.new(0, 3, 0),
		material = Enum.Material.Fabric,
		color = WEWE_COLOR,
		transparency = 0.5,
		canCollide = false,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Head",
		size = Vector3.new(1.5, 1.5, 1.5),
		position = base + Vector3.new(0, 6.5, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Fabric,
		color = WEWE_COLOR,
		transparency = 0.5,
		canCollide = false,
		parent = model,
	})
	model.Parent = parent
end

local function buildSpring(base: Vector3, parent: Instance, index: number)
	MapHelpers.makePart({
		name = ("MataAir%d"):format(index),
		size = Vector3.new(6, 0.3, 6),
		position = base + Vector3.new(0, 0.15, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Water,
		color = SPRING_COLOR,
		canCollide = false,
		parent = parent,
	})
end

function Map10.build(mapData: MapData, parent: Instance)
	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Grass)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local center = mapData.offset
	local random = Random.new(1010)

	local bambuCount = MapHelpers.scaledCount(100)
	for i = 1, bambuCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(20, 200)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildBambu(pos, mapModel, i, random)
	end

	local weweCount = MapHelpers.scaledCount(8)
	for i = 1, weweCount do
		local angle = (i / weweCount) * 2 * math.pi
		local r = random:NextNumber(60, 180)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildWewe(pos, mapModel, i)
	end

	local springCount = MapHelpers.scaledCount(3)
	for i = 1, springCount do
		local angle = (i / springCount) * 2 * math.pi
		local r = 50
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildSpring(pos, mapModel, i)
	end

	MapHelpers.buildSpawnMarker(mapData, mapModel)
	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — %d bambu, %d wewe, %d springs."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			bambuCount,
			weweCount,
			springCount
		)
	)
end

return Map10
