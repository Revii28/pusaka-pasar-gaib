--!strict
--[[
	@module      Map09_KawahBromo
	@description Epic map — gunung berapi aktif. Terrain Sand black + CrackedLava
	             di Y=150, 1 kawah lava center (Cylinder Neon orange + fire
	             particles), 10 batu vulkanik hitam, 5 obor kuno, ash particles
	             falling.
	@author      Claude Agent (primary coder)
]]

local MapHelpers = require(script.Parent:WaitForChild("MapHelpers"))

type MapData = MapHelpers.MapData

local Map09 = {}

local VOLCANIC_ROCK = Color3.fromRGB(35, 25, 22)
local LAVA_COLOR = Color3.fromRGB(255, 90, 0)
local ASH_COLOR = Color3.fromRGB(80, 70, 65)

local function buildLavaCrater(center: Vector3, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "KawahLava"

	local crater = Instance.new("Part")
	crater.Name = "LavaPool"
	crater.Shape = Enum.PartType.Cylinder
	crater.Size = Vector3.new(5, 60, 60)
	crater.CFrame = CFrame.new(center + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	crater.Anchored = true
	crater.CanCollide = false
	crater.Material = Enum.Material.Neon
	crater.Color = LAVA_COLOR
	crater.Parent = model

	local light = Instance.new("PointLight")
	light.Color = LAVA_COLOR
	light.Brightness = 10
	light.Range = 80
	light.Parent = crater

	if MapHelpers.particlesEnabled() then
		local fire = Instance.new("ParticleEmitter")
		fire.Name = "LavaFire"
		fire.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 90)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 110, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 30, 20)),
		})
		fire.Lifetime = NumberRange.new(1.5, 3)
		fire.Rate = 80
		fire.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(1, 0.5),
		})
		fire.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		fire.Speed = NumberRange.new(4, 8)
		fire.SpreadAngle = Vector2.new(30, 30)
		fire.LightEmission = 1
		fire.EmissionDirection = Enum.NormalId.Top
		fire.Parent = crater
	end

	model.Parent = parent
end

local function buildVolcanicRock(base: Vector3, parent: Instance, index: number, random: Random)
	MapHelpers.makePart({
		name = ("VolcanicRock%d"):format(index),
		size = Vector3.new(
			random:NextNumber(4, 8),
			random:NextNumber(3, 6),
			random:NextNumber(4, 8)
		),
		position = base + Vector3.new(0, 2.5, 0),
		material = Enum.Material.Rock,
		color = VOLCANIC_ROCK,
		parent = parent,
	})
end

local function attachAshFall(parent: Instance, center: Vector3, area: Vector3)
	if not MapHelpers.particlesEnabled() then
		return
	end
	local anchor = MapHelpers.makePart({
		name = "AshAnchor",
		size = Vector3.new(area.X, 0.1, area.Z),
		position = center + Vector3.new(0, 70, 0),
		material = Enum.Material.SmoothPlastic,
		color = Color3.new(1, 1, 1),
		transparency = 1,
		canCollide = false,
		parent = parent,
	})
	local ash = Instance.new("ParticleEmitter")
	ash.Name = "Ash"
	ash.Color = ColorSequence.new(ASH_COLOR)
	ash.Lifetime = NumberRange.new(5, 9)
	ash.Rate = 40
	ash.Size = NumberSequence.new(0.3)
	ash.Transparency = NumberSequence.new(0.5)
	ash.Speed = NumberRange.new(1.5)
	ash.Acceleration = Vector3.new(0, -1, 0)
	ash.EmissionDirection = Enum.NormalId.Bottom
	ash.SpreadAngle = Vector2.new(25, 25)
	ash.Parent = anchor
end

function Map09.build(mapData: MapData, parent: Instance)
	MapHelpers.fillTerrain(mapData.offset, mapData.size, Enum.Material.Sand)

	local mapModel = Instance.new("Model")
	mapModel.Name = mapData.id
	mapModel.Parent = parent

	local center = mapData.offset
	local random = Random.new(909)

	buildLavaCrater(center, mapModel)

	local rockCount = MapHelpers.scaledCount(10)
	for i = 1, rockCount do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(50, 180)
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		buildVolcanicRock(pos, mapModel, i, random)
	end

	for i = 1, 5 do
		local angle = math.rad((i - 1) * 72)
		local r = 150
		local pos = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		MapHelpers.buildSimpleTorch(pos, mapModel, Color3.fromRGB(255, 130, 50))
	end

	attachAshFall(mapModel, center, mapData.size)

	MapHelpers.buildSpawnMarker(mapData, mapModel)
	local PortalService = MapHelpers.getPortalService()
	MapHelpers.buildReturnPortal(mapData, mapModel, function(player)
		PortalService.teleportToHub(player)
	end)

	print(
		("[Map_%s] Built at offset (%d, %d, %d) — lava crater ON, %d volcanic rock, 5 torch, ash particles ON."):format(
			mapData.id,
			mapData.offset.X,
			mapData.offset.Y,
			mapData.offset.Z,
			rockCount
		)
	)
end

return Map09
