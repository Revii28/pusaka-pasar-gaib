--!strict
--[[
	@module      ItemRegistry
	@description Canonical item definitions (shared). Each item: id, name, tier,
	             stackable, maxStack, optional iconAssetId / useCallback /
	             weaponData. useCallback runs server-side on use (placeholder
	             effects for now).
	@author      Claude Agent (primary coder)
]]

local ItemRegistry = {}

export type WeaponData = {
	damage: number,
	range: number,
	cooldown: number,
}

export type ItemDef = {
	id: string,
	name: string,
	tier: string,
	stackable: boolean,
	maxStack: number,
	iconAssetId: string?,
	useCallback: ((player: Player) -> ())?,
	weaponData: WeaponData?,
}

local items: { [string]: ItemDef } = {
	KerisPusaka = {
		id = "KerisPusaka",
		name = "Keris Pusaka",
		tier = "Legendary",
		stackable = false,
		maxStack = 1,
		weaponData = { damage = 50, range = 8, cooldown = 1.2 },
	},
	MinyakWangiKembang = {
		id = "MinyakWangiKembang",
		name = "Minyak Wangi Kembang",
		tier = "Common",
		stackable = true,
		maxStack = 99,
		useCallback = function(player: Player)
			print("[ItemRegistry] " .. player.Name .. " used MinyakWangiKembang")
		end,
	},
	JimatPenangkalSetan = {
		id = "JimatPenangkalSetan",
		name = "Jimat Penangkal Setan",
		tier = "Rare",
		stackable = true,
		maxStack = 10,
		useCallback = function(player: Player)
			print("[ItemRegistry] " .. player.Name .. " used JimatPenangkalSetan (5s ward)")
		end,
	},
	AirSucu = {
		id = "AirSucu",
		name = "Air Suci",
		tier = "Uncommon",
		stackable = true,
		maxStack = 99,
		useCallback = function(player: Player)
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.Health = math.min(hum.MaxHealth, hum.Health + 25)
				end
			end
		end,
	},
	BungaTujuhRupa = {
		id = "BungaTujuhRupa",
		name = "Bunga Tujuh Rupa",
		tier = "Epic",
		stackable = true,
		maxStack = 20,
		useCallback = function(player: Player)
			print("[ItemRegistry] " .. player.Name .. " used BungaTujuhRupa")
		end,
	},
}

ItemRegistry.items = items

function ItemRegistry.get(itemId: string): ItemDef?
	return items[itemId]
end

function ItemRegistry.all(): { [string]: ItemDef }
	return items
end

return ItemRegistry
