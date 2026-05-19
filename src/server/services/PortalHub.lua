--!strict
--[[
	@module      PortalHub
	@description Build 12 portal arc di radius 25 stud dari spawn center (0,0,0),
	             distributed 360° (gap 30° per portal). Iterate Constants.MAPS,
	             compute portalX = sin(angle)*25, portalZ = cos(angle)*25. Tiap
	             portal: floor pad Cylinder Neon tier-color, 2 pilar stone +
	             arch top horizontal, glow plane animated pulsing transparency
	             0.3<->0.6 every 1.5s, SurfaceGui label Garamond gold, PointLight
	             tier-color, ProximityPrompt "Masuk" yang fire
	             PortalService.teleportToMap(player, mapId).
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local serverFolder = ServerScriptService:WaitForChild("Server")
local PortalService = require(serverFolder:WaitForChild("services"):WaitForChild("PortalService"))

local PortalHub = {}

local PORTAL_RADIUS = 25
local PAD_DIAMETER = 8
local PAD_THICKNESS = 0.5
local PILLAR_HEIGHT = 12
local PILLAR_DIAMETER = 1
local PILLAR_SIDE_OFFSET = 3
local ARCH_TOP_LENGTH = 7
local GLOW_SIZE = Vector3.new(7, 10, 0.4)
local SIGN_SIZE = Vector3.new(7, 1.4, 0.2)

local STONE_COLOR = Color3.fromRGB(70, 65, 65)
local SIGN_BG_COLOR = Color3.fromRGB(70, 40, 18)
local SIGN_TEXT_COLOR = Color3.fromRGB(220, 190, 110)

local TIER_COLORS: { [string]: Color3 } = {
	Starter = Color3.fromRGB(240, 240, 240),
	Common = Color3.fromRGB(160, 160, 160),
	Uncommon = Color3.fromRGB(80, 200, 90),
	Rare = Color3.fromRGB(80, 130, 230),
	Epic = Color3.fromRGB(180, 80, 230),
	Legendary = Color3.fromRGB(255, 200, 60),
}

local function buildPortal(mapData: Constants.MapData, baseCFrame: CFrame, parent: Instance)
	local model = Instance.new("Model")
	model.Name = ("Portal_%s"):format(mapData.id)

	local tierColor = TIER_COLORS[mapData.tier] or Color3.fromRGB(255, 255, 255)

	local pad = Instance.new("Part")
	pad.Name = "Pad"
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(PAD_THICKNESS, PAD_DIAMETER, PAD_DIAMETER)
	pad.CFrame = baseCFrame
		* CFrame.new(0, PAD_THICKNESS / 2, 0)
		* CFrame.Angles(0, 0, math.rad(90))
	pad.Anchored = true
	pad.CanCollide = true
	pad.Material = Enum.Material.Neon
	pad.Color = tierColor
	pad.Transparency = 0.15
	pad.Parent = model

	for i, sideX in ipairs({ -PILLAR_SIDE_OFFSET, PILLAR_SIDE_OFFSET }) do
		local pillar = Instance.new("Part")
		pillar.Name = ("Pillar%d"):format(i)
		pillar.Shape = Enum.PartType.Cylinder
		pillar.Size = Vector3.new(PILLAR_HEIGHT, PILLAR_DIAMETER, PILLAR_DIAMETER)
		pillar.CFrame = baseCFrame
			* CFrame.new(sideX, PILLAR_HEIGHT / 2, 0)
			* CFrame.Angles(0, 0, math.rad(90))
		pillar.Anchored = true
		pillar.CanCollide = true
		pillar.Material = Enum.Material.Slate
		pillar.Color = STONE_COLOR
		pillar.Parent = model
	end

	local archTop = Instance.new("Part")
	archTop.Name = "ArchTop"
	archTop.Shape = Enum.PartType.Cylinder
	archTop.Size = Vector3.new(ARCH_TOP_LENGTH, PILLAR_DIAMETER, PILLAR_DIAMETER)
	archTop.CFrame = baseCFrame * CFrame.new(0, PILLAR_HEIGHT + PILLAR_DIAMETER / 2, 0)
	archTop.Anchored = true
	archTop.CanCollide = true
	archTop.Material = Enum.Material.Slate
	archTop.Color = STONE_COLOR
	archTop.Parent = model

	local glow = Instance.new("Part")
	glow.Name = "GlowPlane"
	glow.Size = GLOW_SIZE
	glow.CFrame = baseCFrame * CFrame.new(0, GLOW_SIZE.Y / 2 + 0.5, 0)
	glow.Anchored = true
	glow.CanCollide = false
	glow.Material = Enum.Material.Neon
	glow.Color = tierColor
	glow.Transparency = 0.3
	glow.Parent = model

	local pulseInfo =
		TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(glow, pulseInfo, { Transparency = 0.6 }):Play()

	local glowLight = Instance.new("PointLight")
	glowLight.Color = tierColor
	glowLight.Brightness = 3
	glowLight.Range = 20
	glowLight.Parent = glow

	local sign = Instance.new("Part")
	sign.Name = "Signboard"
	sign.Size = SIGN_SIZE
	sign.CFrame = baseCFrame * CFrame.new(0, PILLAR_HEIGHT + 1.7, 0)
	sign.Anchored = true
	sign.CanCollide = false
	sign.Material = Enum.Material.Wood
	sign.Color = SIGN_BG_COLOR
	sign.Parent = model

	local surfGui = Instance.new("SurfaceGui")
	surfGui.Face = Enum.NormalId.Back
	surfGui.LightInfluence = 0
	surfGui.PixelsPerStud = 50
	surfGui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = ("%s\n[%s]"):format(mapData.displayName:upper(), mapData.tier)
	label.Font = Enum.Font.Garamond
	label.TextColor3 = SIGN_TEXT_COLOR
	label.TextScaled = true
	label.RichText = false
	label.Parent = surfGui

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Masuk"
	prompt.ObjectText = mapData.displayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad

	prompt.Triggered:Connect(function(player)
		PortalService.teleportToMap(player, mapData.id)
	end)

	model.Parent = parent
end

function PortalHub.build(): Model
	local hub = Instance.new("Model")
	hub.Name = "PortalHub"
	hub.Parent = workspace

	for i, mapData in ipairs(Constants.MAPS) do
		local angle = math.rad((i - 1) * 30)
		local portalX = math.sin(angle) * PORTAL_RADIUS
		local portalZ = math.cos(angle) * PORTAL_RADIUS
		local portalPos = Vector3.new(portalX, 0, portalZ)
		local baseCFrame = CFrame.lookAt(portalPos, Vector3.new(0, 0, portalZ * 0))
		-- LookVector points from portal toward center → arch front faces center.
		buildPortal(mapData, baseCFrame, hub)
	end

	print(
		("[PortalHub] %d portals built around spawn (radius %d)."):format(
			#Constants.MAPS,
			PORTAL_RADIUS
		)
	)
	return hub
end

return PortalHub
