--!strict
--[[
	@module      InventoryController
	@description Client inventory cache. Subscribes to Remotes "InventoryUpdate"
	             and stores the latest server snapshot. UI binding is deferred
	             (Phase 4 UI). For now it just caches + logs.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local InventoryController = {}

local localInventory: any = { hotbar = {}, bag = {} }

local function countFilled(container: any): number
	local n = 0
	for _ in pairs(container or {}) do
		n += 1
	end
	return n
end

function InventoryController.getLocalInventory(): any
	return localInventory
end

function InventoryController.init()
	Remotes.get("InventoryUpdate").OnClientEvent:Connect(function(snapshot: any)
		localInventory = snapshot or { hotbar = {}, bag = {} }
		print(
			("[InventoryController] inventory updated, hotbar=%d bag=%d"):format(
				countFilled(localInventory.hotbar),
				countFilled(localInventory.bag)
			)
		)
	end)
	-- TODO: bind to inventory UI in Phase 4 UI (deferred).
end

return InventoryController
