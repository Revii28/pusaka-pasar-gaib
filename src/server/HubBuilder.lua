--!strict
--[[
	@module      HubBuilder
	@description Build placeholder Pasar Gaib hub: lantai kayu 100x100 + 4 pillar
	             penanda Inner Ring + SpawnLocation di tengah. Wipe default world
	             dulu (Terrain:Clear() + destroy default BaseParts) supaya gak ada
	             rumput liar / baseplate nyembul. Phase 3 Minggu 1 scaffold —
	             diganti terrain artist + custom prop saat Phase 6+.
	@author      Claude Agent (primary coder)
]]

local HubBuilder = {}

local DEFAULT_PART_NAMES: { [string]: boolean } = {
	Baseplate = true,
	SpawnLocation = true,
	Part = true,
}

local FLOOR_SIZE = Vector3.new(100, 1, 100)
local FLOOR_COLOR = Color3.fromRGB(80, 45, 20)

local PILLAR_SIZE = Vector3.new(4, 10, 4)
local PILLAR_COLOR = Color3.fromRGB(60, 35, 18)
local PILLAR_CORNERS: { Vector3 } = {
	Vector3.new(48, 5, 48),
	Vector3.new(-48, 5, 48),
	Vector3.new(48, 5, -48),
	Vector3.new(-48, 5, -48),
}

local SPAWN_SIZE = Vector3.new(8, 1, 8)
local SPAWN_POSITION = Vector3.new(0, 0.5, 0)
local SPAWN_COLOR = Color3.fromRGB(212, 175, 55)

local function clearDefaultWorld()
	workspace.Terrain:Clear()
	for _, child in workspace:GetChildren() do
		if child:IsA("BasePart") and DEFAULT_PART_NAMES[child.Name] then
			child:Destroy()
		end
	end
end

local function createFloor(parent: Instance): Part
	local floor = Instance.new("Part")
	floor.Name = "WoodFloor"
	floor.Size = FLOOR_SIZE
	floor.Position = Vector3.new(0, -0.5, 0)
	floor.Anchored = true
	floor.Material = Enum.Material.WoodPlanks
	floor.Color = FLOOR_COLOR
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = parent
	return floor
end

local function createPillar(name: string, position: Vector3, parent: Instance): Part
	local pillar = Instance.new("Part")
	pillar.Name = name
	pillar.Size = PILLAR_SIZE
	pillar.Position = position
	pillar.Anchored = true
	pillar.Material = Enum.Material.WoodPlanks
	pillar.Color = PILLAR_COLOR
	pillar.TopSurface = Enum.SurfaceType.Smooth
	pillar.BottomSurface = Enum.SurfaceType.Smooth
	pillar.Parent = parent
	return pillar
end

local function createSpawn(parent: Instance): SpawnLocation
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Size = SPAWN_SIZE
	spawn.Position = SPAWN_POSITION
	spawn.Anchored = true
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Color = SPAWN_COLOR
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Neutral = true
	spawn.Parent = parent
	return spawn
end

function HubBuilder.build(): Model
	clearDefaultWorld()

	local hub = Instance.new("Model")
	hub.Name = "PasarGaibHub"
	hub.Parent = workspace

	createFloor(hub)
	for i, corner in ipairs(PILLAR_CORNERS) do
		createPillar(("Pillar%d"):format(i), corner, hub)
	end
	createSpawn(hub)

	return hub
end

return HubBuilder
