-- worlds/chess/domain.lua
-- The original module entry point. Stitches external API from domains.

local Base = require("worlds.chess.domain_base")
local Lifecycle = require("worlds.chess.domain_lifecycle")
local Contract = require("worlds.chess.domain_contract")

-- Attach functions to the Base table identically to how `router_plugin.lua` expects them
Base.Init = Lifecycle.Init
Base.Poll = Lifecycle.Poll
Base.ApplyContract = Contract.ApplyContract

return Base
