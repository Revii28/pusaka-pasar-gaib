--!strict
--[[
	@module      AtmosphereSetup
	@description Single source of truth untuk visual environment: Lighting basic
	             (Ambient/OutdoorAmbient/ClockTime/Fog), Lighting tune
	             (Brightness/ShadowSoftness/Env scales), post-processing effects
	             (Bloom/ColorCorrection/DepthOfField/Atmosphere), plus ambient
	             particles workspace-level (GroundMist + SpiritFireflies +
	             FallingPetals). Replaces previous LightingSetup module.
	@author      Claude Agent (primary coder)
]]

local Lighting = game:GetService("Lighting")

local AtmosphereSetup = {}

local AMBIENT = Color3.fromRGB(80, 70, 60)
local OUTDOOR_AMBIENT = Color3.fromRGB(40, 30, 50)
local CLOCK_TIME = 20
local FOG_COLOR = Color3.fromRGB(30, 25, 35)
local FOG_START = 50
local FOG_END = 180

local BRIGHTNESS = 0.5
local SHADOW_SOFTNESS = 0.6
local ENV_DIFFUSE_SCALE = 0.4
local ENV_SPECULAR_SCALE = 0.4

local BLOOM_INTENSITY = 1.5
local BLOOM_SIZE = 24
local BLOOM_THRESHOLD = 0.8

local CC_SATURATION = 0.15
local CC_CONTRAST = 0.1
local CC_TINT = Color3.fromRGB(200, 180, 230)

local DOF_FOCUS_DISTANCE = 30
local DOF_IN_FOCUS_RADIUS = 15
local DOF_FAR_INTENSITY = 0.6

local ATMOSPHERE_DENSITY = 0.35
local ATMOSPHERE_OFFSET = 0.25
local ATMOSPHERE_COLOR = Color3.fromRGB(80, 60, 120)
local ATMOSPHERE_DECAY = Color3.fromRGB(200, 80, 150)
local ATMOSPHERE_GLARE = 1

local PARTICLE_ANCHOR_NAME = "AmbientParticleAnchor"
local PARTICLE_ANCHOR_SIZE = Vector3.new(400, 1, 400)
local PARTICLE_ANCHOR_POSITION = Vector3.new(0, 2, 0)

local function setupLighting()
	Lighting.Ambient = AMBIENT
	Lighting.OutdoorAmbient = OUTDOOR_AMBIENT
	Lighting.ClockTime = CLOCK_TIME
	Lighting.FogColor = FOG_COLOR
	Lighting.FogStart = FOG_START
	Lighting.FogEnd = FOG_END
	Lighting.Brightness = BRIGHTNESS
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = SHADOW_SOFTNESS
	Lighting.EnvironmentDiffuseScale = ENV_DIFFUSE_SCALE
	Lighting.EnvironmentSpecularScale = ENV_SPECULAR_SCALE
end

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

local function setupBloom()
	local bloom = ensureEffect("BloomEffect", "PusakaBloom") :: BloomEffect
	bloom.Intensity = BLOOM_INTENSITY
	bloom.Size = BLOOM_SIZE
	bloom.Threshold = BLOOM_THRESHOLD
end

local function setupColorCorrection()
	local cc =
		ensureEffect("ColorCorrectionEffect", "PusakaColorCorrection") :: ColorCorrectionEffect
	cc.Saturation = CC_SATURATION
	cc.Contrast = CC_CONTRAST
	cc.TintColor = CC_TINT
end

local function setupDepthOfField()
	local dof = ensureEffect("DepthOfFieldEffect", "PusakaDOF") :: DepthOfFieldEffect
	dof.FocusDistance = DOF_FOCUS_DISTANCE
	dof.InFocusRadius = DOF_IN_FOCUS_RADIUS
	dof.FarIntensity = DOF_FAR_INTENSITY
end

local function setupAtmosphereEffect()
	local atm = ensureEffect("Atmosphere", "PusakaAtmosphere") :: Atmosphere
	atm.Density = ATMOSPHERE_DENSITY
	atm.Offset = ATMOSPHERE_OFFSET
	atm.Color = ATMOSPHERE_COLOR
	atm.Decay = ATMOSPHERE_DECAY
	atm.Glare = ATMOSPHERE_GLARE
end

function AtmosphereSetup.apply()
	setupLighting()
	setupBloom()
	setupColorCorrection()
	setupDepthOfField()
	setupAtmosphereEffect()
end

local function makeGroundMist(parent: Instance)
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
end

local function makeFireflies(parent: Instance)
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
end

local function makeFallingPetals(parent: Instance)
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

	makeGroundMist(anchor)
	makeFireflies(anchor)
	makeFallingPetals(anchor)
	return anchor
end

return AtmosphereSetup
