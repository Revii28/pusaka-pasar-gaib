--!strict
--[[
	@module      LootService
	@description Listen ke BindableEvent EnemyKilled (server-internal, fired
	             dari EnemyAI.die). Roll LootTables[tier] → spawn drop Part
	             di workspace.Drops folder. Drop Part: Neon Ball 2x2x2
	             tier-colored, PointLight glow, BillboardGui icon+name floating,
	             ProximityPrompt "Pickup", TweenService floating bob Y±1 every
	             2s infinite reverse. Auto-despawn 90s untuk cegah clutter.
	             PickupService nyusul commit 2 — sekarang drop muncul tapi
	             belum bisa di-pickup (cuma visual + prompt yang gak handled).
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items"))
local LootTables = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LootTables"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local LootService = {}

local DROPS_FOLDER_NAME = "Drops"
local DROP_LIFETIME = 90
local DROP_SIZE = Vector3.new(2, 2, 2)
local DROP_TRANSPARENCY = 0.2
local FLOAT_AMPLITUDE = 1
local FLOAT_PERIOD = 2

local TIER_COLORS: { [string]: Color3 } = {
	Consumable = Color3.fromRGB(180, 180, 180),
	Common = Color3.fromRGB(220, 220, 220),
	Uncommon = Color3.fromRGB(60, 210, 80),
	Rare = Color3.fromRGB(60, 120, 240),
	Epic = Color3.fromRGB(170, 70, 240),
	Legendary = Color3.fromRGB(255, 190, 60),
}

local function getOrCreateDropsFolder(): Folder
	local existing = workspace:FindFirstChild(DROPS_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = DROPS_FOLDER_NAME
	folder.Parent = workspace
	return folder
end

local function spawnDrop(itemId: string, item: Items.ItemDef, position: Vector3)
	local color = TIER_COLORS[item.tier] or Color3.new(1, 1, 1)

	local drop = Instance.new("Part")
	drop.Name = "PusakaDrop_" .. itemId
	drop.Shape = Enum.PartType.Ball
	drop.Size = DROP_SIZE
	drop.Material = Enum.Material.Neon
	drop.Color = color
	drop.Transparency = DROP_TRANSPARENCY
	drop.Position = position + Vector3.new(0, 3, 0)
	drop.Anchored = true
	drop.CanCollide = false
	drop:SetAttribute("ItemId", itemId)
	drop:SetAttribute("ItemTier", item.tier)

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 10
	light.Brightness = 2.5
	light.Parent = drop

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pickup"
	prompt.ObjectText = ("%s [%s]"):format(item.name, item.tier)
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = drop

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DropTag"
	billboard.Size = UDim2.fromOffset(220, 44)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.Parent = drop

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = ("%s %s"):format(item.icon, item.name)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Parent = billboard

	drop.Parent = getOrCreateDropsFolder()

	local floatInfo =
		TweenInfo.new(FLOAT_PERIOD, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(drop, floatInfo, {
		Position = drop.Position + Vector3.new(0, FLOAT_AMPLITUDE, 0),
	}):Play()

	task.delay(DROP_LIFETIME, function()
		if drop and drop.Parent then
			drop:Destroy()
		end
	end)
end

function LootService.handleKill(
	killer: Player?,
	enemyType: string,
	position: Vector3,
	dropMultiplier: number?
)
	local enemyData = Constants.ENEMIES[enemyType]
	if not enemyData then
		warn(("[LootService] Unknown enemyType: %s"):format(tostring(enemyType)))
		return
	end

	local itemId = LootTables.rollFromTier(enemyData.tier)
	if not itemId then
		print(("[LootService] %s dropped nothing (tier %s)"):format(enemyType, enemyData.tier))
		return
	end

	local baseItem = Items[itemId]
	if not baseItem then
		warn(("[LootService] Item lookup failed: %s"):format(itemId))
		return
	end

	-- Gauntlet hook: scale item value + tag name dengan multiplier kalau >1.0.
	local mult = dropMultiplier or 1.0
	local item: Items.ItemDef = baseItem
	if mult > 1.0 then
		local suffix = if mult >= 3.0 then " (Boss)" elseif mult >= 2.0 then " (+)" else ""
		item = {
			name = baseItem.name .. suffix,
			tier = baseItem.tier,
			icon = baseItem.icon,
			value = math.floor(baseItem.value * mult),
		}
	end

	spawnDrop(itemId, item, position)
	print(
		("[LootService] %s dropped %s (%s) [x%.1f] at (%.0f, %.0f, %.0f) — killer: %s"):format(
			enemyType,
			item.name,
			item.tier,
			mult,
			position.X,
			position.Y,
			position.Z,
			if killer then killer.Name else "Unknown"
		)
	)
end

function LootService.init()
	Remotes.getBindable("EnemyKilled").Event
		:Connect(function(killer, enemyType, position, dropMultiplier)
			LootService.handleKill(killer, enemyType, position, dropMultiplier)
		end)
	print("[LootService] Listening for EnemyKilled events.")
end

return LootService
