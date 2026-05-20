--!strict
--[[
	@module      GauntletConfig
	@description 6 Epic/Legendary boss map punya gauntlet: 3 progressive room
	             dengan scaling difficulty + enemy count + drop multiplier
	             sebelum unlock boss arena. Per-map theme: rooftop, underwater,
	             lava, bamboo, candi_underground, island. Tiap room: parkour
	             offset (Z forward dari map offset) + combat platform offset +
	             enemy assignment + dropMultiplier. Boss arena di end of corridor.
	@author      Claude Agent (primary coder)
]]

export type EnemyAssignment = {
	type: string,
	count: number,
}

export type RoomConfig = {
	id: number,
	parkourOffset: Vector3,
	combatOffset: Vector3,
	enemies: { EnemyAssignment },
	dropMultiplier: number,
}

export type BossMinion = {
	type: string,
	count: number,
}

export type BossConfig = {
	type: string,
	count: number,
	minions: { BossMinion }?,
}

export type MapGauntletConfig = {
	theme: string,
	rooms: { RoomConfig },
	bossOffset: Vector3,
	bossEnemy: BossConfig,
	bossDropMultiplier: number,
}

local GauntletConfig: { [string]: MapGauntletConfig } = {
	PasarSetan = {
		theme = "rooftop",
		rooms = {
			{
				id = 1,
				parkourOffset = Vector3.new(0, 0, 0),
				combatOffset = Vector3.new(0, 0, 60),
				enemies = { { type = "Pocong", count = 3 } },
				dropMultiplier = 1.0,
			},
			{
				id = 2,
				parkourOffset = Vector3.new(0, 5, 120),
				combatOffset = Vector3.new(0, 0, 180),
				enemies = {
					{ type = "Kuntilanak", count = 3 },
					{ type = "Pocong", count = 2 },
				},
				dropMultiplier = 1.5,
			},
			{
				id = 3,
				parkourOffset = Vector3.new(0, 10, 240),
				combatOffset = Vector3.new(0, 0, 300),
				enemies = {
					{ type = "WeweGombel", count = 2 },
					{ type = "Kuntilanak", count = 4 },
				},
				dropMultiplier = 2.0,
			},
		},
		bossOffset = Vector3.new(0, 0, 380),
		bossEnemy = {
			type = "SetanPasar",
			count = 1,
			minions = { { type = "Tuyul", count = 2 } },
		},
		bossDropMultiplier = 3.0,
	},
	LautSelatan = {
		theme = "underwater",
		rooms = {
			{
				id = 1,
				parkourOffset = Vector3.new(0, 0, 0),
				combatOffset = Vector3.new(0, 0, 60),
				enemies = { { type = "ButoIjo", count = 2 } },
				dropMultiplier = 1.0,
			},
			{
				id = 2,
				parkourOffset = Vector3.new(0, 5, 120),
				combatOffset = Vector3.new(0, 0, 180),
				enemies = {
					{ type = "ButoIjo", count = 3 },
					{ type = "Genderuwo", count = 2 },
				},
				dropMultiplier = 1.5,
			},
			{
				id = 3,
				parkourOffset = Vector3.new(0, 10, 240),
				combatOffset = Vector3.new(0, 0, 300),
				enemies = {
					{ type = "ButoIjo", count = 4 },
					{ type = "SundelBolong", count = 2 },
				},
				dropMultiplier = 2.0,
			},
		},
		bossOffset = Vector3.new(0, 0, 380),
		bossEnemy = { type = "NagaKomodo", count = 1 },
		bossDropMultiplier = 3.0,
	},
	KawahBromo = {
		theme = "lava",
		rooms = {
			{
				id = 1,
				parkourOffset = Vector3.new(0, 0, 0),
				combatOffset = Vector3.new(0, 0, 60),
				enemies = { { type = "Banaspati", count = 2 } },
				dropMultiplier = 1.0,
			},
			{
				id = 2,
				parkourOffset = Vector3.new(0, 5, 120),
				combatOffset = Vector3.new(0, 0, 180),
				enemies = {
					{ type = "Banaspati", count = 3 },
					{ type = "Genderuwo", count = 2 },
				},
				dropMultiplier = 1.5,
			},
			{
				id = 3,
				parkourOffset = Vector3.new(0, 10, 240),
				combatOffset = Vector3.new(0, 0, 300),
				enemies = { { type = "Banaspati", count = 5 } },
				dropMultiplier = 2.0,
			},
		},
		bossOffset = Vector3.new(0, 0, 380),
		bossEnemy = { type = "BuddhaWraith", count = 1 },
		bossDropMultiplier = 3.0,
	},
	HutanBambu = {
		theme = "bamboo",
		rooms = {
			{
				id = 1,
				parkourOffset = Vector3.new(0, 0, 0),
				combatOffset = Vector3.new(0, 0, 60),
				enemies = { { type = "Kuntilanak", count = 2 } },
				dropMultiplier = 1.0,
			},
			{
				id = 2,
				parkourOffset = Vector3.new(0, 5, 120),
				combatOffset = Vector3.new(0, 0, 180),
				enemies = {
					{ type = "WeweGombel", count = 2 },
					{ type = "Kuntilanak", count = 2 },
				},
				dropMultiplier = 1.5,
			},
			{
				id = 3,
				parkourOffset = Vector3.new(0, 10, 240),
				combatOffset = Vector3.new(0, 0, 300),
				enemies = {
					{ type = "WeweGombel", count = 3 },
					{ type = "Leak", count = 3 },
				},
				dropMultiplier = 2.0,
			},
		},
		bossOffset = Vector3.new(0, 0, 380),
		bossEnemy = { type = "SetanPasar", count = 1 },
		bossDropMultiplier = 3.0,
	},
	BorobudurBawahTanah = {
		theme = "candi_underground",
		rooms = {
			{
				id = 1,
				parkourOffset = Vector3.new(0, 0, 0),
				combatOffset = Vector3.new(0, 0, 60),
				enemies = { { type = "Pocong", count = 3 } },
				dropMultiplier = 1.0,
			},
			{
				id = 2,
				parkourOffset = Vector3.new(0, 5, 120),
				combatOffset = Vector3.new(0, 0, 180),
				enemies = {
					{ type = "Leak", count = 3 },
					{ type = "Kuntilanak", count = 2 },
				},
				dropMultiplier = 1.5,
			},
			{
				id = 3,
				parkourOffset = Vector3.new(0, 10, 240),
				combatOffset = Vector3.new(0, 0, 300),
				enemies = {
					{ type = "WeweGombel", count = 2 },
					{ type = "SundelBolong", count = 3 },
					{ type = "Banaspati", count = 2 },
				},
				dropMultiplier = 2.0,
			},
		},
		bossOffset = Vector3.new(0, 0, 380),
		bossEnemy = { type = "BuddhaWraith", count = 1 },
		bossDropMultiplier = 3.0,
	},
	PulauKomodo = {
		theme = "island",
		rooms = {
			{
				id = 1,
				parkourOffset = Vector3.new(0, 0, 0),
				combatOffset = Vector3.new(0, 0, 60),
				enemies = { { type = "Tuyul", count = 4 } },
				dropMultiplier = 1.0,
			},
			{
				id = 2,
				parkourOffset = Vector3.new(0, 5, 120),
				combatOffset = Vector3.new(0, 0, 180),
				enemies = {
					{ type = "Genderuwo", count = 2 },
					{ type = "Tuyul", count = 3 },
				},
				dropMultiplier = 1.5,
			},
			{
				id = 3,
				parkourOffset = Vector3.new(0, 10, 240),
				combatOffset = Vector3.new(0, 0, 300),
				enemies = {
					{ type = "ButoIjo", count = 2 },
					{ type = "SundelBolong", count = 2 },
					{ type = "WeweGombel", count = 2 },
				},
				dropMultiplier = 2.0,
			},
		},
		bossOffset = Vector3.new(0, 0, 380),
		bossEnemy = { type = "NagaKomodo", count = 1 },
		bossDropMultiplier = 3.0,
	},
}

return GauntletConfig
