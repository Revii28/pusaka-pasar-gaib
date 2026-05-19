--!strict
--[[
	@module      Constants
	@description Game-wide constants. Single source of truth untuk nilai yang dipakai
	             lintas client/server (game name, version, debug flags, dst.).
	             Tweak balance? Tweak di sini, BUKAN di-hardcode di kode lain.
	@author      Claude Agent (primary coder)
]]

local Constants = {}

Constants.GAME_NAME = "PUSAKA: Pasar Gaib"
Constants.VERSION = "0.0.1-alpha"
Constants.DEBUG_MODE = true

-- Lighting preset toggle. Valid: "DEBUG_BRIGHT" | "MYSTIC_NIGHT".
-- DEBUG_BRIGHT = siang bolong, no post-processing, no mist — verify composition.
-- MYSTIC_NIGHT = malam jam 20 dengan Bloom/CC/DOF/Atmosphere + fog + particles.
-- Default DEBUG_BRIGHT sampai user verify semua prop keliatan, lalu ganti.
Constants.LIGHTING_PRESET = "DEBUG_BRIGHT"

table.freeze(Constants)
return Constants
