-- worlds/chess/domain.lua
local ffi = require("ffi")
local bit = require("bit")
local lab_tools = require("tools.lab_domain")
local Fixed = require("runtime.services.math.fixed_math")
require("game.turn")
require("game.standard")
require("global")

local ChessDomain = {}
local loc_cache = {}
for y = 1, 8 do
    loc_cache[y] = {}
    for x = 1, 8 do loc_cache[y][x] = loc:new(x, y) end
end

-- [NEW] Define how many physical tiles represent one chess square.
-- 1 = 8x8 visual board (64 modifications at Init)
-- 2 = 16x16 visual board (256 modifications at Init)
-- 3 = 24x24 visual board (576 modifications at Init)
-- 4 = 32x32 visual board (1024 modifications at Init)
local CHUNK_SCALE = 3

-- [UPDATED] Helper to elevate BIG chunks of the board squared-wise
local function pop_isometric_chunk(ext_state, app_ctx, chess_x, chess_y, terrain_id, custom_elev)
    local w = app_ctx.cfg_sim.world.map_width
    local h = app_ctx.cfg_sim.world.map_height
    local cx = math.floor(w / 2)
    local cz = math.floor(h / 2)

    -- 1. Calculate the full size of the visual board to keep it perfectly centered
    local visual_board_size = 8 * CHUNK_SCALE
    local board_origin_x = cx - math.floor(visual_board_size / 2)
    local board_origin_z = cz - math.floor(visual_board_size / 2)

    -- 2. Find the root (top-left) tile for THIS specific chunk
    local base_iso_x = board_origin_x + ((chess_x - 1) * CHUNK_SCALE)
    local base_iso_z = board_origin_z + ((chess_y - 1) * CHUNK_SCALE)

    -- Cache the fixed math conversion outside the loop to save CPU cycles
    local elev_val = Fixed.from_float(custom_elev or 15)

    -- 3. Loop over the chunk and push to the ring buffer
    for dz = 0, CHUNK_SCALE - 1 do
        for dx = 0, CHUNK_SCALE - 1 do
            local tile_idx = (base_iso_z + dz) * w + (base_iso_x + dx)

            local head = ext_state.head_idx
            ext_state.tiles[head].tile_idx = tile_idx
            ext_state.tiles[head].terrain_type = terrain_id
            ext_state.tiles[head].elevation = elev_val

            ext_state.head_idx = (ext_state.head_idx + 1) % 2048
            if ext_state.modification_count < 2048 then
                ext_state.modification_count = ext_state.modification_count + 1
            end
        end
    end
end

-- Updated Init function receives ext_state to paint the board at boot
function ChessDomain.Init(app_ctx, ext_state)
    local init_state = app_ctx.rts_grid
    local init_map = standard()

    local lua_grid_index = 1
    for y = 0, 7 do
        for x = 0, 7 do
            local current_loc = loc_cache[y + 1][x + 1]
            local piece = init_map[current_loc] or 0
            init_state.chess.grid[lua_grid_index - 1] = piece

            if piece ~= 0 then
                -- [UPDATED] Swap to the chunk function
                pop_isometric_chunk(ext_state, app_ctx, x + 1, y + 1, 15, 15)
            end

            lua_grid_index = lua_grid_index + 1
        end
    end
    init_state.chess.flags = 0x80
    init_state.chess.en_passant = 255
end

function ChessDomain.Poll(app_ctx, cmd_slot)
    if app_ctx.pending_chess_cmd then
        cmd_slot.opcode = app_ctx.pending_chess_cmd.opcode
        cmd_slot.target_pos = app_ctx.pending_chess_cmd.target_pos
        app_ctx.pending_chess_cmd = nil
    else
        cmd_slot.opcode = 0
    end
end

function ChessDomain.ApplyContract(state, ext_state, cmd, player_id, app_ctx)
    local packed = cmd.target_pos
    local from_idx = bit.rshift(packed, 8)
    local to_idx = bit.band(packed, 0xFF)

    local current_lua_map = {}
    local temp_map = Map:new(0)
    local freshmap = Map:new(false)
    local lua_grid_index = 1

    for y = 0, 7 do
        current_lua_map[y + 1] = {}
        for x = 0, 7 do
            local current_loc = loc_cache[y + 1][x + 1]
            local piece = state.chess.grid[lua_grid_index - 1]
            temp_map[current_loc] = piece
            current_lua_map[y + 1][x + 1] = piece
            if piece ~= 0 then freshmap[current_loc] = true end
            lua_grid_index = lua_grid_index + 1
        end
    end

    local is_white_turn = bit.band(state.chess.flags, 0x80) == 0x80
    local current_turn = is_white_turn and 1 or 2
    local T = Turn:new(temp_map, current_turn, freshmap)

    local f_x, f_y = (from_idx % 8) + 1, math.floor(from_idx / 8) + 1
    local t_x, t_y = (to_idx % 8) + 1, math.floor(to_idx / 8) + 1

    local new_T = false
    if f_x > 0 and f_x <= 8 and f_y > 0 and f_y <= 8 and t_x > 0 and t_x <= 8 and t_y > 0 and t_y <= 8 then
        new_T = T:make_move(loc_cache[f_y][f_x], loc_cache[t_y][t_x])
    end

    if new_T then
        local predicted_map = {}
        for y = 1, 8 do
            predicted_map[y] = {}
            for x = 1, 8 do predicted_map[y][x] = new_T.pos[loc_cache[y][x]] or 0 end
        end

        if not lab_tools.deep_compare(current_lua_map, predicted_map) then
            lab_tools.deep_merge(current_lua_map, predicted_map)

            -- [UPDATED] Swap to the chunk function for flattening
            pop_isometric_chunk(ext_state, app_ctx, f_x, f_y, 0, 0)

            -- [UPDATED] Swap to the chunk function for highlighting
            pop_isometric_chunk(ext_state, app_ctx, t_x, t_y, 15)

            lua_grid_index = 1
            for y = 1, 8 do
                for x = 1, 8 do
                    state.chess.grid[lua_grid_index - 1] = predicted_map[y][x]
                    lua_grid_index = lua_grid_index + 1
                end
            end
            state.chess.flags = is_white_turn and 0x00 or 0x80
        end
    end
end

return ChessDomain
