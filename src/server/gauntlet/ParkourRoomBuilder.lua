--!strict
--[[
	@module      ParkourRoomBuilder
	@description Build parkour geometry per theme (6 theme: rooftop, underwater,
	             lava, bamboo, candi_underground, island) + flat combat platform
	             post-parkour + bigger boss arena. DIFFICULTY scaling: room 1
	             easy (6-stud platform, 4-stud gap, 3 platforms), room 2 medium
	             (4-stud, 8-gap, 5), room 3 hard (3-stud, 12-gap, 7).
	@author      Claude Agent (primary coder)
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local ParkourRoomBuilder = {}

type DifficultyConfig = {
	platformSize: number,
	gapDistance: number,
	numPlatforms: number,
	heightVariation: number,
}

local DIFFICULTY: { [number]: DifficultyConfig } = {
	[1] = { platformSize = 6, gapDistance = 4, numPlatforms = 3, heightVariation = 2 },
	[2] = { platformSize = 4, gapDistance = 8, numPlatforms = 5, heightVariation = 4 },
	[3] = { platformSize = 3, gapDistance = 12, numPlatforms = 7, heightVariation = 6 },
}

local function getMapsFolder(): Instance
	return workspace:FindFirstChild("Maps") or workspace
end

local function buildRooftopParkour(origin: Vector3, roomNum: number)
	local d = DIFFICULTY[roomNum]
	if not d then
		return
	end
	local random = Random.new(origin.X * 13 + origin.Z + roomNum)
	for i = 1, d.numPlatforms do
		local roof = Instance.new("Part")
		roof.Name = ("RooftopPlatform%d_%d"):format(roomNum, i)
		roof.Size = Vector3.new(d.platformSize, 0.5, d.platformSize)
		roof.Position = origin
			+ Vector3.new(
				if i % 2 == 0 then 3 else -3,
				i * 2 + random:NextNumber(-d.heightVariation, d.heightVariation),
				(i - 1) * (d.platformSize + d.gapDistance)
			)
		roof.Anchored = true
		roof.Material = Enum.Material.WoodPlanks
		roof.Color = Color3.fromRGB(100, 60, 30)
		roof.Parent = getMapsFolder()

		local lantern = Instance.new("Part")
		lantern.Name = "Lantern"
		lantern.Shape = Enum.PartType.Ball
		lantern.Size = Vector3.new(1, 1, 1)
		lantern.Position = roof.Position + Vector3.new(0, 1.5, 0)
		lantern.Anchored = true
		lantern.CanCollide = false
		lantern.Material = Enum.Material.Neon
		lantern.Color = Color3.fromRGB(220, 60, 60)
		lantern.Parent = roof
	end
end

local function buildUnderwaterParkour(origin: Vector3, roomNum: number)
	local d = DIFFICULTY[roomNum]
	if not d then
		return
	end
	local random = Random.new(origin.X * 17 + origin.Z + roomNum)
	for i = 1, d.numPlatforms do
		local coral = Instance.new("Part")
		coral.Name = ("CoralPlatform%d_%d"):format(roomNum, i)
		coral.Shape = Enum.PartType.Cylinder
		coral.Size = Vector3.new(0.5, d.platformSize, d.platformSize)
		coral.CFrame = CFrame.new(
			origin
				+ Vector3.new(
					random:NextNumber(-3, 3),
					i * 2,
					(i - 1) * (d.platformSize + d.gapDistance)
				)
		) * CFrame.Angles(0, 0, math.rad(90))
		coral.Anchored = true
		coral.Material = Enum.Material.Neon
		coral.Color = Color3.fromRGB(255, 100, 200)
		coral.Parent = getMapsFolder()
	end
end

local function buildLavaParkour(origin: Vector3, roomNum: number)
	local d = DIFFICULTY[roomNum]
	if not d then
		return
	end
	for i = 1, d.numPlatforms do
		local stone = Instance.new("Part")
		stone.Name = ("LavaStone%d_%d"):format(roomNum, i)
		stone.Size = Vector3.new(d.platformSize, 1, d.platformSize)
		stone.Position = origin
			+ Vector3.new(
				if i % 2 == 0 then 4 else -4,
				0,
				(i - 1) * (d.platformSize + d.gapDistance)
			)
		stone.Anchored = true
		stone.Material = Enum.Material.Basalt
		stone.Color = Color3.fromRGB(40, 30, 30)
		stone.Parent = getMapsFolder()
		stone:SetAttribute("SafePlatform", true)
	end

	local lavaLength = d.numPlatforms * (d.platformSize + d.gapDistance) + 20
	local lava = Instance.new("Part")
	lava.Name = ("LavaDamageZone%d"):format(roomNum)
	lava.Size = Vector3.new(lavaLength, 1, 30)
	lava.Position = origin + Vector3.new(0, -5, lavaLength / 2)
	lava.Anchored = true
	lava.CanCollide = false
	lava.Material = Enum.Material.Neon
	lava.Color = Color3.fromRGB(255, 80, 0)
	lava.Parent = getMapsFolder()

	-- Throttle damage via per-player last-hit cooldown attribute (anti-spam).
	local lastHit: { [number]: number } = {}
	lava.Touched:Connect(function(hit: BasePart)
		local char = hit.Parent
		if not char then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local player = Players:GetPlayerFromCharacter(char :: Model)
		if not hum or not player then
			return
		end
		local now = os.clock()
		if now - (lastHit[player.UserId] or 0) < 0.5 then
			return
		end
		lastHit[player.UserId] = now
		hum:TakeDamage(30)
	end)
end

local function buildBambooParkour(origin: Vector3, roomNum: number)
	local d = DIFFICULTY[roomNum]
	if not d then
		return
	end
	local random = Random.new(origin.X * 19 + origin.Z + roomNum)
	for i = 1, d.numPlatforms do
		local pole = Instance.new("Part")
		pole.Name = ("BambooPole%d_%d"):format(roomNum, i)
		pole.Shape = Enum.PartType.Cylinder
		pole.Size = Vector3.new(d.platformSize, 0.8, 0.8)
		pole.CFrame = CFrame.new(
			origin
				+ Vector3.new(
					random:NextNumber(-3, 3),
					i * 1.5,
					(i - 1) * (d.platformSize + d.gapDistance)
				)
		)
		pole.Anchored = true
		pole.Material = Enum.Material.Wood
		pole.Color = Color3.fromRGB(140, 180, 80)
		pole.Parent = getMapsFolder()
	end
end

local function buildCandiParkour(origin: Vector3, roomNum: number)
	local d = DIFFICULTY[roomNum]
	if not d then
		return
	end
	for i = 1, d.numPlatforms do
		local stone = Instance.new("Part")
		stone.Name = ("CandiStone%d_%d"):format(roomNum, i)
		stone.Size = Vector3.new(d.platformSize, 1, d.platformSize)
		stone.Position = origin
			+ Vector3.new(
				if i % 2 == 0 then 3 else -3,
				i * 2,
				(i - 1) * (d.platformSize + d.gapDistance)
			)
		stone.Anchored = true
		stone.Material = Enum.Material.Sandstone
		stone.Color = Color3.fromRGB(180, 150, 100)
		stone.Parent = getMapsFolder()

		local torch = Instance.new("PointLight")
		torch.Color = Color3.fromRGB(255, 180, 80)
		torch.Range = 15
		torch.Brightness = 3
		torch.Parent = stone
	end
end

local function buildIslandParkour(origin: Vector3, roomNum: number)
	local d = DIFFICULTY[roomNum]
	if not d then
		return
	end
	local random = Random.new(origin.X * 23 + origin.Z + roomNum)
	for i = 1, d.numPlatforms do
		local rock = Instance.new("Part")
		rock.Name = ("IslandRock%d_%d"):format(roomNum, i)
		rock.Size = Vector3.new(d.platformSize, 2, d.platformSize)
		rock.Position = origin
			+ Vector3.new(
				random:NextNumber(-4, 4),
				i * 1.5,
				(i - 1) * (d.platformSize + d.gapDistance)
			)
		rock.Anchored = true
		rock.Material = Enum.Material.Rock
		rock.Color = Color3.fromRGB(90, 80, 70)
		rock.Parent = getMapsFolder()
	end
end

local THEME_BUILDERS: { [string]: (Vector3, number) -> () } = {
	rooftop = buildRooftopParkour,
	underwater = buildUnderwaterParkour,
	lava = buildLavaParkour,
	bamboo = buildBambooParkour,
	candi_underground = buildCandiParkour,
	island = buildIslandParkour,
}

local THEME_COMBAT_COLOR: { [string]: Color3 } = {
	rooftop = Color3.fromRGB(80, 60, 40),
	underwater = Color3.fromRGB(40, 80, 100),
	lava = Color3.fromRGB(60, 30, 30),
	bamboo = Color3.fromRGB(80, 110, 70),
	candi_underground = Color3.fromRGB(120, 100, 70),
	island = Color3.fromRGB(110, 95, 70),
}

function ParkourRoomBuilder.buildParkour(theme: string, origin: Vector3, roomNum: number)
	local builder = THEME_BUILDERS[theme]
	if builder then
		builder(origin, roomNum)
	end
	-- ParkourStart anchor marker per room — buat respawn anti-cheese
	local startMarker = Instance.new("Part")
	startMarker.Name = ("ParkourStart_%d"):format(roomNum)
	startMarker.Size = Vector3.new(4, 0.2, 4)
	startMarker.Position = origin
	startMarker.Anchored = true
	startMarker.CanCollide = false
	startMarker.Transparency = 1
	startMarker:SetAttribute("ParkourRoom", roomNum)
	startMarker.Parent = getMapsFolder()
	Debris:AddItem(startMarker, 0) -- noop, just keep it
end

function ParkourRoomBuilder.buildCombatPlatform(theme: string, origin: Vector3, roomNum: number)
	local color = THEME_COMBAT_COLOR[theme] or Color3.fromRGB(80, 80, 90)
	local platform = Instance.new("Part")
	platform.Name = ("CombatPlatform_%d"):format(roomNum)
	platform.Size = Vector3.new(20, 1, 20)
	platform.Position = origin
	platform.Anchored = true
	platform.Material = Enum.Material.Slate
	platform.Color = color
	platform.Parent = getMapsFolder()

	for i, corner in ipairs({
		Vector3.new(9, 0, 9),
		Vector3.new(-9, 0, 9),
		Vector3.new(9, 0, -9),
		Vector3.new(-9, 0, -9),
	}) do
		local pillar = Instance.new("Part")
		pillar.Name = ("CombatPillar_%d_%d"):format(roomNum, i)
		pillar.Shape = Enum.PartType.Cylinder
		pillar.Size = Vector3.new(6, 0.5, 0.5)
		pillar.CFrame = CFrame.new(origin + corner + Vector3.new(0, 3, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		pillar.Anchored = true
		pillar.Material = Enum.Material.Neon
		pillar.Color = color
		pillar.Parent = getMapsFolder()
	end
end

function ParkourRoomBuilder.buildBossArena(theme: string, origin: Vector3)
	local color = THEME_COMBAT_COLOR[theme] or Color3.fromRGB(60, 50, 70)
	local arena = Instance.new("Part")
	arena.Name = "BossArena"
	arena.Size = Vector3.new(40, 1, 40)
	arena.Position = origin
	arena.Anchored = true
	arena.Material = Enum.Material.Marble
	arena.Color = color
	arena.Parent = getMapsFolder()
end

return ParkourRoomBuilder
