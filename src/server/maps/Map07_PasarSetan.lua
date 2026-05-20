--!strict
--[[
	@module      Map07_PasarSetan
	@description Epic map — pasar setan terbengkalai vibe blood-moon. Terrain
	             Mud dark + CrackedLava patches, 20 kios reyot rusak (Part wood
	             broken + atap rumbia sobek), 1 lampion gantung tinggi center
	             (Neon red), 10 setan figure samar transparent dark purple, 30
	             tulang scattered.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map07 = {}

local KIOS_WALL = Color3.fromRGB(60, 40, 25)
local KIOS_ROOF = Color3.fromRGB(110, 75, 40)
local LAMPION_RED = Color3.fromRGB(200, 30, 30)
local SETAN_COLOR = Color3.fromRGB(40, 25, 50)
local BONE_COLOR = Color3.fromRGB(230, 220, 200)

local function buildBrokenKios(base: Vector3, parent: Instance, index: number, random: Random)
	local model = Instance.new("Model")
	model.Name = ("KiosReyot%d"):format(index)
	local tilt = math.rad(random:NextNumber(-8, 8))
	MapHelpers.makePart({
		name = "Wall",
		size = Vector3.new(4, 6, 4),
		cframe = CFrame.new(base + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, tilt),
		material = Enum.Material.Wood,
		color = KIOS_WALL,
		parent = model,
	})
	MapHelpers.makePart({
		name = "RoofBroken",
		size = Vector3.new(5, 0.4, 5),
		cframe = CFrame.new(base + Vector3.new(0, 6.5, 0))
			* CFrame.Angles(math.rad(random:NextNumber(-10, 10)), 0, tilt),
		material = Enum.Material.Fabric,
		color = KIOS_ROOF,
		parent = model,
	})
	model.Parent = parent
end

local function buildCenterLampion(center: Vector3, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "GiantLampion"
	MapHelpers.makePart({
		name = "Pole",
		size = Vector3.new(0.5, 40, 0.5),
		position = center + Vector3.new(0, 20, 0),
		material = Enum.Material.Wood,
		color = Color3.fromRGB(30, 20, 15),
		parent = model,
	})
	local bulb = MapHelpers.makePart({
		name = "Bulb",
		size = Vector3.new(8, 8, 8),
		position = center + Vector3.new(0, 36, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Neon,
		color = LAMPION_RED,
		transparency = 0.1,
		canCollide = false,
		parent = model,
	})
	local light = Instance.new("PointLight")
	light.Color = LAMPION_RED
	light.Brightness = 8
	light.Range = 60
	light.Parent = bulb
	model.Parent = parent
end

local function buildSetanFigure(base: Vector3, parent: Instance, index: number, random: Random)
	local model = Instance.new("Model")
	model.Name = ("Setan%d"):format(index)
	MapHelpers.makePart({
		name = "Body",
		size = Vector3.new(2, 6, 1.5),
		position = base + Vector3.new(0, 3, 0),
		material = Enum.Material.Plastic,
		color = SETAN_COLOR,
		transparency = 0.7,
		canCollide = false,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Head",
		size = Vector3.new(1.5, 1.5, 1.5),
		position = base + Vector3.new(0, 6.5, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Plastic,
		color = SETAN_COLOR,
		transparency = 0.7,
		canCollide = false,
		parent = model,
	})
	model.Parent = parent
	local _ = random
end

local function buildBone(base: Vector3, parent: Instance, index: number, random: Random)
	MapHelpers.makePart({
		name = ("Bone%d"):format(index),
		size = Vector3.new(0.4, random:NextNumber(1.5, 3), 0.4),
		cframe = CFrame.new(base + Vector3.new(0, 0.5, 0))
			* CFrame.Angles(math.rad(random:NextNumber(0, 360)), 0, math.rad(85)),
		material = Enum.Material.Sand,
		color = BONE_COLOR,
		canCollide = false,
		parent = parent,
	})
end

function Map07.build(mapData: MapData, parent: Instance)
	-- Spawn platform + Gauntlet (3 room + boss arena, theme rooftop).
	MapHelpers.buildSpawnPlatform(mapData.spawnPos, mapData.id, parent)
	MapHelpers.getGauntletService().buildGauntlet(mapData.id, mapData.offset)

	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Mud)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local center = mapData.offset
	local random = Random.new(707)

	buildCenterLampion(center, mapModel)

	local kiosCount = MapHelpers.scaledCount(20)
	for i = 1, kiosCount do
		local angle = (i / kiosCount) * 2 * math.pi
		local r = random:NextNumber(40, 130)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildBrokenKios(pos, mapModel, i, random)
	end

	local setanCount = MapHelpers.scaledCount(10)
	for i = 1, setanCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(50, 180)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildSetanFigure(pos, mapModel, i, random)
	end

	local boneCount = MapHelpers.scaledCount(30)
	for i = 1, boneCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(15, 180)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildBone(pos, mapModel, i, random)
	end

	MapHelpers.buildSpawnMarker(mapData, mapModel)
	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — giant red lampion, %d kios, %d setan, %d bones."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			kiosCount,
			setanCount,
			boneCount
		)
	)
end

return Map07
