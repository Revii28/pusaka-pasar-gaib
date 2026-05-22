--!strict
--[[
	@script      InventoryBoot
	@description Client bootstrap for InventoryController (project has no central
	             init.client.lua — Welcome/CombatInput are standalone LocalScripts,
	             so this small LocalScript inits the inventory controller).
	@author      Claude Agent (primary coder)
]]

local InventoryController =
	require(script.Parent:WaitForChild("inventory"):WaitForChild("InventoryController"))

InventoryController.init()
