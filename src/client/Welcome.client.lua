--!strict
--[[
	@module      Welcome
	@description Client-side welcome banner. Spawn TextLabel "Selamat datang di
	             Pasar Gaib" di tengah layar saat player join. Phase 2 smoke test —
	             nanti diganti / di-extend pas UI sistem Pasar Gaib jadi.
	@author      Claude Agent (primary coder)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local GOLD = Color3.fromRGB(212, 175, 55)
local DARK = Color3.fromRGB(15, 15, 20)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WelcomeGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Name = "WelcomeLabel"
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.5)
label.Size = UDim2.fromOffset(600, 96)
label.BackgroundColor3 = DARK
label.BackgroundTransparency = 0.35
label.BorderSizePixel = 0
label.Text = "Selamat datang di Pasar Gaib"
label.Font = Enum.Font.Cartoon
label.TextSize = 32
label.TextColor3 = GOLD
label.TextStrokeTransparency = 0.6
label.Parent = screenGui

if Constants.DEBUG_MODE then
	print(("[Welcome] UI mounted for %s (v%s)"):format(player.Name, Constants.VERSION))
end
