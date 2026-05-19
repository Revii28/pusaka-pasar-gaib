--!strict
--[[
	@module      AtmosphereSetup
	@description Visual environment toggle. Dispatcher AtmosphereSetup.apply()
	             baca Constants.LIGHTING_PRESET dan routing ke:
	               "DEBUG_BRIGHT" — siang bolong, no post-processing, no fog —
	                               buat verify composition (semua keliatan).
	               "MYSTIC_NIGHT" — malam jam 20 dengan Bloom/CC/DOF/Atmosphere
	                               + fog + tint ungu-pink + particles full.
	             Ambient particles juga toned-down di DEBUG mode (mist OFF,
	             fireflies rate 2).
	@author      Claude Agent (primary coder)
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local AtmosphereSetup = {}

local PRESET_DEBUG = "DEBUG_BRIGHT"
local PRESET_MYSTIC = "MYSTIC_NIGHT"

local BLOOM_NAME = "PusakaBloom"
local CC_NAME = "PusakaColorCorrection"
local DOF_NAME = "PusakaDOF"
local ATMOSPHERE_NAME = "PusakaAtmosphere"

local PARTICLE_ANCHOR_NAME = "AmbientParticleAnchor"
local PARTICLE_ANCHOR_SIZE = Vector3.new(400, 1, 400)
local PARTICLE_ANCHOR_POSITION = Vector3.new(0, 2, 0)

local DEBUG_AMBIENT = Color3.fromRGB(150, 150, 150)
local DEBUG_OUTDOOR_AMBIENT = Color3.fromRGB(180, 180, 200)

local MYSTIC_AMBIENT = Color3.fromRGB(80, 70, 60)
local MYSTIC_OUTDOOR_AMBIENT = Color3.fromRGB(40, 30, 50)
local MYSTIC_FOG_COLOR = Color3.fromRGB(30, 25, 35)

local MYSTIC_BLOOM_INTENSITY = 1.0
local MYSTIC_BLOOM_SIZE = 24
local MYSTIC_BLOOM_THRESHOLD = 0.9

local MYSTIC_CC_SATURATION = 0.15
local MYSTIC_CC_CONTRAST = 0.1
local MYSTIC_CC_TINT = Color3.fromRGB(200, 180, 230)

local MYSTIC_DOF_FOCUS_DISTANCE = 40
local MYSTIC_DOF_IN_FOCUS_RADIUS = 35
local MYSTIC_DOF_FAR_INTENSITY = 0.4

local MYSTIC_ATMOSPHERE_DENSITY = 0.35
local MYSTIC_ATMOSPHERE_OFFSET = 0.25
local MYSTIC_ATMOSPHERE_COLOR = Color3.fromRGB(80, 60, 120)
local MYSTIC_ATMOSPHERE_DECAY = Color3.fromRGB(200, 80, 150)
local MYSTIC_ATMOSPHERE_GLARE = 1

local function ensureEffect(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local fresh = Instance.new(className)
	fresh.Name = name
	fresh.Parent = Lighting
	return fresh
end

local function disableEffectIfExists(name: string)
	local existing = Lighting:FindFirstChild(name)
	if not existing then
		return
	end
	if existing:IsA("PostEffect") then
		existing.Enabled = false
	elseif existing.ClassName == "Atmosphere" then
		local atm = existing :: Atmosphere
		atm.Density = 0
		atm.Glare = 0
	end
end

function AtmosphereSetup.applyDebugBright()
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.Ambient = DEBUG_AMBIENT
	Lighting.OutdoorAmbient = DEBUG_OUTDOOR_AMBIENT
	Lighting.FogStart = 0
	Lighting.FogEnd = 100000

	disableEffectIfExists(BLOOM_NAME)
	disableEffectIfExists(CC_NAME)
	disableEffectIfExists(DOF_NAME)
	disableEffectIfExists(ATMOSPHERE_NAME)

	print("[Atmosphere] DEBUG_BRIGHT preset applied — semua keliatan jelas.")
end

function AtmosphereSetup.applyMysticNight()
	Lighting.ClockTime = 20
	Lighting.Brightness = 0.5
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.6
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.Ambient = MYSTIC_AMBIENT
	Lighting.OutdoorAmbient = MYSTIC_OUTDOOR_AMBIENT
	Lighting.FogColor = MYSTIC_FOG_COLOR
	Lighting.FogStart = 50
	Lighting.FogEnd = 180

	local bloom = ensureEffect("BloomEffect", BLOOM_NAME) :: BloomEffect
	bloom.Intensity = MYSTIC_BLOOM_INTENSITY
	bloom.Size = MYSTIC_BLOOM_SIZE
	bloom.Threshold = MYSTIC_BLOOM_THRESHOLD
	bloom.Enabled = true

	local cc = ensureEffect("ColorCorrectionEffect", CC_NAME) :: ColorCorrectionEffect
	cc.Saturation = MYSTIC_CC_SATURATION
	cc.Contrast = MYSTIC_CC_CONTRAST
	cc.TintColor = MYSTIC_CC_TINT
	cc.Enabled = true

	local dof = ensureEffect("DepthOfFieldEffect", DOF_NAME) :: DepthOfFieldEffect
	dof.FocusDistance = MYSTIC_DOF_FOCUS_DISTANCE
	dof.InFocusRadius = MYSTIC_DOF_IN_FOCUS_RADIUS
	dof.FarIntensity = MYSTIC_DOF_FAR_INTENSITY
	dof.Enabled = true

	local atm = ensureEffect("Atmosphere", ATMOSPHERE_NAME) :: Atmosphere
	atm.Density = MYSTIC_ATMOSPHERE_DENSITY
	atm.Offset = MYSTIC_ATMOSPHERE_OFFSET
	atm.Color = MYSTIC_ATMOSPHERE_COLOR
	atm.Decay = MYSTIC_ATMOSPHERE_DECAY
	atm.Glare = MYSTIC_ATMOSPHERE_GLARE

	print("[Atmosphere] MYSTIC_NIGHT preset applied.")
end

function AtmosphereSetup.apply()
	local preset = Constants.LIGHTING_PRESET
	if preset == PRESET_DEBUG then
		AtmosphereSetup.applyDebugBright()
	elseif preset == PRESET_MYSTIC then
		AtmosphereSetup.applyMysticNight()
	else
		warn(
			("[Atmosphere] Unknown LIGHTING_PRESET: %s — falling back to DEBUG_BRIGHT"):format(
				tostring(preset)
			)
		)
		AtmosphereSetup.applyDebugBright()
	end
end

local function makeGroundMist(parent: Instance): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "GroundMist"
	emitter.Color = ColorSequence.new(Color3.fromRGB(180, 160, 200))
	emitter.Lifetime = NumberRange.new(5, 8)
	emitter.Rate = 30
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(1, 6),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.85),
		NumberSequenceKeypoint.new(0.8, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Speed = NumberRange.new(0.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = parent
	return emitter
end

local function makeFireflies(parent: Instance): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SpiritFireflies"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 220)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 100)),
	})
	emitter.Lifetime = NumberRange.new(4, 6)
	emitter.Rate = 8
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	emitter.Transparency = NumberSequence.new(0.3)
	emitter.Speed = NumberRange.new(1)
	emitter.LightEmission = 1
	emitter.Rotation = NumberRange.new(-180, 180)
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = parent
	return emitter
end

local function makeFallingPetals(parent: Instance): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "FallingPetals"
	emitter.Color = ColorSequence.new(Color3.fromRGB(220, 180, 200))
	emitter.Lifetime = NumberRange.new(8)
	emitter.Rate = 3
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0.5),
	})
	emitter.Transparency = NumberSequence.new(0.4)
	emitter.Speed = NumberRange.new(0.5)
	emitter.Acceleration = Vector3.new(0, -0.5, 0)
	emitter.Rotation = NumberRange.new(-180, 180)
	emitter.RotSpeed = NumberRange.new(-30, 30)
	emitter.SpreadAngle = Vector2.new(40, 40)
	emitter.Parent = parent
	return emitter
end

function AtmosphereSetup.spawnAmbientParticles(): BasePart
	local existing = workspace:FindFirstChild(PARTICLE_ANCHOR_NAME)
	if existing then
		existing:Destroy()
	end

	local anchor = Instance.new("Part")
	anchor.Name = PARTICLE_ANCHOR_NAME
	anchor.Size = PARTICLE_ANCHOR_SIZE
	anchor.Position = PARTICLE_ANCHOR_POSITION
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = workspace

	local mist = makeGroundMist(anchor)
	local fireflies = makeFireflies(anchor)
	makeFallingPetals(anchor)

	if Constants.LIGHTING_PRESET == PRESET_DEBUG then
		mist.Enabled = false
		fireflies.Rate = 2
	end

	return anchor
end

return AtmosphereSetup
