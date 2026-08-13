-- worlds/chess/domain_contract_logic.lua
local DecodePhase = require("worlds.chess.domain_contract_decode")
local SimPhase    = require("worlds.chess.domain_contract_simulate")
local CommitPhase = require("worlds.chess.domain_contract_commit")

local Logic = {}

local function ApplyContract(state, ext_state, cmd, player_id, app_ctx)
    -- 1. DECODE: Parse commands and inflate the FFI state to Lua structures
    local has_cmd, from_idx, to_idx, temp_map, freshmap, current_turn, eptoken, is_white_turn = DecodePhase(state, cmd)

    -- If no command this tick, exit to save CPU cycles
    if not has_cmd then return end

    -- 2. SIMULATE: Run luachess logic in a sandbox for this tick
    local new_T = SimPhase(from_idx, to_idx, temp_map, freshmap, current_turn, eptoken, state.chess.halfmove)

    -- 3. COMMIT: Diff the state, encode metadata back to FFI, and check game over
    if new_T then
        CommitPhase(state, ext_state, app_ctx, temp_map, new_T, is_white_turn, from_idx, to_idx)
    end
end

Logic.ApplyContract = ApplyContract

return Logic
