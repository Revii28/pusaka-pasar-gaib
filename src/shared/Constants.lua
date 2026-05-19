--!strict
--[[
	@module      Constants
	@description Game-wide constants. Single source of truth untuk nilai yang dipakai
	             lintas client/server (game name, version, debug flags, MAPS table
	             untuk 12 map skeleton + portal hub). Tweak balance di sini, BUKAN
	             di-hardcode di kode lain.
	@author      Claude Agent (primary coder)
]]

export type MapData = {
	id: string,
	displayName: string,
	tier: string,
	offset: Vector3,
	size: Vector3,
	biome: string,
	lightingPreset: string,
	spawnPos: Vector3,
	returnPortalPos: Vector3,
}

local Constants = {}

Constants.GAME_NAME = "PUSAKA: Pasar Gaib"
Constants.VERSION = "0.0.1-alpha"
Constants.DEBUG_MODE = true

-- Lighting preset toggle. Valid: "DEBUG_BRIGHT" | "MYSTIC_NIGHT".
-- DEBUG_BRIGHT = siang bolong, no post-processing, no mist — verify composition.
-- MYSTIC_NIGHT = malam jam 20 dengan Bloom/CC/DOF/Atmosphere + fog + particles.
-- Default DEBUG_BRIGHT sampai user verify semua prop keliatan, lalu ganti.
Constants.LIGHTING_PRESET = "DEBUG_BRIGHT"

-- Performance toggles. Default = full quality. Turunin manual kalau frame
-- rate jelek di low-end device. Lampion tween Random.new() default seed
-- (clock-based) by design — flicker desync antar lampion non-deterministic.
Constants.PERFORMANCE = {
	LAMPION_FLICKER_ENABLED = true,
	TREE_LEAF_COUNT_MAX = 6,
	GHOST_AURA_PARTICLE_RATE_MULTIPLIER = 1.0,
	MAP_DECORATION_DENSITY_MULTIPLIER = 1.0,
	ENABLE_PARTICLE_EMITTERS_MAPS = true,
}
table.freeze(Constants.PERFORMANCE)

-- 12 map definitions. Iterated by MapManager (build map skeleton) dan
-- PortalHub (spawn 12 portal arc 360° di sekitar spawn hub). Offsets jauh
-- (2000-4000 stud) supaya tiap map terisolasi di workspace single-place.
-- lightingPreset = metadata buat per-map Lighting transitions Phase 4+ —
-- saat ini global lighting DEBUG_BRIGHT sampai user verify composition.
Constants.MAPS = {
	{
		id = "DesaPangkalan",
		displayName = "Desa Pangkalan",
		tier = "Starter",
		offset = Vector3.new(2000, 0, 0),
		size = Vector3.new(300, 0, 300),
		biome = "Village",
		lightingPreset = "BrightDay",
		spawnPos = Vector3.new(2000, 5, 0),
		returnPortalPos = Vector3.new(2000, 5, -130),
	},
	{
		id = "KuburanMbahBuyut",
		displayName = "Kuburan Mbah Buyut",
		tier = "Common",
		offset = Vector3.new(-2000, 0, 0),
		size = Vector3.new(350, 0, 350),
		biome = "Graveyard",
		lightingPreset = "NightMisty",
		spawnPos = Vector3.new(-2000, 5, 0),
		returnPortalPos = Vector3.new(-2000, 5, -150),
	},
	{
		id = "HutanLarangan",
		displayName = "Hutan Larangan",
		tier = "Uncommon",
		offset = Vector3.new(0, 0, 2000),
		size = Vector3.new(400, 0, 400),
		biome = "DenseForest",
		lightingPreset = "DimForest",
		spawnPos = Vector3.new(0, 5, 2000),
		returnPortalPos = Vector3.new(0, 5, 1850),
	},
	{
		id = "GunungLawu",
		displayName = "Gunung Lawu Puncak",
		tier = "Rare",
		offset = Vector3.new(0, 200, -2000),
		size = Vector3.new(350, 0, 350),
		biome = "MountainPeak",
		lightingPreset = "ColdMountain",
		spawnPos = Vector3.new(0, 205, -2000),
		returnPortalPos = Vector3.new(0, 205, -2150),
	},
	{
		id = "PuraBali",
		displayName = "Pura Terbengkalai Bali",
		tier = "Rare",
		offset = Vector3.new(2000, 0, 2000),
		size = Vector3.new(300, 0, 300),
		biome = "Temple",
		lightingPreset = "GoldenHour",
		spawnPos = Vector3.new(2000, 5, 2000),
		returnPortalPos = Vector3.new(2000, 5, 1870),
	},
	{
		id = "GoaPetruk",
		displayName = "Goa Petruk",
		tier = "Rare",
		offset = Vector3.new(-2000, -100, 2000),
		size = Vector3.new(350, 0, 350),
		biome = "Cave",
		lightingPreset = "DarkCave",
		spawnPos = Vector3.new(-2000, -95, 2000),
		returnPortalPos = Vector3.new(-2000, -95, 1850),
	},
	{
		id = "PasarSetan",
		displayName = "Pasar Setan",
		tier = "Epic",
		offset = Vector3.new(2000, 0, -2000),
		size = Vector3.new(400, 0, 400),
		biome = "GhostMarket",
		lightingPreset = "BloodMoon",
		spawnPos = Vector3.new(2000, 5, -2000),
		returnPortalPos = Vector3.new(2000, 5, -2200),
	},
	{
		id = "LautSelatan",
		displayName = "Dasar Laut Selatan",
		tier = "Epic",
		offset = Vector3.new(-2000, -300, -2000),
		size = Vector3.new(500, 0, 500),
		biome = "DeepOcean",
		lightingPreset = "UnderwaterBlue",
		spawnPos = Vector3.new(-2000, -295, -2000),
		returnPortalPos = Vector3.new(-2000, -295, -2250),
	},
	{
		id = "KawahBromo",
		displayName = "Kawah Bromo",
		tier = "Epic",
		offset = Vector3.new(4000, 150, 0),
		size = Vector3.new(400, 0, 400),
		biome = "Volcano",
		lightingPreset = "FieryRed",
		spawnPos = Vector3.new(4000, 155, 0),
		returnPortalPos = Vector3.new(4000, 155, -200),
	},
	{
		id = "HutanBambu",
		displayName = "Hutan Bambu Pamijahan",
		tier = "Epic",
		offset = Vector3.new(-4000, 0, 0),
		size = Vector3.new(450, 0, 450),
		biome = "BambooForest",
		lightingPreset = "MysticalGreen",
		spawnPos = Vector3.new(-4000, 5, 0),
		returnPortalPos = Vector3.new(-4000, 5, -225),
	},
	{
		id = "BorobudurBawahTanah",
		displayName = "Candi Borobudur Bawah Tanah",
		tier = "Legendary",
		offset = Vector3.new(0, -400, 4000),
		size = Vector3.new(500, 0, 500),
		biome = "UndergroundTemple",
		lightingPreset = "TorchLit",
		spawnPos = Vector3.new(0, -395, 4000),
		returnPortalPos = Vector3.new(0, -395, 3750),
	},
	{
		id = "PulauKomodo",
		displayName = "Pulau Komodo Mistis",
		tier = "Legendary",
		offset = Vector3.new(0, 0, -4000),
		size = Vector3.new(500, 0, 500),
		biome = "TropicalIsland",
		lightingPreset = "StormySky",
		spawnPos = Vector3.new(0, 5, -4000),
		returnPortalPos = Vector3.new(0, 5, -4250),
	},
} :: { MapData }
table.freeze(Constants.MAPS)

table.freeze(Constants)
return Constants
