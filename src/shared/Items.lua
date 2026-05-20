--!strict
--[[
	@module      Items
	@description Catalog 30 pusaka (10 Common + 8 Uncommon + 5 Rare + 4 Epic +
	             3 Legendary) + 5 consumable. Tiap item punya icon emoji,
	             display name, tier, dan value (placeholder buat trade/shop
	             Phase 5+). Items diakses by string itemId di LootTables &
	             InventoryService.
	@author      Claude Agent (primary coder)
]]

export type ItemDef = {
	name: string,
	tier: string,
	icon: string,
	value: number,
}

local Items: { [string]: ItemDef } = {
	koin_tua = { name = "Koin Tua", tier = "Common", icon = "🪙", value = 10 },
	bunga_kemboja = { name = "Bunga Kemboja", tier = "Common", icon = "🌼", value = 8 },
	kain_kafan_robek = { name = "Kain Kafan Robek", tier = "Common", icon = "🧶", value = 12 },
	tanah_kuburan = { name = "Tanah Kuburan", tier = "Common", icon = "⚱️", value = 6 },
	lilin_hitam = { name = "Lilin Hitam", tier = "Common", icon = "🕯️", value = 15 },
	garam_halus = { name = "Garam Halus", tier = "Common", icon = "🧂", value = 5 },
	beras_kuning = { name = "Beras Kuning", tier = "Common", icon = "🍚", value = 7 },
	daun_pandan = { name = "Daun Pandan", tier = "Common", icon = "🌿", value = 4 },
	air_liur_pocong = { name = "Air Liur Pocong", tier = "Common", icon = "💧", value = 20 },
	tulang_ayam = { name = "Tulang Ayam", tier = "Common", icon = "🦴", value = 9 },

	rambut_kuntilanak = { name = "Rambut Kuntilanak", tier = "Uncommon", icon = "💁", value = 50 },
	mata_setan = { name = "Mata Setan", tier = "Uncommon", icon = "👁️", value = 75 },
	jimat_sederhana = { name = "Jimat Sederhana", tier = "Uncommon", icon = "🧿", value = 60 },
	keris_bambu = { name = "Keris Pusaka Bambu", tier = "Uncommon", icon = "🗡️", value = 80 },
	cincin_mbah = { name = "Cincin Mbah Buyut", tier = "Uncommon", icon = "💍", value = 90 },
	topeng_leak = { name = "Topeng Leak", tier = "Uncommon", icon = "🎭", value = 100 },
	pasir_selatan = {
		name = "Pasir Pantai Selatan",
		tier = "Uncommon",
		icon = "🏖️",
		value = 45,
	},
	abu_bromo = { name = "Abu Vulkanik Bromo", tier = "Uncommon", icon = "🌋", value = 55 },

	keris_empu = { name = "Keris Pusaka Empu", tier = "Rare", icon = "🗡️", value = 300 },
	kalung_garuda = { name = "Kalung Garuda Kecil", tier = "Rare", icon = "🦅", value = 350 },
	tasbih_walisongo = { name = "Tasbih Wali Songo", tier = "Rare", icon = "📿", value = 400 },
	mustika_hitam = { name = "Mustika Hitam", tier = "Rare", icon = "⬛", value = 380 },
	caping_petruk = { name = "Caping Petruk Sobek", tier = "Rare", icon = "👒", value = 320 },

	mustika_merah = { name = "Mustika Merah Darah", tier = "Epic", icon = "🔴", value = 1500 },
	keris_mpu_gandring = {
		name = "Keris Mpu Gandring",
		tier = "Epic",
		icon = "⚔️",
		value = 2000,
	},
	selendang_nyiroro = { name = "Selendang Nyi Roro", tier = "Epic", icon = "🧕", value = 1800 },
	tongkat_kalijaga = {
		name = "Tongkat Sunan Kalijaga",
		tier = "Epic",
		icon = "🪄",
		value = 2200,
	},

	naga_sasra = {
		name = "Keris Pusaka Naga Sasra",
		tier = "Legendary",
		icon = "🐉",
		value = 10000,
	},
	mahkota_buddha = {
		name = "Mahkota Buddha Bawah Tanah",
		tier = "Legendary",
		icon = "👑",
		value = 12000,
	},
	bulu_perindu = { name = "Bulu Perindu Asli", tier = "Legendary", icon = "🪶", value = 15000 },

	air_suci = { name = "Air Suci", tier = "Consumable", icon = "💧", value = 3 },
	garam_kasar = { name = "Garam Kasar", tier = "Consumable", icon = "🧂", value = 2 },
	lilin_putih = { name = "Lilin Putih", tier = "Consumable", icon = "🕯️", value = 3 },
	bawang_putih = { name = "Bawang Putih", tier = "Consumable", icon = "🧄", value = 4 },
	korek_api = { name = "Korek Api", tier = "Consumable", icon = "🔥", value = 2 },
}

table.freeze(Items)
return Items
