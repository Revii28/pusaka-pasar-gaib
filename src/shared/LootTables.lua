--!strict
--[[
	@module      LootTables
	@description Weighted loot table per enemy tier. rollFromTier(tier) returns
	             itemId string atau nil (no drop). Total weight per tier ≈ 100
	             jadi feels percentage-like, gampang tweak.
	             - Trash: 30% no drop + 70% consumable
	             - Common: 100% pusaka common (small chance uncommon)
	             - Uncommon: common pusaka + uncommon shift
	             - Rare/Epic/Boss/Legendary: progressive higher-tier weighted
	@author      Claude Agent (primary coder)
]]

export type LootEntry = {
	item: string?,
	weight: number,
}

local LootTables = {}

local TABLES: { [string]: { LootEntry } } = {
	Trash = {
		{ item = nil, weight = 30 },
		{ item = "air_suci", weight = 20 },
		{ item = "garam_kasar", weight = 20 },
		{ item = "lilin_putih", weight = 15 },
		{ item = "bawang_putih", weight = 10 },
		{ item = "korek_api", weight = 5 },
	},
	Common = {
		{ item = "koin_tua", weight = 18 },
		{ item = "bunga_kemboja", weight = 14 },
		{ item = "kain_kafan_robek", weight = 14 },
		{ item = "tanah_kuburan", weight = 12 },
		{ item = "garam_halus", weight = 10 },
		{ item = "beras_kuning", weight = 10 },
		{ item = "daun_pandan", weight = 8 },
		{ item = "tulang_ayam", weight = 8 },
		{ item = "lilin_hitam", weight = 4 },
		{ item = "air_liur_pocong", weight = 2 },
	},
	Uncommon = {
		{ item = "jimat_sederhana", weight = 25 },
		{ item = "rambut_kuntilanak", weight = 18 },
		{ item = "keris_bambu", weight = 15 },
		{ item = "cincin_mbah", weight = 12 },
		{ item = "mata_setan", weight = 10 },
		{ item = "topeng_leak", weight = 8 },
		{ item = "pasir_selatan", weight = 7 },
		{ item = "abu_bromo", weight = 5 },
	},
	Rare = {
		{ item = "keris_empu", weight = 25 },
		{ item = "kalung_garuda", weight = 20 },
		{ item = "mustika_hitam", weight = 18 },
		{ item = "tasbih_walisongo", weight = 17 },
		{ item = "caping_petruk", weight = 12 },
		{ item = "mata_setan", weight = 5 },
		{ item = "topeng_leak", weight = 3 },
	},
	Epic = {
		{ item = "mustika_merah", weight = 25 },
		{ item = "keris_mpu_gandring", weight = 20 },
		{ item = "selendang_nyiroro", weight = 18 },
		{ item = "tongkat_kalijaga", weight = 15 },
		{ item = "keris_empu", weight = 10 },
		{ item = "kalung_garuda", weight = 7 },
		{ item = "mustika_hitam", weight = 5 },
	},
	Boss = {
		{ item = "mustika_merah", weight = 28 },
		{ item = "keris_mpu_gandring", weight = 22 },
		{ item = "selendang_nyiroro", weight = 18 },
		{ item = "tongkat_kalijaga", weight = 15 },
		{ item = "naga_sasra", weight = 8 },
		{ item = "mahkota_buddha", weight = 5 },
		{ item = "bulu_perindu", weight = 4 },
	},
	Legendary = {
		{ item = "naga_sasra", weight = 32 },
		{ item = "mahkota_buddha", weight = 28 },
		{ item = "bulu_perindu", weight = 22 },
		{ item = "mustika_merah", weight = 10 },
		{ item = "keris_mpu_gandring", weight = 8 },
	},
}

function LootTables.rollFromTier(tier: string): string?
	local entries = TABLES[tier]
	if not entries then
		return nil
	end
	local total = 0
	for _, entry in ipairs(entries) do
		total += entry.weight
	end
	local roll = math.random() * total
	local cumulative = 0
	for _, entry in ipairs(entries) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.item
		end
	end
	return nil
end

return LootTables
