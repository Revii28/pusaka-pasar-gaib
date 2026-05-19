--!strict
--[[
	@module      Map04_GunungLawu
	@description Rare map — puncak gunung dingin. Terrain Rock + Snow patches
	             di Y=200, 15 batu besar abu, 5 edelweiss kecil, snow particles
	             rate 50 white, 1 shrine stone tengah dengan obor.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map04 = {}

local ROCK_COLOR = Color3.fromRGB(140, 140, 140)
local SHRINE_COLOR = Color3.fromRGB(100, 95, 90)
local EDELWEISS_COLOR = Color3.fromRGB(240, 240, 230)
local EDELWEISS_LEAF_COLOR = Color3.fromRGB(140, 160, 130)

local function buildBoulder(base: Vector3, parent: Instance, index: number, random: Random)
	MapHelpers.makePart({
		name = ("Boulder%d"):format(index),
		size = Vector3.new(
			random:NextNumber(5, 9),
			random:NextNumber(4, 7),
			random:NextNumber(5, 9)
		),
		position = base + Vector3.new(0, 3, 0),
		material = Enum.Material.Rock,
		color = ROCK_COLOR,
		parent = parent,
	})
end

local function buildEdelweiss(base: Vector3, parent: Instance, index: number)
	local model = Instance.new("Model")
	model.Name = ("Edelweiss%d"):format(index)
	MapHelpers.makePart({
		name = "Stem",
		size = Vector3.new(0.3, 1.5, 0.3),
		position = base + Vector3.new(0, 0.75, 0),
		material = Enum.Material.Grass,
		color = EDELWEISS_LEAF_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Flower",
		size = Vector3.new(1, 0.5, 1),
		position = base + Vector3.new(0, 1.7, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.SmoothPlastic,
		color = EDELWEISS_COLOR,
		parent = model,
	})
	model.Parent = parent
end

local function buildShrine(center: Vector3, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Shrine"
	MapHelpers.makePart({
		name = "Base",
		size = Vector3.new(8, 1, 8),
		position = center + Vector3.new(0, 0.5, 0),
		material = Enum.Material.Slate,
		color = SHRINE_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Pillar",
		size = Vector3.new(6, 6, 6),
		position = center + Vector3.new(0, 4, 0),
		material = Enum.Material.Slate,
		color = SHRINE_COLOR,
		parent = model,
	})
	MapHelpers.buildSimpleTorch(
		center + Vector3.new(3.5, 1, 3.5),
		model,
		Color3.fromRGB(255, 140, 60)
	)
	MapHelpers.buildSimpleTorch(
		center + Vector3.new(-3.5, 1, 3.5),
		model,
		Color3.fromRGB(255, 140, 60)
	)
	model.Parent = parent
end

local function attachSnowParticles(parent: Instance, center: Vector3, area: Vector3)
	if not MapHelpers.particlesEnabled() then
		return
	end
	local anchor = MapHelpers.makePart({
		name = "SnowAnchor",
		size = Vector3.new(area.X, 0.1, area.Z),
		position = center + Vector3.new(0, 60, 0),
		material = Enum.Material.SmoothPlastic,
		color = Color3.new(1, 1, 1),
		transparency = 1,
		canCollide = false,
		parent = parent,
	})
	local snow = Instance.new("ParticleEmitter")
	snow.Name = "Snow"
	snow.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	snow.Lifetime = NumberRange.new(4, 7)
	snow.Rate = 50
	snow.Size = NumberSequence.new(0.2)
	snow.Transparency = NumberSequence.new(0.3)
	snow.Speed = NumberRange.new(2)
	snow.Acceleration = Vector3.new(0, -3, 0)
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.SpreadAngle = Vector2.new(20, 20)
	snow.Parent = anchor
end

function Map04.build(mapData: MapData, parent: Instance)
	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Rock)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local random = Random.new(404)
	local center = mapData.offset

	local boulderCount = MapHelpers.scaledCount(15)
	for i = 1, boulderCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(20, 150)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildBoulder(pos, mapModel, i, random)
	end

	local edelCount = MapHelpers.scaledCount(5)
	for i = 1, edelCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(15, 100)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildEdelweiss(pos, mapModel, i)
	end

	buildShrine(center, mapModel)
	attachSnowParticles(mapModel, center, mapData.size)

	MapHelpers.buildSpawnMarker(mapData, mapModel)
	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — %d boulders, %d edelweiss, snow ON."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			boulderCount,
			edelCount
		)
	)
end

return Map04
