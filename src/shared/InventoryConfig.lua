--!strict
--[[
	@module      InventoryConfig
	@description Inventory + persistence tunables (shared). Slot caps, stack
	             size, starter grant, DataStore name + autosave/retry policy.
	@author      Claude Agent (primary coder)
]]

local InventoryConfig = {}

InventoryConfig.HOTBAR_SLOTS = 10
InventoryConfig.BAG_SLOTS = 20
InventoryConfig.MAX_STACK_SIZE = 99

InventoryConfig.STARTER_ITEMS = {
	{ itemId = "MinyakWangiKembang", qty = 3 },
	{ itemId = "JimatPenangkalSetan", qty = 1 },
	{ itemId = "AirSucu", qty = 2 },
}

InventoryConfig.DATASTORE_NAME = "PlayerData_v2"
InventoryConfig.AUTOSAVE_INTERVAL = 60 -- seconds
InventoryConfig.DATASTORE_RETRY_COUNT = 3
InventoryConfig.DATASTORE_RETRY_BACKOFF = 1.5 -- backoff multiplier

return InventoryConfig
