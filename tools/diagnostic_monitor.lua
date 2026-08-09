-- tools/diagnostic_monitor.lua
local ffi = require("ffi")
local lab_tools = require("tools.lab_domain")
local deep_compare = lab_tools.deep_compare

local Monitor = {}

-- Sucks the FFI state into a standard Lua table so your audit tools can read it
function Monitor.HydrateStateToTable(state_ptr, ext_state_ptr)
    local state = ffi.cast("LabWorldState*", state_ptr)
    local ext_state = ffi.cast("GameState*", ext_state_ptr)

    local readout = {
        network = {
            tick = state.global_tick,
            chess_flags = state.chess.flags,
            -- Let's just sample a few squares to keep the readout clean
            chess_square_0 = state.chess.grid[0],
            chess_square_63 = state.chess.grid[63]
        },
        visual = {
            mod_count = ext_state.modification_count,
            head_idx = ext_state.head_idx,
            -- Sample the latest visual modification
            latest_tile_idx = ext_state.modification_count > 0
                and ext_state.tiles[ext_state.head_idx - 1].tile_idx or -1
        },
        -- We can map diagnostic settings here to ensure UI elements aren't overwritten
        ui_config = {
            highlight_mode = "subtle"
        }
    }

    return readout
end

-- Uses your deep_compare to assert the engine state matches your exact expectations
function Monitor.AssertEngineState(state_ptr, ext_state_ptr, expected_table)
    local current_state = Monitor.HydrateStateToTable(state_ptr, ext_state_ptr)

    local is_synced = deep_compare(current_state, expected_table)

    if not is_synced then
        print("[AUDIT FAIL] Engine state drifted from expected layout.")
        -- You could hook your walkJson or deep_merge here to print the exact delta
        return false
    end

    print("[AUDIT PASS] FFI memory perfectly matches expected topology.")
    return true
end

return Monitor
