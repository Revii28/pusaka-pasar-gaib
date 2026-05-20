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

export type EnemyTierStats = {
	hp: number,
	damage: number,
	walkSpeed: number,
	chaseSpeed: number,
	detectRange: number,
	attackRange: number,
	attackCooldown: number,
}

export type EnemyDef = {
	tier: string,
	displayName: string,
	rigSize: number,
}

export type EnemySpawnEntry = {
	type: string,
	count: number,
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

-- Combat M1 melee settings. Player melee range + damage + cooldown anti-spam.
Constants.COMBAT = {
	playerMaxHealth = 100,
	m1Damage = 20,
	m1Range = 5,
	m1Cooldown = 0.5,
}
table.freeze(Constants.COMBAT)

-- Enemy stat balance per tier (Trash → Legendary). EnemyAI.attach() reads
-- Constants.ENEMY_TIERS[enemyDef.tier] untuk konfig HP/damage/speed/range.
Constants.ENEMY_TIERS = {
	Trash = {
		hp = 30,
		damage = 5,
		walkSpeed = 8,
		chaseSpeed = 12,
		detectRange = 20,
		attackRange = 4,
		attackCooldown = 1.0,
	},
	Common = {
		hp = 80,
		damage = 12,
		walkSpeed = 8,
		chaseSpeed = 14,
		detectRange = 25,
		attackRange = 4,
		attackCooldown = 1.5,
	},
	Uncommon = {
		hp = 130,
		damage = 18,
		walkSpeed = 9,
		chaseSpeed = 16,
		detectRange = 28,
		attackRange = 5,
		attackCooldown = 1.5,
	},
	Rare = {
		hp = 200,
		damage = 25,
		walkSpeed = 10,
		chaseSpeed = 18,
		detectRange = 32,
		attackRange = 5,
		attackCooldown = 1.3,
	},
	Epic = {
		hp = 350,
		damage = 35,
		walkSpeed = 10,
		chaseSpeed = 20,
		detectRange = 35,
		attackRange = 6,
		attackCooldown = 1.2,
	},
	Boss = {
		hp = 1500,
		damage = 60,
		walkSpeed = 8,
		chaseSpeed = 16,
		detectRange = 50,
		attackRange = 8,
		attackCooldown = 1.0,
	},
	Legendary = {
		hp = 3000,
		damage = 90,
		walkSpeed = 8,
		chaseSpeed = 14,
		detectRange = 60,
		attackRange = 10,
		attackCooldown = 0.8,
	},
} :: { [string]: EnemyTierStats }
table.freeze(Constants.ENEMY_TIERS)

-- 12 enemy type definitions. tier → lookup di ENEMY_TIERS.
-- rigSize = scale multiplier (1.0 = baseline ~5 stud tall, 0.5 = mini, 3.0 = giant).
Constants.ENEMIES = {
	Tuyul = { tier = "Trash", displayName = "Tuyul", rigSize = 0.5 },
	Pocong = { tier = "Common", displayName = "Pocong", rigSize = 1.0 },
	Genderuwo = { tier = "Uncommon", displayName = "Genderuwo", rigSize = 1.3 },
	Kuntilanak = { tier = "Rare", displayName = "Kuntilanak", rigSize = 1.0 },
	Leak = { tier = "Rare", displayName = "Leak", rigSize = 1.0 },
	SundelBolong = { tier = "Rare", displayName = "Sundel Bolong", rigSize = 1.0 },
	Banaspati = { tier = "Epic", displayName = "Banaspati", rigSize = 1.2 },
	WeweGombel = { tier = "Epic", displayName = "Wewe Gombel", rigSize = 1.5 },
	ButoIjo = { tier = "Epic", displayName = "Buto Ijo", rigSize = 2.0 },
	SetanPasar = { tier = "Boss", displayName = "Setan Pasar", rigSize = 1.5 },
	NagaKomodo = { tier = "Legendary", displayName = "Naga Komodo", rigSize = 3.0 },
	BuddhaWraith = { tier = "Legendary", displayName = "Buddha Wraith", rigSize = 2.5 },
} :: { [string]: EnemyDef }
table.freeze(Constants.ENEMIES)

-- Per-map enemy spawn assignment. EnemySpawner.assignEnemiesToAllMaps() iterate
-- ini → require src/server/ai/enemies/<type>.lua → spawn count instances.
-- Total ~55 ghost + 4 boss/mini-boss across 12 maps.
Constants.ENEMY_SPAWN_MAP = {
	DesaPangkalan = { { type = "Tuyul", count = 3 } },
	KuburanMbahBuyut = { { type = "Pocong", count = 5 } },
	HutanLarangan = { { type = "Genderuwo", count = 4 } },
	GunungLawu = { { type = "SundelBolong", count = 3 } },
	PuraBali = { { type = "Leak", count = 3 } },
	GoaPetruk = { { type = "Kuntilanak", count = 4 } },
	PasarSetan = {
		{ type = "SetanPasar", count = 1 },
		{ type = "Pocong", count = 3 },
		{ type = "Kuntilanak", count = 3 },
	},
	LautSelatan = { { type = "ButoIjo", count = 4 } },
	KawahBromo = { { type = "Banaspati", count = 5 } },
	HutanBambu = {
		{ type = "WeweGombel", count = 2 },
		{ type = "Kuntilanak", count = 3 },
	},
	BorobudurBawahTanah = { { type = "BuddhaWraith", count = 1 } },
	PulauKomodo = {
		{ type = "NagaKomodo", count = 1 },
		{ type = "Tuyul", count = 4 },
	},
} :: { [string]: { EnemySpawnEntry } }
table.freeze(Constants.ENEMY_SPAWN_MAP)

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
		-- spawnPos moved 80 stud south (Z-80) — courtyard outside pura, avoid
		-- player teleport-inside-stupa-solid bug.
		spawnPos = Vector3.new(2000, 5, 1920),
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
		-- spawnPos moved 150 stud east — crater rim, avoid spawn-in-lava bug.
		spawnPos = Vector3.new(4150, 155, 0),
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
		-- spawnPos moved 120 stud south — corridor entry, avoid spawn-inside-
		-- stupa-base bug (stupa center has 40-stud-wide solid tier 1).
		spawnPos = Vector3.new(0, -395, 3880),
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
