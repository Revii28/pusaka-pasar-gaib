--!strict
--[[
	@module      InventoryService
	@description Server inventory logic. State lives in PlayerDataService under
	             "inventory" = { hotbar = {[slot]={itemId,qty}}, bag = {...} }.
	             add/remove/move/use with auto-stacking (hotbar first, then bag).
	             Pushes a full snapshot to the client via Remotes "InventoryUpdate".
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local InventoryConfig = require(sharedFolder:WaitForChild("InventoryConfig"))
local ItemRegistry = require(sharedFolder:WaitForChild("ItemRegistry"))
local Remotes = require(sharedFolder:WaitForChild("Remotes"))

local serverFolder = ServerScriptService:WaitForChild("Server")
local PlayerDataService =
	require(serverFolder:WaitForChild("data"):WaitForChild("PlayerDataService"))

local InventoryService = {}

local CONTAINERS = { "hotbar", "bag" }

local function capOf(container: string): number
	return if container == "hotbar" then InventoryConfig.HOTBAR_SLOTS else InventoryConfig.BAG_SLOTS
end

local function emptyInventory(): any
	return { hotbar = {}, bag = {} }
end

function InventoryService.getInventory(player: Player): any
	local inv = PlayerDataService.get(player, "inventory")
	if not inv then
		return emptyInventory()
	end
	return inv
end

local function fireUpdate(player: Player)
	Remotes.get("InventoryUpdate"):FireClient(player, InventoryService.getInventory(player))
end

-- Returns success (all placed), remaining (unplaced qty if inventory full).
function InventoryService.addItem(player: Player, itemId: string, qty: number): (boolean, number)
	local def = ItemRegistry.get(itemId)
	if not def then
		warn(("[InventoryService] Unknown itemId: %s"):format(tostring(itemId)))
		return false, qty
	end
	local inv = InventoryService.getInventory(player)
	local maxStack = if def.stackable then def.maxStack else 1
	local remaining = qty

	-- Phase 1: top up existing stacks (stackable only), hotbar then bag.
	if def.stackable then
		for _, container in ipairs(CONTAINERS) do
			local slots = inv[container]
			for slot = 1, capOf(container) do
				if remaining <= 0 then
					break
				end
				local s = slots[slot]
				if s and s.itemId == itemId and s.qty < maxStack then
					local add = math.min(maxStack - s.qty, remaining)
					s.qty += add
					remaining -= add
				end
			end
			if remaining <= 0 then
				break
			end
		end
	end

	-- Phase 2: fill empty slots, hotbar then bag.
	for _, container in ipairs(CONTAINERS) do
		local slots = inv[container]
		for slot = 1, capOf(container) do
			if remaining <= 0 then
				break
			end
			if slots[slot] == nil then
				local add = math.min(maxStack, remaining)
				slots[slot] = { itemId = itemId, qty = add }
				remaining -= add
			end
		end
		if remaining <= 0 then
			break
		end
	end

	PlayerDataService.set(player, "inventory", inv)
	fireUpdate(player)
	return remaining <= 0, remaining
end

function InventoryService.removeItem(player: Player, itemId: string, qty: number): boolean
	local inv = InventoryService.getInventory(player)
	local remaining = qty
	for _, container in ipairs(CONTAINERS) do
		local slots = inv[container]
		for slot = 1, capOf(container) do
			if remaining <= 0 then
				break
			end
			local s = slots[slot]
			if s and s.itemId == itemId then
				local take = math.min(s.qty, remaining)
				s.qty -= take
				remaining -= take
				if s.qty <= 0 then
					slots[slot] = nil
				end
			end
		end
	end
	PlayerDataService.set(player, "inventory", inv)
	fireUpdate(player)
	return remaining <= 0
end

function InventoryService.moveItem(
	player: Player,
	fromContainer: string,
	fromSlot: number,
	toContainer: string,
	toSlot: number
): boolean
	local inv = InventoryService.getInventory(player)
	if inv[fromContainer] == nil or inv[toContainer] == nil then
		return false
	end
	if fromSlot < 1 or fromSlot > capOf(fromContainer) then
		return false
	end
	if toSlot < 1 or toSlot > capOf(toContainer) then
		return false
	end
	local fromSlots = inv[fromContainer]
	local toSlots = inv[toContainer]
	local moving = fromSlots[fromSlot]
	if not moving then
		return false
	end
	-- Swap (handles both move-to-empty and swap-occupied).
	fromSlots[fromSlot] = toSlots[toSlot]
	toSlots[toSlot] = moving
	PlayerDataService.set(player, "inventory", inv)
	fireUpdate(player)
	return true
end

function InventoryService.useItem(player: Player, container: string, slot: number): boolean
	local inv = InventoryService.getInventory(player)
	local slots = inv[container]
	if not slots then
		return false
	end
	local s = slots[slot]
	if not s then
		return false
	end
	local def = ItemRegistry.get(s.itemId)
	if not def then
		return false
	end
	if def.useCallback then
		def.useCallback(player)
	end
	if def.stackable then
		s.qty -= 1
		if s.qty <= 0 then
			slots[slot] = nil
		end
	end
	PlayerDataService.set(player, "inventory", inv)
	fireUpdate(player)
	return true
end

function InventoryService.init()
	-- Pre-create the RemoteEvent (server-side) so clients can subscribe.
	Remotes.get("InventoryUpdate")
	print("[InventoryService] ready")
end

return InventoryService
