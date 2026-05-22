--!strict
--[[
	@module      PickupService
	@description Server pickup handler. Any BasePart tagged "Pickup"
	             (CollectionService) with attributes ItemId (string) and optional
	             Qty (number, default 1) is picked up on player touch →
	             InventoryService.addItem. Full pickup destroys the part; partial
	             (inventory full) leaves it with the remaining Qty.
	@author      Claude Agent (primary coder)
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local serverFolder = ServerScriptService:WaitForChild("Server")
local InventoryService =
	require(serverFolder:WaitForChild("inventory"):WaitForChild("InventoryService"))

local PickupService = {}

local PICKUP_TAG = "Pickup"
local connected: { [Instance]: boolean } = {}

local function handleTouch(part: BasePart, hit: BasePart)
	local char = hit.Parent
	if not char then
		return
	end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then
		return
	end
	local itemId = part:GetAttribute("ItemId")
	if typeof(itemId) ~= "string" then
		return
	end
	local qty = (part:GetAttribute("Qty") or 1) :: number

	local success, remaining = InventoryService.addItem(player, itemId, qty)
	local taken = qty - remaining
	if taken > 0 then
		print(("[PickupService] %s picked up %s x%d"):format(player.Name, itemId, taken))
	end
	if success then
		part:Destroy()
	else
		-- Partial pickup: leave the remaining quantity on the part.
		part:SetAttribute("Qty", remaining)
	end
end

local function connectPart(inst: Instance)
	if connected[inst] or not inst:IsA("BasePart") then
		return
	end
	connected[inst] = true
	local part = inst :: BasePart
	part.Touched:Connect(function(hit: BasePart)
		handleTouch(part, hit)
	end)
end

function PickupService.start()
	for _, inst in ipairs(CollectionService:GetTagged(PICKUP_TAG)) do
		connectPart(inst)
	end
	CollectionService:GetInstanceAddedSignal(PICKUP_TAG):Connect(connectPart)
	print("[PickupService] ready")
end

return PickupService
