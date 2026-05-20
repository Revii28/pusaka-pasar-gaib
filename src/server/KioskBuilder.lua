--!strict
--[[
	@module      KioskBuilder
	@description Build kios "wah" per NPC vendor: floor wood base, 4 pilar
	             dengan carving emas decorative, atap rumbia layered 3-strip
	             cascading, 2 lampion gantung Neon orange dengan PointLight
	             flicker tween (period 0.5-1.5s random, phase-shifted), counter
	             dengan sesajen pile (lilin merah Neon + PointLight + dupa
	             cylinder dengan smoke ParticleEmitter + 7 bunga pastel scattered
	             + mangkok sesajen di tengah), papan nama SurfaceGui di depan
	             atap (vendor name + dagangan, font Garamond color gold).
	             Kiosk oriented via CFrame.lookAt(npcPos, npcPos+lookDir) supaya
	             counter & papan menghadap customer (spawn center).
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local KioskBuilder = {}

local POLE_SIZE = Vector3.new(1, 8, 1)
local POLE_OFFSETS: { Vector3 } = {
	Vector3.new(4, 4, 4),
	Vector3.new(-4, 4, 4),
	Vector3.new(4, 4, -4),
	Vector3.new(-4, 4, -4),
}
local POLE_COLOR = Color3.fromRGB(80, 50, 25)
local CARVING_COLOR = Color3.fromRGB(180, 140, 60)
local CARVING_SIZE = Vector3.new(0.3, 0.5, 0.3)

local ROOF_STRIP_COUNT = 4
local ROOF_STRIP_SIZE = Vector3.new(11, 0.4, 3)
local ROOF_BASE_Y = 8.5
local ROOF_Y_STEP = 0.3
local ROOF_TILT_DEGREES = 6
local ROOF_COLOR = Color3.fromRGB(110, 90, 50)

local COUNTER_SIZE = Vector3.new(6, 3, 2)
local COUNTER_OFFSET = Vector3.new(0, 1.5, -3)
local COUNTER_COLOR = Color3.fromRGB(60, 35, 18)

local FLOOR_SIZE = Vector3.new(8, 0.4, 8)
local FLOOR_OFFSET = Vector3.new(0, -0.2, 0)
local FLOOR_COLOR = Color3.fromRGB(90, 65, 40)

local LAMPION_RADIUS = 1
local LAMPION_COLOR = Color3.fromRGB(255, 180, 80)
local LAMPION_STRING_SIZE = Vector3.new(0.1, 3, 0.1)
local LAMPION_STRING_COLOR = Color3.fromRGB(20, 20, 20)
local LAMPION_OFFSETS: { Vector3 } = {
	Vector3.new(-2.5, 6.5, -2.5),
	Vector3.new(2.5, 6.5, -2.5),
}
local LAMPION_LIGHT_MIN = 3
local LAMPION_LIGHT_MAX = 5
local LAMPION_LIGHT_RANGE = 12

local CANDLE_COLOR = Color3.fromRGB(200, 30, 30)
local INCENSE_COLOR = Color3.fromRGB(60, 40, 30)
local BOWL_COLOR = Color3.fromRGB(25, 22, 18)

local SIGN_SIZE = Vector3.new(4.5, 1.2, 0.2)
local SIGN_OFFSET = Vector3.new(0, 7.5, -5)
local SIGN_COLOR = Color3.fromRGB(70, 40, 18)
local SIGN_TEXT_COLOR = Color3.fromRGB(200, 170, 90)

local FLOWER_COLORS: { Color3 } = {
	Color3.fromRGB(255, 180, 200),
	Color3.fromRGB(255, 245, 160),
	Color3.fromRGB(250, 250, 250),
	Color3.fromRGB(200, 160, 230),
	Color3.fromRGB(230, 80, 80),
	Color3.fromRGB(250, 170, 90),
	Color3.fromRGB(170, 210, 240),
}

local VENDOR_WARES: { [string]: string } = {
	["Mbok Inem"] = "Kemenyan Madu • Garam • Bawang Putih",
	["Pak Tukijo"] = "Bunga 7 Rupa • Sirih • Telur Cemani",
	["Nyai Sumi"] = "Tasbih • Lilin Merah • Air Mawar",
	["Bandar Robux"] = "Robux ↔ Koin Gaib",
}

local function makePart(props: {
	name: string,
	size: Vector3,
	cframe: CFrame,
	material: Enum.Material,
	color: Color3,
	transparency: number?,
	canCollide: boolean?,
	shape: Enum.PartType?,
	parent: Instance,
}): Part
	local part = Instance.new("Part")
	part.Name = props.name
	if props.shape then
		part.Shape = props.shape
	end
	part.Size = props.size
	part.CFrame = props.cframe
	part.Material = props.material
	part.Color = props.color
	part.Transparency = props.transparency or 0
	part.Anchored = true
	part.CanCollide = if props.canCollide == nil then true else props.canCollide
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent
	return part
end

local function buildFloor(kiosk: Model, base: CFrame)
	makePart({
		name = "Floor",
		size = FLOOR_SIZE,
		cframe = base * CFrame.new(FLOOR_OFFSET),
		material = Enum.Material.Wood,
		color = FLOOR_COLOR,
		parent = kiosk,
	})
end

local function buildPolesWithCarving(kiosk: Model, base: CFrame)
	for i, localOffset in ipairs(POLE_OFFSETS) do
		local pole = makePart({
			name = ("Pole%d"):format(i),
			size = POLE_SIZE,
			cframe = base * CFrame.new(localOffset),
			material = Enum.Material.WoodPlanks,
			color = POLE_COLOR,
			parent = kiosk,
		})

		local carvingOffsets: { Vector3 } = {
			Vector3.new(0.65, 0, 0),
			Vector3.new(-0.65, 0, 0),
			Vector3.new(0, 0, 0.65),
			Vector3.new(0, 0, -0.65),
		}
		for j, off in ipairs(carvingOffsets) do
			makePart({
				name = ("Carving%d"):format(j),
				size = CARVING_SIZE,
				cframe = pole.CFrame * CFrame.new(off),
				material = Enum.Material.Metal,
				color = CARVING_COLOR,
				parent = kiosk,
			})
		end
	end
end

local function buildRoof(kiosk: Model, base: CFrame, random: Random)
	for i = 1, ROOF_STRIP_COUNT do
		local yOff = ROOF_BASE_Y + (i - 1) * ROOF_Y_STEP
		local zOff = -3 + (i - 1) * 2
		local tilt = math.rad(random:NextNumber(-ROOF_TILT_DEGREES, ROOF_TILT_DEGREES))
		makePart({
			name = ("RoofStrip%d"):format(i),
			size = ROOF_STRIP_SIZE,
			cframe = base * CFrame.new(0, yOff, zOff) * CFrame.Angles(tilt, 0, 0),
			material = Enum.Material.Fabric,
			color = ROOF_COLOR,
			parent = kiosk,
		})
	end
end

local function buildLampion(kiosk: Model, base: CFrame, localOffset: Vector3, index: number)
	local stringCFrame = base * CFrame.new(localOffset + Vector3.new(0, 1.5, 0))
	makePart({
		name = ("LampionString%d"):format(index),
		size = LAMPION_STRING_SIZE,
		cframe = stringCFrame,
		material = Enum.Material.Fabric,
		color = LAMPION_STRING_COLOR,
		canCollide = false,
		parent = kiosk,
	})

	local lampion = makePart({
		name = ("Lampion%d"):format(index),
		size = Vector3.new(LAMPION_RADIUS * 2, LAMPION_RADIUS * 2, LAMPION_RADIUS * 2),
		cframe = base * CFrame.new(localOffset),
		material = Enum.Material.Neon,
		color = LAMPION_COLOR,
		transparency = 0.2,
		canCollide = false,
		shape = Enum.PartType.Ball,
		parent = kiosk,
	})

	local light = Instance.new("PointLight")
	light.Color = LAMPION_COLOR
	light.Brightness = LAMPION_LIGHT_MIN
	light.Range = LAMPION_LIGHT_RANGE
	light.Parent = lampion

	if not Constants.PERFORMANCE.LAMPION_FLICKER_ENABLED then
		return
	end

	local random = Random.new()
	local period = 0.5 + random:NextNumber() * 1.0
	local delaySeconds = random:NextNumber() * period
	local info = TweenInfo.new(
		period,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,
		true,
		delaySeconds
	)
	local tween = TweenService:Create(light, info, { Brightness = LAMPION_LIGHT_MAX })
	tween:Play()
end

local function buildCounter(kiosk: Model, base: CFrame): Part
	return makePart({
		name = "Counter",
		size = COUNTER_SIZE,
		cframe = base * CFrame.new(COUNTER_OFFSET),
		material = Enum.Material.Wood,
		color = COUNTER_COLOR,
		parent = kiosk,
	})
end

local function buildCandle(kiosk: Model, counterTopCFrame: CFrame, sideX: number, index: number)
	local candle = makePart({
		name = ("Candle%d"):format(index),
		size = Vector3.new(0.4, 2, 0.4),
		cframe = counterTopCFrame * CFrame.new(sideX, 1, 0),
		material = Enum.Material.Neon,
		color = CANDLE_COLOR,
		transparency = 0.05,
		canCollide = false,
		shape = Enum.PartType.Cylinder,
		parent = kiosk,
	}) :: Part
	candle.CFrame = candle.CFrame * CFrame.Angles(0, 0, math.rad(90))

	local flame = Instance.new("PointLight")
	flame.Color = Color3.fromRGB(255, 140, 90)
	flame.Brightness = 2
	flame.Range = 4
	flame.Parent = candle
end

local function buildIncense(kiosk: Model, counterTopCFrame: CFrame, offsetX: number, index: number)
	local stick = makePart({
		name = ("Incense%d"):format(index),
		size = Vector3.new(0.2, 3, 0.2),
		cframe = counterTopCFrame * CFrame.new(offsetX, 1.5, 0.3),
		material = Enum.Material.Wood,
		color = INCENSE_COLOR,
		canCollide = false,
		parent = kiosk,
	}) :: Part

	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "IncenseSmoke"
	smoke.Color = ColorSequence.new(Color3.fromRGB(220, 220, 220))
	smoke.Lifetime = NumberRange.new(2, 4)
	smoke.Rate = 3
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.8),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Speed = NumberRange.new(0.8)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.SpreadAngle = Vector2.new(15, 15)
	smoke.Parent = stick
end

local function buildFlowers(kiosk: Model, counterTopCFrame: CFrame, random: Random)
	for i, color in ipairs(FLOWER_COLORS) do
		local localX = random:NextNumber(-2.5, 2.5)
		local localZ = random:NextNumber(-0.7, 0.7)
		makePart({
			name = ("Flower%d"):format(i),
			size = Vector3.new(0.5, 0.5, 0.5),
			cframe = counterTopCFrame * CFrame.new(localX, 0.25, localZ),
			material = Enum.Material.Plastic,
			color = color,
			canCollide = false,
			shape = Enum.PartType.Ball,
			parent = kiosk,
		})
	end
end

local function buildOfferingBowl(kiosk: Model, counterTopCFrame: CFrame)
	local bowl = makePart({
		name = "OfferingBowl",
		size = Vector3.new(1.5, 0.5, 1.5),
		cframe = counterTopCFrame * CFrame.new(0, 0.25, 0),
		material = Enum.Material.Slate,
		color = BOWL_COLOR,
		canCollide = false,
		shape = Enum.PartType.Cylinder,
		parent = kiosk,
	}) :: Part
	bowl.CFrame = bowl.CFrame * CFrame.Angles(0, 0, math.rad(90))
end

local function buildSesajen(kiosk: Model, base: CFrame, random: Random)
	local counter = buildCounter(kiosk, base)
	local counterTopCFrame = counter.CFrame * CFrame.new(0, COUNTER_SIZE.Y / 2, 0)

	buildCandle(kiosk, counterTopCFrame, -2.5, 1)
	buildCandle(kiosk, counterTopCFrame, 2.5, 2)
	buildIncense(kiosk, counterTopCFrame, -1, 1)
	buildIncense(kiosk, counterTopCFrame, 0, 2)
	buildIncense(kiosk, counterTopCFrame, 1, 3)
	buildOfferingBowl(kiosk, counterTopCFrame)
	buildFlowers(kiosk, counterTopCFrame, random)
end

local function buildSignboard(kiosk: Model, base: CFrame, vendorName: string)
	local wares = VENDOR_WARES[vendorName] or ""
	local sign = makePart({
		name = "Signboard",
		size = SIGN_SIZE,
		cframe = base * CFrame.new(SIGN_OFFSET),
		material = Enum.Material.Wood,
		color = SIGN_COLOR,
		parent = kiosk,
	})

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.LightInfluence = 0
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = ("%s\n%s"):format(vendorName:upper(), wares)
	label.Font = Enum.Font.Garamond
	label.TextColor3 = SIGN_TEXT_COLOR
	label.TextScaled = true
	label.RichText = false
	label.Parent = surfaceGui
end

function KioskBuilder.build(
	npcPosition: Vector3,
	lookDirection: Vector3,
	vendorName: string,
	parent: Instance
): Model
	print(
		("[KioskBuilder] Building kiosk for %s at (%.0f, %.0f, %.0f)..."):format(
			vendorName,
			npcPosition.X,
			npcPosition.Y,
			npcPosition.Z
		)
	)

	local kiosk = Instance.new("Model")
	kiosk.Name = ("Kiosk_%s"):format(vendorName:gsub(" ", ""))

	-- Kiosk base CFrame at ground (NPC feet level), not HRP level. Shifts the
	-- whole kiosk down by FEET_TO_HRP_OFFSET so floor sits on terrain, poles
	-- stand from ground, roof clears NPC head, counter at waist height.
	local FEET_TO_HRP_OFFSET = 3
	local groundPos = npcPosition - Vector3.new(0, FEET_TO_HRP_OFFSET, 0)
	local base = CFrame.lookAt(groundPos, groundPos + lookDirection)
	local random = Random.new()

	buildFloor(kiosk, base)
	buildPolesWithCarving(kiosk, base)
	buildRoof(kiosk, base, random)
	for i, offset in ipairs(LAMPION_OFFSETS) do
		buildLampion(kiosk, base, offset, i)
	end
	buildSesajen(kiosk, base, random)
	buildSignboard(kiosk, base, vendorName)

	kiosk.Parent = parent
	print(
		("[KioskBuilder] Kiosk for %s complete (%d parts)."):format(
			vendorName,
			#kiosk:GetDescendants()
		)
	)
	return kiosk
end

return KioskBuilder
