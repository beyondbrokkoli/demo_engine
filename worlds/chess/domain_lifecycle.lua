-- worlds/chess/domain_lifecycle.lua
local ffi = require("ffi")
require("worlds.luachess.game.standard")

local Base = require("worlds.chess.domain_base")
local Terrain = require("worlds.chess.domain_terrain")

-- Maintain exact variable names internally
local loc_cache = Base._loc_cache
local pop_isometric_chunk = Terrain.pop_isometric_chunk

local function reset_to_standard(state, ext_state, app_ctx)
    local init_map = standard()
    local lua_grid_index = 1

    for y = 0, 7 do
        for x = 0, 7 do
            local current_loc = loc_cache[y + 1][x + 1]
            local piece = init_map[current_loc] or 0

            -- Overwrite the FFI struct
            state.chess.grid[lua_grid_index - 1] = piece

            -- Force update the 3D visual grid
            if piece == 0 then
                pop_isometric_chunk(ext_state, app_ctx, x + 1, y + 1, 0, 0)
            else
                pop_isometric_chunk(ext_state, app_ctx, x + 1, y + 1, 15, 15.0)
            end

            lua_grid_index = lua_grid_index + 1
        end
    end

    -- Reset metadata
    state.chess.flags = 0x80
    state.chess.en_passant = 255
    state.chess.halfmove = 0
    -- Zero out the C-array using LuaJIT's FFI memory fill
    ffi.fill(state.chess.history, ffi.sizeof(state.chess.history))

    print("[CHESS HARNESS] Board reset to standard starting position.")
end

local function Init(app_ctx, ext_state)
    reset_to_standard(app_ctx.rts_grid, ext_state, app_ctx)
end

local function Poll(app_ctx, cmd_slot)
    if app_ctx.pending_chess_cmd then
        cmd_slot.opcode = app_ctx.pending_chess_cmd.opcode
        cmd_slot.target_pos = app_ctx.pending_chess_cmd.target_pos
        app_ctx.pending_chess_cmd = nil
    else
        cmd_slot.opcode = 0
    end
end

return {
    reset_to_standard = reset_to_standard,
    Init = Init,
    Poll = Poll
}
