--!strict
--[[
	@module      LightingSetup
	@description Apply ambience global default Pasar Gaib: malam jam 20.00,
	             warm-dim indoor ambient, ungu gelap outdoor ambient, sedikit fog
	             biar void edge gak keliatan tajam. Diapply server-side sekali
	             saat boot, replicate ke semua client. Per-map override (kuburan,
	             hutan, dst.) nyusul di Phase 3 Minggu 2+.
	@author      Claude Agent (primary coder)
]]

local Lighting = game:GetService("Lighting")

local LightingSetup = {}

local AMBIENT = Color3.fromRGB(80, 70, 60)
local OUTDOOR_AMBIENT = Color3.fromRGB(40, 30, 50)
local CLOCK_TIME = 20
local FOG_COLOR = Color3.fromRGB(30, 25, 35)
local FOG_START = 50
local FOG_END = 180

function LightingSetup.apply()
	Lighting.Ambient = AMBIENT
	Lighting.OutdoorAmbient = OUTDOOR_AMBIENT
	Lighting.ClockTime = CLOCK_TIME
	Lighting.FogColor = FOG_COLOR
	Lighting.FogStart = FOG_START
	Lighting.FogEnd = FOG_END
end

return LightingSetup
