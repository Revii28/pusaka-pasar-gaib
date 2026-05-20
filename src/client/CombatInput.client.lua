--!strict
--[[
	@module      CombatInput
	@description Client-side M1 melee input handler. UIS.InputBegan LMB →
	             debounce 0.4s local-side → fire Remotes.get("CombatM1") ke
	             server. Server validate cooldown + range + apply damage.
	             Local debounce hindarin spam network; canonical cooldown tetap
	             di server via Constants.COMBAT.m1Cooldown.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local LOCAL_DEBOUNCE = 0.4

local m1Remote = Remotes.get("CombatM1")
local lastClickTime = 0

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	local now = os.clock()
	if now - lastClickTime < LOCAL_DEBOUNCE then
		return
	end
	lastClickTime = now
	m1Remote:FireServer()
end)
