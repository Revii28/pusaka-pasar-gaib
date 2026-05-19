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

table.freeze(Constants)
return Constants
