--!strict
--[[
	@module      MapManager
	@description Orchestrator buat 12 map module. Iterate Constants.MAPS, require
	             Map%02d_<id> dari src/server/maps/, pcall mapModule.build(mapData,
	             mapsFolder). Per-map fail di-warn, gak cascade-abort ke yang lain.
	             Folder workspace.Maps jadi parent untuk semua 12 map model.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local MapManager = {}

function MapManager.buildAll(): Folder
	local existing = workspace:FindFirstChild("Maps")
	if existing then
		existing:Destroy()
	end
	local mapsFolder = Instance.new("Folder")
	mapsFolder.Name = "Maps"
	mapsFolder.Parent = workspace

	local mapsModuleFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("maps")
	local successCount = 0

	for i, mapData in ipairs(Constants.MAPS) do
		local moduleName = string.format("Map%02d_%s", i, mapData.id)
		local moduleScript = mapsModuleFolder:FindFirstChild(moduleName)
		if not moduleScript then
			warn(("[MapManager] Module %s NOT FOUND"):format(moduleName))
			continue
		end

		local ok, err = pcall(function()
			local mapModule = require(moduleScript) :: any
			mapModule.build(mapData, mapsFolder)
		end)
		if ok then
			successCount += 1
		else
			warn(("[MapManager] Failed to build %s: %s"):format(mapData.displayName, tostring(err)))
		end
	end

	print(("[MapManager] %d/%d maps built."):format(successCount, #Constants.MAPS))
	return mapsFolder
end

return MapManager
