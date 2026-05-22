--!strict
--[[
	@module      PlayerDataService
	@description Per-player persistent data (DataStore "PlayerData_v2"). In-memory
	             cache + dirty flag, retry-with-backoff GetAsync/SetAsync, 60s
	             autosave, BindToClose flush. Schema migration: missing keys
	             filled from DEFAULT_DATA. Grants starter items once per player
	             (grantedStarters flag) via InventoryService (lazy-required to
	             avoid a require cycle).
	@author      Claude Agent (primary coder)
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local InventoryConfig = require(sharedFolder:WaitForChild("InventoryConfig"))

local PlayerDataService = {}

local store = DataStoreService:GetDataStore(InventoryConfig.DATASTORE_NAME)

local dataByPlayer: { [Player]: any } = {}
local dirtyByPlayer: { [Player]: boolean } = {}

local function defaultData(): any
	return {
		inventory = { hotbar = {}, bag = {} },
		currency = { setanCoin = 0 },
		stats = { level = 1, xp = 0 },
		grantedStarters = false,
	}
end

-- Fill any missing keys (incl. nested) from default — schema migration.
local function mergeDefaults(data: any, default: any): any
	for k, v in pairs(default) do
		if data[k] == nil then
			data[k] = if typeof(v) == "table" then mergeDefaults({}, v) else v
		elseif typeof(v) == "table" and typeof(data[k]) == "table" then
			mergeDefaults(data[k], v)
		end
	end
	return data
end

-- DataStore JSON round-trips integer keys to STRING keys; restore int slot keys.
local function normalizeSlots(container: any): any
	local out = {}
	for k, v in pairs(container) do
		out[tonumber(k) or k] = v
	end
	return out
end

local function retry(fn: () -> any): (boolean, any)
	local waitTime = 1
	for attempt = 1, InventoryConfig.DATASTORE_RETRY_COUNT do
		local ok, res = pcall(fn)
		if ok then
			return true, res
		end
		warn(("[PlayerDataService] DataStore attempt %d failed: %s"):format(attempt, tostring(res)))
		if attempt < InventoryConfig.DATASTORE_RETRY_COUNT then
			task.wait(waitTime)
			waitTime *= InventoryConfig.DATASTORE_RETRY_BACKOFF
		end
	end
	return false, nil
end

function PlayerDataService.get(player: Player, key: string): any
	local data = dataByPlayer[player]
	return if data then data[key] else nil
end

function PlayerDataService.set(player: Player, key: string, value: any)
	local data = dataByPlayer[player]
	if data then
		data[key] = value
		dirtyByPlayer[player] = true
	end
end

function PlayerDataService.load(player: Player)
	local loaded: any = nil
	local ok, res = retry(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if ok and typeof(res) == "table" then
		loaded = res
	end

	local data = mergeDefaults(loaded or {}, defaultData())
	data.inventory.hotbar = normalizeSlots(data.inventory.hotbar)
	data.inventory.bag = normalizeSlots(data.inventory.bag)
	dataByPlayer[player] = data

	if not data.grantedStarters then
		-- Lazy require breaks the InventoryService <-> PlayerDataService cycle.
		local InventoryService =
			require(ServerScriptService.Server.inventory.InventoryService) :: any
		for _, entry in ipairs(InventoryConfig.STARTER_ITEMS) do
			InventoryService.addItem(player, entry.itemId, entry.qty)
		end
		data.grantedStarters = true
		dirtyByPlayer[player] = true
	end
	print(("[PlayerDataService] Loaded data for %s"):format(player.Name))
end

function PlayerDataService.save(player: Player)
	if not dirtyByPlayer[player] then
		return
	end
	local data = dataByPlayer[player]
	if not data then
		return
	end
	local ok = retry(function()
		store:SetAsync(tostring(player.UserId), data)
	end)
	if ok then
		dirtyByPlayer[player] = nil
		print(("[PlayerDataService] Saved data for %s"):format(player.Name))
	else
		warn(("[PlayerDataService] FAILED to save %s after retries"):format(player.Name))
	end
end

function PlayerDataService.init()
	Players.PlayerAdded:Connect(function(player)
		PlayerDataService.load(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		PlayerDataService.save(player)
		dataByPlayer[player] = nil
		dirtyByPlayer[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerDataService.load, player)
	end

	task.spawn(function()
		while true do
			task.wait(InventoryConfig.AUTOSAVE_INTERVAL)
			for player in pairs(dataByPlayer) do
				PlayerDataService.save(player)
			end
		end
	end)

	game:BindToClose(function()
		for player in pairs(dataByPlayer) do
			PlayerDataService.save(player)
		end
	end)
end

return PlayerDataService
