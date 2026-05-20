--!strict
--[[
	@module      Remotes
	@description RemoteEvent registry. Client & server panggil Remotes.get(name)
	             buat lookup atau auto-create RemoteEvent di
	             ReplicatedStorage.Remotes folder. Server bisa create on demand,
	             client tunggu via WaitForChild kalau belum exist. Pattern ini
	             pas buat lazy-init: kalau server ngirim RemoteEvent baru tengah
	             game, client tetap bisa subscribe.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local REMOTES_FOLDER_NAME = "Remotes"

local Remotes = {}

local function getOrCreateFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if RunService:IsServer() then
		local folder = Instance.new("Folder")
		folder.Name = REMOTES_FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME) :: Folder
end

function Remotes.get(name: string): RemoteEvent
	local folder = getOrCreateFolder()
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	if RunService:IsServer() then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
