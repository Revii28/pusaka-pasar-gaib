--!strict
--[[
	@module      PortalService
	@description Teleport logic — single-place workspace folder approach. Semua
	             12 map exist sekaligus di workspace, terisolasi via coordinate
	             offset (2000-4000 stud apart). Player ditelefer pakai
	             char:PivotTo(CFrame.new(spawnPos)) (modern API, replaces
	             deprecated SetPrimaryPartCFrame). PortalHub & MapHelpers
	             ProximityPrompt Triggered handlers panggil teleportToMap /
	             teleportToHub.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local PortalService = {}

local HUB_RESPAWN_CFRAME = CFrame.new(0, 5, 0)

local function findMap(mapId: string): Constants.MapData?
	for _, m in ipairs(Constants.MAPS) do
		if m.id == mapId then
			return m
		end
	end
	return nil
end

function PortalService.teleportToMap(player: Player, mapId: string)
	local mapData = findMap(mapId)
	if not mapData then
		warn(("[PortalService] Unknown mapId: %s"):format(tostring(mapId)))
		return
	end

	local char = player.Character
	if not char then
		warn(("[PortalService] %s has no Character"):format(player.Name))
		return
	end

	local ok, err = pcall(function()
		char:PivotTo(CFrame.new(mapData.spawnPos))
	end)
	if not ok then
		warn(
			("[PortalService] PivotTo failed for %s -> %s: %s"):format(
				player.Name,
				mapData.displayName,
				tostring(err)
			)
		)
		return
	end

	print(("[PortalService] Teleported %s to %s"):format(player.Name, mapData.displayName))
end

function PortalService.teleportToHub(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local ok, err = pcall(function()
		char:PivotTo(HUB_RESPAWN_CFRAME)
	end)
	if not ok then
		warn(("[PortalService] PivotTo hub failed for %s: %s"):format(player.Name, tostring(err)))
		return
	end
	print(("[PortalService] Teleported %s back to hub"):format(player.Name))
end

return PortalService
