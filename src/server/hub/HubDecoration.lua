--!strict
--[[
	@module      HubDecoration
	@description Hub plaza polish layer — dipanggil setelah core HubBuilder
	             build selesai. Add: 32 stone path tile (4×0.5×4 Slate, 8 per
	             direction NE/NW/SE/SW dari center ke 4 vendor), 4 signage
	             WoodPlanks dengan BillboardGui label themed (Mbah Karto 🌿,
	             Nyi Sumiyem 🍡, Pak Tarjo 🪦, Bu Ratmi 🕯), 24 lampion Neon
	             alternating orange/red/yellow dengan PointLight warm, center
	             altar Marble 6×1×6 + Neon ungu top + 4 fire particle candle,
	             ambient props (8 barrel Wood, 12 bunga kemboja Neon white,
	             4 tikar Fabric red), atmosphere preset PASAR_GAIB_NIGHT
	             (Ambient ungu redup, FogColor ungu, FogEnd=250, ClockTime=20).
	             NOTE: Atmosphere setting di-apply override AtmosphereSetup —
	             HubDecoration runs LAST jadi night vibe konsisten.
	@author      Claude Agent (primary coder)
]]

local Lighting = game:GetService("Lighting")

local HubDecoration = {}

-- Vendor positions (mirror NPCSpawner VENDORS list — kalau NPCSpawner positions
-- berubah, sync di sini juga). Path + signage anchor di sini.
local VENDOR_ANCHORS: { { name: string, label: string, position: Vector3 } } = {
	{
		name = "MbokInem",
		label = "🌿 MBAH KARTO — Ramuan",
		position = Vector3.new(38, 0, -42),
	},
	{
		name = "PakTukijo",
		label = "🍡 NYI SUMIYEM — Sesajen",
		position = Vector3.new(-52, 0, -22),
	},
	{
		name = "NyaiSumi",
		label = "🪦 PAK TARJO — Pusaka",
		position = Vector3.new(45, 0, 35),
	},
	{
		name = "BandarRobux",
		label = "🕯 BU RATMI — Lilin & Mantra",
		position = Vector3.new(-30, 0, 48),
	},
}

local HUB_CENTER = Vector3.new(0, 0, 0)
local PATH_TILE_COUNT_PER_LINE = 8
local PATH_TILE_SIZE = Vector3.new(4, 0.5, 4)
local PATH_TILE_Y = 0.25
local PATH_TILE_COLOR = Color3.fromRGB(140, 120, 100)

local SIGNAGE_SIZE = Vector3.new(4, 2, 0.3)
local SIGNAGE_COLOR = Color3.fromRGB(80, 50, 30)
local SIGNAGE_TEXT_COLOR = Color3.fromRGB(230, 200, 120)
local SIGNAGE_HEIGHT = 4
local SIGNAGE_FORWARD_OFFSET = 8

local LAMPION_PER_QUADRANT = 6
local LAMPION_STRING_SIZE = Vector3.new(0.15, 3, 0.15)
local LAMPION_BULB_SIZE = Vector3.new(0.8, 0.8, 0.8)
local LAMPION_Y = 5
local LAMPION_COLORS: { Color3 } = {
	Color3.fromRGB(255, 130, 50),
	Color3.fromRGB(220, 70, 70),
	Color3.fromRGB(255, 200, 80),
}

local ALTAR_BASE_SIZE = Vector3.new(6, 1, 6)
local ALTAR_BASE_COLOR = Color3.fromRGB(180, 170, 160)
local ALTAR_MID_SIZE = Vector3.new(4, 0.5, 4)
local ALTAR_MID_COLOR = Color3.fromRGB(140, 130, 145)
local ALTAR_TOP_SIZE = Vector3.new(1.5, 1.5, 1.5)
local ALTAR_TOP_COLOR = Color3.fromRGB(180, 90, 230)

local BARREL_COUNT = 8
local BARREL_SIZE = Vector3.new(2, 3, 2)
local BARREL_COLOR = Color3.fromRGB(80, 55, 30)

