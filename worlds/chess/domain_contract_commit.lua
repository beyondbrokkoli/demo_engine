-- worlds/chess/domain_contract_commit.lua
local ffi = require("ffi")
local bit = require("bit")

local Base = require("worlds.chess.domain_base")
local Terrain = require("worlds.chess.domain_terrain")
local Lifecycle = require("worlds.chess.domain_lifecycle")

local loc_cache = Base._loc_cache
local pop_isometric_chunk = Terrain.pop_isometric_chunk
local reset_to_standard = Lifecycle.reset_to_standard

local function CommitPhase(state, ext_state, app_ctx, temp_map, new_T, is_white_turn, from_idx, to_idx)
    -- 5. STRICT STATE DIFFING (Reconciliation)
    local lua_grid_index = 1
    for y = 1, 8 do
        for x = 1, 8 do
            local loc = loc_cache[y][x]
            local old_piece = temp_map[loc] or 0
            local new_piece = new_T.pos[loc] or 0

            if old_piece ~= new_piece then
                state.chess.grid[lua_grid_index - 1] = new_piece

                if new_piece == 0 then
                    pop_isometric_chunk(ext_state, app_ctx, x, y, 0, 0)
                else
                    pop_isometric_chunk(ext_state, app_ctx, x, y, 15, 15)
                end
            end
            lua_grid_index = lua_grid_index + 1
        end
    end

    -- 6. ENCODE LUA STATE BACK TO FFI
    local out_flags = is_white_turn and 0x00 or 0x80

    if new_T.freshmap[loc_cache[1][5]] then
        if new_T.freshmap[loc_cache[1][8]] then out_flags = bit.bor(out_flags, 0x08) end
        if new_T.freshmap[loc_cache[1][1]] then out_flags = bit.bor(out_flags, 0x04) end
    end
    if new_T.freshmap[loc_cache[8][5]] then
        if new_T.freshmap[loc_cache[8][8]] then out_flags = bit.bor(out_flags, 0x02) end
        if new_T.freshmap[loc_cache[8][1]] then out_flags = bit.bor(out_flags, 0x01) end
    end
    state.chess.flags = out_flags

    -- Re-calculate coordinates for the En Passant check logic
    local f_x, f_y = (from_idx % 8) + 1, math.floor(from_idx / 8) + 1
    local t_x, t_y = (to_idx % 8) + 1, math.floor(to_idx / 8) + 1

    local next_ep = 255
    local moved_pc = temp_map[loc_cache[f_y][f_x]]

    if math.abs(moved_pc) == 1 and math.abs(f_y - t_y) == 2 then
        local ep_y = t_y - moved_pc
        next_ep = (ep_y - 1) * 8 + (t_x - 1)
    end
    state.chess.en_passant = next_ep

    -- 7. TERMINAL STATE HARNESS
    state.chess.halfmove = new_T.drawCount

    local is_terminal = false
    local terminal_reason = ""

    if new_T.checkmate then
        is_terminal = true
        terminal_reason = "Checkmate"
    elseif new_T.stalemate then
        is_terminal = true
        terminal_reason = "Stalemate"
    elseif state.chess.halfmove >= 100 then
        is_terminal = true
        terminal_reason = "50-Move Rule"
    else
        local hash_val = ffi.new("uint32_t", 5381)
        for i = 0, 63 do
            hash_val = hash_val * 33 + ffi.cast("uint8_t", state.chess.grid[i])
        end
        hash_val = hash_val * 33 + state.chess.flags
        hash_val = hash_val * 33 + state.chess.en_passant

        local ply = state.chess.halfmove
        state.chess.history[ply] = hash_val

        local repetitions = 0
        for i = 0, ply do
            if state.chess.history[i] == hash_val then
                repetitions = repetitions + 1
            end
        end

        if repetitions >= 3 then
            is_terminal = true
            terminal_reason = "Threefold Repetition"
        end
    end

    if is_terminal then
        print(string.format("[CHESS MATCH END] Trigger: %s. Resetting board...", terminal_reason))
        reset_to_standard(state, ext_state, app_ctx)
    end
end

return CommitPhase
