-- worlds/chess/domain_contract.lua

-- 1. Load the Base layout (Memory shared state)
local Hub = require("worlds.chess.domain_contract_base")

-- 2. Load the specific logical spokes/workers
local logic = require("worlds.chess.domain_contract_logic")

-- 3. Map the external API precisely to the original footprint
Hub.ApplyContract = logic.ApplyContract

-- 4. Return the fully formed module. The external code expects a table holding ApplyContract.
return Hub
