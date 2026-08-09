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

-- Helper for subtle visual highlights
local function pop_isometric_tile(ext_state, app_ctx, chess_x, chess_y, terrain_id, custom_elev)
    -- [RESTORED]
    local w = app_ctx.cfg_sim.world.map_width
    local h = app_ctx.cfg_sim.world.map_height
    local cx = math.floor(w / 2)
    local cz = math.floor(h / 2)

    local iso_x = (cx - 4) + (chess_x - 1)
    local iso_y = (cz - 4) + (chess_y - 1)
    local tile_idx = iso_y * w + iso_x

    local head = ext_state.head_idx
    ext_state.tiles[head].tile_idx = tile_idx
    ext_state.tiles[head].terrain_type = terrain_id

    -- Allow passing a custom elevation, default to 0.5 for active pieces
    ext_state.tiles[head].elevation = custom_elev or Fixed.from_float(0.5)

    ext_state.head_idx = (ext_state.head_idx + 1) % 2048
    if ext_state.modification_count < 2048 then
        ext_state.modification_count = ext_state.modification_count + 1
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

            -- If a piece exists on this square, map it to the visual grid
            if piece ~= 0 then
                -- Terrain 15 provides a distinct but subdued board square highlight
                pop_isometric_tile(ext_state, app_ctx, x + 1, y + 1, 15)
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


-- Update signature to receive ext_state
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

            -- CROSS-POLLINATION: Update the visuals!
            -- 1. Flatten the old 'from' square (Terrain 0, Elevation 0)
            pop_isometric_tile(ext_state, app_ctx, f_x, f_y, 0, 0)

            -- 2. Highlight the new 'to' square (Terrain 15, Elevation 0.5)
            pop_isometric_tile(ext_state, app_ctx, t_x, t_y, 15)

            -- Write back to FFI
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
