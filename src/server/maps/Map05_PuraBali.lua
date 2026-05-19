--!strict
--[[
	@module      Map05_PuraBali
	@description Rare map — pura Bali terbengkalai. Terrain Grass + Mud, 1 candi
	             besar tengah dengan atap meru bertingkat 5, 4 patung guardian
	             di pinggir, 8 obor menyala, bunga frangipani putih scattered.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map05 = {}

local STONE_COLOR = Color3.fromRGB(95, 95, 100)
local MERU_COLOR = Color3.fromRGB(40, 35, 30)
local STATUE_COLOR = Color3.fromRGB(80, 80, 80)
local FRANGIPANI_COLOR = Color3.fromRGB(250, 245, 230)
local FRANGIPANI_CENTER = Color3.fromRGB(255, 220, 110)

local function buildCandi(center: Vector3, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Candi"
	MapHelpers.makePart({
		name = "Base",
		size = Vector3.new(20, 8, 20),
		position = center + Vector3.new(0, 4, 0),
		material = Enum.Material.Slate,
		color = STONE_COLOR,
		parent = model,
	})

	for tier = 1, 5 do
		local scale = 1 - (tier - 1) * 0.15
		local size = Vector3.new(18 * scale, 1.5, 18 * scale)
		MapHelpers.makePart({
			name = ("Meru%d"):format(tier),
			size = size,
			position = center + Vector3.new(0, 8 + (tier - 1) * 2, 0),
			material = Enum.Material.Fabric,
			color = MERU_COLOR,
			parent = model,
		})
	end
	model.Parent = parent
end

local function buildGuardian(position: Vector3, parent: Instance, index: number)
	local model = Instance.new("Model")
	model.Name = ("Guardian%d"):format(index)
	MapHelpers.makePart({
		name = "Base",
		size = Vector3.new(3, 1, 3),
		position = position + Vector3.new(0, 0.5, 0),
		material = Enum.Material.Slate,
		color = STATUE_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Torso",
		size = Vector3.new(2, 4, 2),
		position = position + Vector3.new(0, 3, 0),
		material = Enum.Material.Slate,
		color = STATUE_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Head",
		size = Vector3.new(1.5, 1.5, 1.5),
		position = position + Vector3.new(0, 5.75, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Slate,
		color = STATUE_COLOR,
		parent = model,
	})
	model.Parent = parent
end

local function buildFrangipani(base: Vector3, parent: Instance, index: number, random: Random)
	local model = Instance.new("Model")
	model.Name = ("Frangipani%d"):format(index)
	for i = 1, 5 do
		local angle = math.rad((i - 1) * 72)
		MapHelpers.makePart({
			name = ("Petal%d"):format(i),
			size = Vector3.new(0.6, 0.15, 0.4),
			position = base + Vector3.new(math.cos(angle) * 0.35, 0.2, math.sin(angle) * 0.35),
			material = Enum.Material.SmoothPlastic,
			color = FRANGIPANI_COLOR,
			canCollide = false,
			parent = model,
		})
	end
	MapHelpers.makePart({
		name = "Center",
		size = Vector3.new(0.25, 0.25, 0.25),
		position = base + Vector3.new(0, 0.3, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Neon,
		color = FRANGIPANI_CENTER,
		canCollide = false,
		parent = model,
	})
	model.Parent = parent
	-- Random param suppressed by usage in caller scatter logic
	local _ = random
end

function Map05.build(mapData: MapData, parent: Instance)
	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Grass)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local random = Random.new(505)
	local center = mapData.offset

	buildCandi(center, mapModel)

	local guardianOffsets = {
		Vector3.new(15, 0, 15),
		Vector3.new(-15, 0, 15),
		Vector3.new(15, 0, -15),
		Vector3.new(-15, 0, -15),
	}
	for i, off in ipairs(guardianOffsets) do
		buildGuardian(center + off, mapModel, i)
	end

	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45)
		local r = 30
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		MapHelpers.buildSimpleTorch(pos, mapModel, Color3.fromRGB(255, 160, 70))
	end

	local frangipaniCount = MapHelpers.scaledCount(40)
	for i = 1, frangipaniCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(25, 130)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildFrangipani(pos, mapModel, i, random)
	end

	MapHelpers.buildSpawnMarker(mapData, mapModel)
	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — 1 candi 5-tier, 4 guardian, 8 torch, %d frangipani."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			frangipaniCount
		)
	)
end

return Map05
