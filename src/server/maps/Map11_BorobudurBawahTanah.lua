--!strict
--[[
	@module      Map11_BorobudurBawahTanah
	@description Legendary map — candi Borobudur underground. Terrain Rock di
	             Y=-400, ceiling Y=-370, 1 candi bertingkat 9 (stupa pattern
	             stacked stone), 8 patung Buddha emas (humanoid seated), 16 obor
	             wall mounted orange, 4 jalur lorong stone corridors.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map11 = {}

local STONE_GRAY = Color3.fromRGB(110, 105, 100)
local STUPA_DARK = Color3.fromRGB(80, 75, 70)
local BUDDHA_GOLD = Color3.fromRGB(200, 165, 70)
local CEILING_COLOR = Color3.fromRGB(45, 42, 40)

local function buildStupaTier(center: Vector3, parent: Instance, tier: number, baseSize: number)
	local tierScale = 1 - (tier - 1) * 0.09
	local size = baseSize * tierScale
	MapHelpers.makePart({
		name = ("Stupa%d"):format(tier),
		size = Vector3.new(size, 5, size),
		position = center + Vector3.new(0, (tier - 1) * 5 + 2.5, 0),
		material = Enum.Material.Slate,
		color = if tier % 2 == 0 then STUPA_DARK else STONE_GRAY,
		parent = parent,
	})
end

local function buildBorobudur(center: Vector3, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "BorobudurStupa"
	for tier = 1, 9 do
		buildStupaTier(center, model, tier, 40)
	end
	MapHelpers.makePart({
		name = "Crown",
		size = Vector3.new(8, 8, 8),
		position = center + Vector3.new(0, 50, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Slate,
		color = STONE_GRAY,
		parent = model,
	})
	model.Parent = parent
end

local function buildBuddha(position: Vector3, parent: Instance, index: number)
	local model = Instance.new("Model")
	model.Name = ("Buddha%d"):format(index)
	MapHelpers.makePart({
		name = "Lotus",
		size = Vector3.new(3.5, 0.8, 3.5),
		position = position + Vector3.new(0, 0.4, 0),
		material = Enum.Material.Marble,
		color = BUDDHA_GOLD,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Body",
		size = Vector3.new(2.5, 2.5, 2.5),
		position = position + Vector3.new(0, 2, 0),
		material = Enum.Material.Marble,
		color = BUDDHA_GOLD,
		parent = model,
	})
	MapHelpers.makePart({
		name = "Head",
		size = Vector3.new(1.4, 1.4, 1.4),
		position = position + Vector3.new(0, 4, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Marble,
		color = BUDDHA_GOLD,
		parent = model,
	})
	model.Parent = parent
end

function Map11.build(mapData: MapData, parent: Instance)
	-- Bug 5 fix: spawn di corridor entry via buildSpawnPlatform (spawnPos
	-- sudah dipindah 120 stud south outside stupa solid di Constants).
	MapHelpers.buildSpawnPlatform(mapData.spawnPos, mapData.id, parent)

	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Rock)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local center = mapData.offset

	-- Bug 5 fix: ceiling raise dari Y+12 ke Y+25 untuk player clearance + boss
	-- arena vertical room. Center: offset.Y + 27.5 (ceiling base Y+25, 5 thick).
	MapHelpers.makePart({
		name = "Ceiling",
		size = Vector3.new(mapData.size.X, 5, mapData.size.Z),
		position = center + Vector3.new(0, 27.5, 0),
		material = Enum.Material.Rock,
		color = CEILING_COLOR,
		parent = mapModel,
	})

	buildBorobudur(center, mapModel)

	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45)
		local r = 80
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildBuddha(pos, mapModel, i)
	end

	for i = 1, 16 do
		local angle = math.rad((i - 1) * 22.5)
		local r = 220
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		MapHelpers.buildSimpleTorch(pos, mapModel, Color3.fromRGB(255, 150, 60))
	end

	-- Bug 5 fix: corridor wider (6→8) + taller (12→20) + recenter Y+10 supaya
	-- ceiling Y+25 ada 5 stud headroom buat WeweGombel 9-tall enemy.
	for i = 1, 4 do
		local angle = math.rad((i - 1) * 90)
		MapHelpers.makePart({
			name = ("Corridor%d"):format(i),
			size = Vector3.new(8, 20, 80),
			cframe = CFrame.new(
				center + Vector3.new(math.cos(angle) * 130, 10, math.sin(angle) * 130)
			) * CFrame.Angles(0, angle, 0),
			material = Enum.Material.Slate,
			color = STONE_GRAY,
			parent = mapModel,
		})
	end

	MapHelpers.buildSpawnMarker(mapData, mapModel)
	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — 9-tier stupa + crown, 8 Buddha, 16 torch, 4 corridor."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z
		)
	)
end

return Map11
