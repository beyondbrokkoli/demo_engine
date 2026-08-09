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

local CHUNK_SCALE = 3

local function pop_isometric_chunk(ext_state, app_ctx, chess_x, chess_y, terrain_id, custom_elev)
    local w = app_ctx.cfg_sim.world.map_width
    local h = app_ctx.cfg_sim.world.map_height
    local cx = math.floor(w / 2)
    local cz = math.floor(h / 2)

    local visual_board_size = 8 * CHUNK_SCALE
    local board_origin_x = cx - math.floor(visual_board_size / 2)
    local board_origin_z = cz - math.floor(visual_board_size / 2)

    local base_iso_x = board_origin_x + ((chess_x - 1) * CHUNK_SCALE)
    local base_iso_z = board_origin_z + ((chess_y - 1) * CHUNK_SCALE)

    -- [AUDIT GUARD: Float vs Fixed-Point]
    -- Catch redundant fixed-point conversions before they ruin the subtle visual layout
    local raw_elev = custom_elev or 15.0
    if raw_elev > 255 then
        print(string.format("[AUDIT WARN] Suspiciously high float detected in chunk (%d, %d): %s. Forcing subtle baseline.", chess_x, chess_y, tostring(raw_elev)))
        raw_elev = 15.0
    end

    local elev_val = Fixed.from_float(raw_elev)

    for dz = 0, CHUNK_SCALE - 1 do
        for dx = 0, CHUNK_SCALE - 1 do
            local tile_idx = (base_iso_z + dz) * w + (base_iso_x + dx)

            -- [AUDIT GUARD: Spatial Boundaries]
            if tile_idx < 0 or tile_idx >= (w * h) then
                error(string.format("[FATAL AUDIT] Chunk scaling out of bounds! Tile %d exceeds map limits.", tile_idx))
            end

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
                pop_isometric_chunk(ext_state, app_ctx, x + 1, y + 1, 15, 15.0)
            end

            lua_grid_index = lua_grid_index + 1
        end
    end
    init_state.chess.flags = 0x80
    init_state.chess.en_passant = 255
    print("[AUDIT INIT] Chess Domain mapped successfully to visual buffer.")
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

    -- 1. Early exit for empty commands to save CPU cycles
    if from_idx == 0 and to_idx == 0 then return end

    local temp_map = Map:new(0)
    local freshmap = Map:new(false)
    local lua_grid_index = 1

    -- 2. Read directly from FFI memory to feed the oracle
    for y = 0, 7 do
        for x = 0, 7 do
            local current_loc = loc_cache[y + 1][x + 1]
            local piece = state.chess.grid[lua_grid_index - 1]
            temp_map[current_loc] = piece
            if piece ~= 0 then freshmap[current_loc] = true end
            lua_grid_index = lua_grid_index + 1
        end
    end

    local is_white_turn = bit.band(state.chess.flags, 0x80) == 0x80
    local current_turn = is_white_turn and 1 or 2
    local T = Turn:new(temp_map, current_turn, freshmap)

    local f_x, f_y = (from_idx % 8) + 1, math.floor(from_idx / 8) + 1
    local t_x, t_y = (to_idx % 8) + 1, math.floor(to_idx / 8) + 1

    -- 3. Maintain the spatial bounds check
    local new_T = false
    if f_x > 0 and f_x <= 8 and f_y > 0 and f_y <= 8 and t_x > 0 and t_x <= 8 and t_y > 0 and t_y <= 8 then
        new_T = T:make_move(loc_cache[f_y][f_x], loc_cache[t_y][t_x])
    end

    -- 4. Trust the oracle. If new_T exists, the move is 100% valid.
    if new_T then
        if app_ctx.rollback_arena.is_rollback_active == 0 then
            print(string.format("[AUDIT PASS] Valid move accepted. Visually updating (%d, %d) to (%d, %d).", f_x, f_y, t_x, t_y))
        end

        pop_isometric_chunk(ext_state, app_ctx, f_x, f_y, 0, 0.0)
        pop_isometric_chunk(ext_state, app_ctx, t_x, t_y, 15, 15.0)

        -- 5. Write directly back to FFI memory, bypassing Lua table instantiation entirely!
        lua_grid_index = 1
        for y = 1, 8 do
            for x = 1, 8 do
                state.chess.grid[lua_grid_index - 1] = new_T.pos[loc_cache[y][x]] or 0
                lua_grid_index = lua_grid_index + 1
            end
        end

        state.chess.flags = is_white_turn and 0x00 or 0x80
    else
        if app_ctx.rollback_arena.is_rollback_active == 0 then
            print(string.format("[AUDIT REJECT] Turn engine declined move vector (%d, %d) -> (%d, %d)", f_x, f_y, t_x, t_y))
        end
    end
end

return ChessDomain