local KEMBOJA_COUNT = 12
local KEMBOJA_FLOWER_SIZE = Vector3.new(0.4, 0.4, 0.4)
local KEMBOJA_STEM_SIZE = Vector3.new(0.1, 0.8, 0.1)

local TIKAR_SIZE = Vector3.new(6, 0.2, 4)
local TIKAR_COLOR = Color3.fromRGB(140, 30, 30)
local TIKAR_FORWARD_OFFSET = 4

local NIGHT_AMBIENT = Color3.fromRGB(60, 50, 75)
local NIGHT_OUTDOOR_AMBIENT = Color3.fromRGB(40, 30, 50)
local NIGHT_FOG_COLOR = Color3.fromRGB(20, 15, 30)
local NIGHT_FOG_END = 250
local NIGHT_CLOCK_TIME = 20

local function makePart(props: {
	name: string,
	size: Vector3,
	cframe: CFrame?,
	position: Vector3?,
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
	if props.cframe then
		part.CFrame = props.cframe
	elseif props.position then
		part.Position = props.position
	end
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

local function buildPathToVendor(parent: Instance, vendor: { name: string, position: Vector3 })
	local direction = (vendor.position - HUB_CENTER)
	for i = 1, PATH_TILE_COUNT_PER_LINE do
		local t = i / (PATH_TILE_COUNT_PER_LINE + 1)
		local tilePos = HUB_CENTER + direction * t
		makePart({
			name = ("Path_%s_%d"):format(vendor.name, i),
			size = PATH_TILE_SIZE,
			position = Vector3.new(tilePos.X, PATH_TILE_Y, tilePos.Z),
			material = Enum.Material.Slate,
			color = PATH_TILE_COLOR,
			parent = parent,
		})
	end
end

local function buildSignage(
	parent: Instance,
	vendor: { name: string, label: string, position: Vector3 }
)
	-- Sign 8 stud "in front" of vendor toward hub center (south face menghadap
	-- player approaching dari spawn).
	local toCenter = (HUB_CENTER - vendor.position)
	if toCenter.Magnitude < 0.01 then
		return
	end
	local forward = toCenter.Unit
	local signXZ = vendor.position + forward * SIGNAGE_FORWARD_OFFSET
	local signPos = Vector3.new(signXZ.X, SIGNAGE_HEIGHT, signXZ.Z)

	local sign = makePart({
		name = ("Signage_%s"):format(vendor.name),
		size = SIGNAGE_SIZE,
		cframe = CFrame.lookAt(signPos, signPos + forward),
		material = Enum.Material.WoodPlanks,
		color = SIGNAGE_COLOR,
		canCollide = false,
		parent = parent,
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SignBillboard"
	billboard.Size = UDim2.fromOffset(240, 60)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 200
	billboard.Parent = sign

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = vendor.label
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextScaled = true
	label.TextColor3 = SIGNAGE_TEXT_COLOR
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard
end

local function buildLampionAt(parent: Instance, position: Vector3, color: Color3, index: number)
	local stringPart = makePart({
		name = ("LampionString_%d"):format(index),
		size = LAMPION_STRING_SIZE,
		position = position + Vector3.new(0, LAMPION_STRING_SIZE.Y / 2, 0),
		material = Enum.Material.Fabric,
		color = Color3.fromRGB(30, 25, 20),
		canCollide = false,
		parent = parent,
	})

	local bulb = makePart({
		name = ("LampionBulb_%d"):format(index),
		size = LAMPION_BULB_SIZE,
		position = position + Vector3.new(0, 0, 0),
		material = Enum.Material.Neon,
		color = color,
		transparency = 0.15,
		shape = Enum.PartType.Ball,
		canCollide = false,
		parent = parent,
	})

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 10
	light.Brightness = 1.5
	light.Parent = bulb

	-- Reference string in unused-local guard via parent assignment
	stringPart.CanCollide = false
end

local function buildLampionArray(parent: Instance)
	local random = Random.new(7777)
	local index = 0
	for _, vendor in ipairs(VENDOR_ANCHORS) do
		local toVendor = vendor.position - HUB_CENTER
		local lateral = Vector3.new(-toVendor.Z, 0, toVendor.X).Unit
		for i = 1, LAMPION_PER_QUADRANT do
			local t = (i / (LAMPION_PER_QUADRANT + 1))
			local sideOffset = (if i % 2 == 0 then 1 else -1) * (3 + random:NextNumber(0, 1))
			local pos = HUB_CENTER + toVendor * t + lateral * sideOffset
			local color = LAMPION_COLORS[(index % #LAMPION_COLORS) + 1]
			buildLampionAt(parent, Vector3.new(pos.X, LAMPION_Y, pos.Z), color, index)
			index += 1
		end
	end
end

local function buildAltar(parent: Instance)
	local altar = Instance.new("Model")
	altar.Name = "CenterAltar"
	altar.Parent = parent

	local base = makePart({
		name = "AltarBase",
		size = ALTAR_BASE_SIZE,
		cframe = CFrame.new(HUB_CENTER + Vector3.new(0, ALTAR_BASE_SIZE.Y / 2, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
		shape = Enum.PartType.Cylinder,
		material = Enum.Material.Sandstone,
		color = ALTAR_BASE_COLOR,
		parent = altar,
	})

	local mid = makePart({
		name = "AltarMid",
		size = ALTAR_MID_SIZE,
		cframe = CFrame.new(
			base.Position + Vector3.new(0, ALTAR_BASE_SIZE.Y / 2 + ALTAR_MID_SIZE.Y / 2, 0)
		) * CFrame.Angles(0, 0, math.rad(90)),
		shape = Enum.PartType.Cylinder,
		material = Enum.Material.Marble,
		color = ALTAR_MID_COLOR,
		parent = altar,
	})

	local top = makePart({
		name = "AltarSpiritOrb",
		size = ALTAR_TOP_SIZE,
		position = mid.Position + Vector3.new(0, ALTAR_MID_SIZE.Y / 2 + ALTAR_TOP_SIZE.Y / 2, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Neon,
		color = ALTAR_TOP_COLOR,
		transparency = 0.15,
		canCollide = false,
		parent = altar,
	})

	local orbLight = Instance.new("PointLight")
	orbLight.Color = ALTAR_TOP_COLOR
	orbLight.Range = 18
	orbLight.Brightness = 4
	orbLight.Parent = top

	-- 4 candle corner around altar base
	for i, sideAngle in ipairs({ 45, 135, 225, 315 }) do
		local angle = math.rad(sideAngle)
		local candlePos = HUB_CENTER + Vector3.new(math.cos(angle) * 3.5, 1, math.sin(angle) * 3.5)
		local candle = makePart({
			name = ("AltarCandle%d"):format(i),
			size = Vector3.new(0.5, 2, 0.5),
			position = candlePos,
			shape = Enum.PartType.Cylinder,
			material = Enum.Material.Neon,
			color = Color3.fromRGB(255, 180, 100),
			canCollide = false,
			parent = altar,
		})
		candle.CFrame = candle.CFrame * CFrame.Angles(0, 0, math.rad(90))

		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(255, 200, 100)
		fire.SecondaryColor = Color3.fromRGB(180, 80, 30)
		fire.Size = 2
		fire.Heat = 6
		fire.Parent = candle

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 180, 100)
		light.Range = 6
		light.Brightness = 2
		light.Parent = candle
	end
end

local function buildBarrels(parent: Instance)
	local random = Random.new(8888)
	for i = 1, BARREL_COUNT do
		local angle = (i / BARREL_COUNT) * 2 * math.pi
		local r = 30 + random:NextNumber(-4, 4)
		local pos = HUB_CENTER
			+ Vector3.new(math.cos(angle) * r, BARREL_SIZE.Y / 2, math.sin(angle) * r)
		local barrel = makePart({
			name = ("Barrel%d"):format(i),
			size = BARREL_SIZE,
			position = pos,
			shape = Enum.PartType.Cylinder,
			material = Enum.Material.Wood,
			color = BARREL_COLOR,
			parent = parent,
		})
		barrel.CFrame = barrel.CFrame * CFrame.Angles(0, 0, math.rad(90))
	end
end

local function buildKemboja(parent: Instance)
	local random = Random.new(9999)
	for i = 1, KEMBOJA_COUNT do
		local angle = random:NextNumber() * 2 * math.pi
		local r = random:NextNumber(15, 70)
		local pos = HUB_CENTER + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)

		local stem = makePart({
			name = ("KembojaStem%d"):format(i),
			size = KEMBOJA_STEM_SIZE,
			position = pos + Vector3.new(0, KEMBOJA_STEM_SIZE.Y / 2, 0),
			material = Enum.Material.Grass,
			color = Color3.fromRGB(50, 100, 50),
			canCollide = false,
			parent = parent,
		})
		stem.CanCollide = false

		local flower = makePart({
			name = ("KembojaFlower%d"):format(i),
			size = KEMBOJA_FLOWER_SIZE,
			position = pos + Vector3.new(0, KEMBOJA_STEM_SIZE.Y + 0.2, 0),
			shape = Enum.PartType.Ball,
			material = Enum.Material.Neon,
			color = Color3.fromRGB(250, 245, 230),
			transparency = 0.2,
			canCollide = false,
			parent = parent,
		})

		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 230, 200)
		glow.Range = 4
		glow.Brightness = 0.6
		glow.Parent = flower
	end
end

local function buildTikar(parent: Instance)
	for _, vendor in ipairs(VENDOR_ANCHORS) do
		local toCenter = (HUB_CENTER - vendor.position)
		if toCenter.Magnitude < 0.01 then
			continue
		end
		local forward = toCenter.Unit
		local tikarXZ = vendor.position + forward * TIKAR_FORWARD_OFFSET
		makePart({
			name = ("Tikar_%s"):format(vendor.name),
			size = TIKAR_SIZE,
			cframe = CFrame.lookAt(
				Vector3.new(tikarXZ.X, TIKAR_SIZE.Y / 2, tikarXZ.Z),
				Vector3.new(tikarXZ.X, TIKAR_SIZE.Y / 2, tikarXZ.Z) + forward
			),
			material = Enum.Material.Fabric,
			color = TIKAR_COLOR,
			parent = parent,
		})
	end
end

local function applyNightAtmosphere()
	-- NOTE: Override AtmosphereSetup preset. Kalau LIGHTING_PRESET = DEBUG_BRIGHT,
	-- ini override jadi night vibe regardless. User toggle back via Constants
	-- atau comment out function call kalau gak mau override.
	Lighting.Ambient = NIGHT_AMBIENT
	Lighting.OutdoorAmbient = NIGHT_OUTDOOR_AMBIENT
	Lighting.FogColor = NIGHT_FOG_COLOR
	Lighting.FogStart = 30
	Lighting.FogEnd = NIGHT_FOG_END
	Lighting.ClockTime = NIGHT_CLOCK_TIME
	Lighting.Brightness = 1.2
end

function HubDecoration.build(parent: Instance?)
	local target = parent or workspace
	local decoModel = Instance.new("Model")
	decoModel.Name = "HubDecoration"
	decoModel.Parent = target

	for _, vendor in ipairs(VENDOR_ANCHORS) do
		buildPathToVendor(decoModel, { name = vendor.name, position = vendor.position })
		buildSignage(decoModel, vendor)
	end
	buildLampionArray(decoModel)
	buildAltar(decoModel)
	buildBarrels(decoModel)
	buildKemboja(decoModel)
	buildTikar(decoModel)
	applyNightAtmosphere()

	print(
		("[HubDecoration] Plaza decoration built (descendants=%d)."):format(
			#decoModel:GetDescendants()
		)
	)
	return decoModel
end

return HubDecoration
