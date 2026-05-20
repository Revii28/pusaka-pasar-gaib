--!strict
--[[
	@module      Map08_LautSelatan
	@description Epic map — dasar laut selatan. Terrain Sand + Salt patches floor
	             Y=-300, ceiling water plane transparent blue Y=-200, 30 karang
	             warna-warni (sphere/cone), 15 rumput laut tall cylinder tilted,
	             5 kerang besar, 1 istana Nyi Roro Kidul placeholder gold ornate.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map08 = {}

local WATER_PLANE_COLOR = Color3.fromRGB(40, 90, 150)
local SEAWEED_COLOR = Color3.fromRGB(50, 110, 80)
local SHELL_COLOR = Color3.fromRGB(220, 180, 160)
local PALACE_COLOR = Color3.fromRGB(220, 180, 70)

local CORAL_COLORS = {
	Color3.fromRGB(255, 120, 140),
	Color3.fromRGB(180, 100, 220),
	Color3.fromRGB(250, 170, 90),
	Color3.fromRGB(120, 200, 230),
	Color3.fromRGB(255, 230, 130),
}

local function buildCoral(base: Vector3, parent: Instance, index: number, random: Random)
	local color = CORAL_COLORS[random:NextInteger(1, #CORAL_COLORS)]
	MapHelpers.makePart({
		name = ("Coral%d"):format(index),
		size = Vector3.new(
			random:NextNumber(1.5, 3.5),
			random:NextNumber(2, 5),
			random:NextNumber(1.5, 3.5)
		),
		position = base + Vector3.new(0, 1.5, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Sand,
		color = color,
		parent = parent,
	})
end

local function buildSeaweed(base: Vector3, parent: Instance, index: number, random: Random)
	local height = random:NextNumber(4, 7)
	local tilt = math.rad(random:NextNumber(-15, 15))
	local seaweed = Instance.new("Part")
	seaweed.Name = ("Seaweed%d"):format(index)
	seaweed.Shape = Enum.PartType.Cylinder
	seaweed.Size = Vector3.new(height, 0.5, 0.5)
	seaweed.CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0))
		* CFrame.Angles(0, 0, math.rad(90) + tilt)
	seaweed.Anchored = true
	seaweed.CanCollide = false
	seaweed.Material = Enum.Material.Grass
	seaweed.Color = SEAWEED_COLOR
	seaweed.Parent = parent
end

local function buildShell(base: Vector3, parent: Instance, index: number)
	MapHelpers.makePart({
		name = ("Shell%d"):format(index),
		size = Vector3.new(4, 1.5, 4),
		position = base + Vector3.new(0, 0.75, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.SmoothPlastic,
		color = SHELL_COLOR,
		parent = parent,
	})
end

local function buildPalace(center: Vector3, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "IstanaNyiRoro"
	MapHelpers.makePart({
		name = "Base",
		size = Vector3.new(25, 5, 25),
		position = center + Vector3.new(0, 2.5, 0),
		material = Enum.Material.Marble,
		color = PALACE_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Tower",
		size = Vector3.new(15, 15, 15),
		position = center + Vector3.new(0, 12.5, 0),
		material = Enum.Material.Marble,
		color = PALACE_COLOR,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Dome",
		size = Vector3.new(10, 10, 10),
		position = center + Vector3.new(0, 23, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Marble,
		color = PALACE_COLOR,
		parent = model,
	})
	for i, sideX in ipairs({ -10, 10 }) do
		for j, sideZ in ipairs({ -10, 10 }) do
			MapHelpers.makePart({
				name = ("Spire%d_%d"):format(i, j),
				size = Vector3.new(2, 8, 2),
				position = center + Vector3.new(sideX, 9, sideZ),
				material = Enum.Material.Marble,
				color = PALACE_COLOR,
				parent = model,
			})
		end
	end
	model.Parent = parent
end

function Map08.build(mapData: MapData, parent: Instance)
	-- Spawn platform di sea floor — solid landing sebelum coral scatter.
	MapHelpers.buildSpawnPlatform(mapData.spawnPos, mapData.id, parent)
	-- Gauntlet 3 room + boss arena, theme underwater.
	MapHelpers.getGauntletService().buildGauntlet(mapData.id, mapData.offset)

	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Sand)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local center = mapData.offset
	local random = Random.new(808)

	MapHelpers.makePart({
		name = "WaterCeiling",
		size = Vector3.new(mapData.size.X, 1, mapData.size.Z),
		position = center + Vector3.new(0, 100, 0),
		material = Enum.Material.Water,
		color = WATER_PLANE_COLOR,
		transparency = 0.5,
		canCollide = false,
		parent = mapModel,
	})

	buildPalace(center, mapModel)

	local coralCount = MapHelpers.scaledCount(30)
	for i = 1, coralCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(40, 220)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildCoral(pos, mapModel, i, random)
	end

	local seaweedCount = MapHelpers.scaledCount(15)
	for i = 1, seaweedCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(30, 200)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildSeaweed(pos, mapModel, i, random)
	end

	local shellCount = MapHelpers.scaledCount(5)
	for i = 1, shellCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(50, 200)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildShell(pos, mapModel, i)
	end

	MapHelpers.buildSpawnMarker(mapData, mapModel)
	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — palace, %d coral, %d seaweed, %d shell."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			coralCount,
			seaweedCount,
			shellCount
		)
	)
end

return Map08
