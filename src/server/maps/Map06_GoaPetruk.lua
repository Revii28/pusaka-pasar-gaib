--!strict
--[[
	@module      Map06_GoaPetruk
	@description Rare map — goa karst labirin. Terrain Rock semua di Y=-100,
	             ceiling block 350x5x350 di Y=-80 buat efek tertutup, 20
	             stalaktit gantung ceiling, 15 stalakmit naik dari floor, 5 obor
	             wall, 3 genangan air kecil di floor.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map06 = {}

local ROCK_COLOR = Color3.fromRGB(70, 65, 60)
local CEILING_COLOR = Color3.fromRGB(45, 40, 38)
local PUDDLE_COLOR = Color3.fromRGB(50, 70, 90)

local function buildStalactite(position: Vector3, parent: Instance, random: Random, index: number)
	local len = random:NextNumber(4, 8)
	MapHelpers.makePart({
		name = ("Stalactite%d"):format(index),
		size = Vector3.new(random:NextNumber(1, 2.5), len, random:NextNumber(1, 2.5)),
		position = position - Vector3.new(0, len / 2, 0),
		material = Enum.Material.Rock,
		color = ROCK_COLOR,
		parent = parent,
	})
end

local function buildStalagmite(base: Vector3, parent: Instance, random: Random, index: number)
	local h = random:NextNumber(3, 7)
	MapHelpers.makePart({
		name = ("Stalagmite%d"):format(index),
		size = Vector3.new(random:NextNumber(1.5, 3), h, random:NextNumber(1.5, 3)),
		position = base + Vector3.new(0, h / 2, 0),
		material = Enum.Material.Rock,
		color = ROCK_COLOR,
		parent = parent,
	})
end

local function buildPuddle(base: Vector3, parent: Instance, index: number, random: Random)
	MapHelpers.makePart({
		name = ("Puddle%d"):format(index),
		size = Vector3.new(random:NextNumber(4, 7), 0.2, random:NextNumber(4, 7)),
		position = base + Vector3.new(0, 0.1, 0),
		material = Enum.Material.Water,
		color = PUDDLE_COLOR,
		canCollide = false,
		parent = parent,
	})
end

function Map06.build(mapData: MapData, parent: Instance)
	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Rock)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local center = mapData.offset
	local random = Random.new(606)

	MapHelpers.makePart({
		name = "Ceiling",
		size = Vector3.new(mapData.size.X, 5, mapData.size.Z),
		position = center + Vector3.new(0, 18, 0),
		material = Enum.Material.Rock,
		color = CEILING_COLOR,
		parent = mapModel,
	})

	local stalactiteCount = MapHelpers.scaledCount(20)
	for i = 1, stalactiteCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(15, 150)
		local pos = center + Vector3.new(math.cos(angle) * r, 15.5, math.sin(angle) * r)
		buildStalactite(pos, mapModel, random, i)
	end

	local stalagmiteCount = MapHelpers.scaledCount(15)
	for i = 1, stalagmiteCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(15, 150)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildStalagmite(pos, mapModel, random, i)
	end

	for i = 1, 5 do
		local angle = math.rad((i - 1) * 72)
		local r = 160
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		MapHelpers.buildSimpleTorch(pos, mapModel, Color3.fromRGB(255, 170, 80))
	end

	local puddleCount = MapHelpers.scaledCount(3)
	for i = 1, puddleCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(30, 120)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildPuddle(pos, mapModel, i, random)
	end

	MapHelpers.buildSpawnMarker(mapData, mapModel)
	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — ceiling ON, %d stalactite, %d stalagmite, 5 torch, %d puddle."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			stalactiteCount,
			stalagmiteCount,
			puddleCount
		)
	)
end

return Map06
