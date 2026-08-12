-- worlds/luachess/game/logic.lua
-- The original module entry point. Stitches external API from domains.

local Base = require("worlds.luachess.game.logic_base")
local Core = require("worlds.luachess.game.logic_core")
local Gen = require("worlds.luachess.game.logic_gen")

-- Attach functions to the Base table just in case modern scripts require this module.
Base.findKing = Core.findKing
Base.opponents = Core.opponents
Base.possible = Gen.possible
Base.inCheck = Gen.inCheck

-- [CRITICAL RETRO-COMPATIBILITY]
-- The original script defined these 4 specific functions globally (without `local`).
-- To ensure external scripts continue working without catching the return object,
-- we map them identically onto Lua's global environment.
_G.findKing = Core.findKing
_G.opponents = Core.opponents
_G.possible = Gen.possible
_G.inCheck = Gen.inCheck

return Base
