-- worlds/chess/domain.lua
local ffi = require("ffi")
local bit = require("bit")
local lab_tools = require("tools.lab_domain")
local Fixed = require("runtime.services.math.fixed_math") -- Need this for elevation
require("game.turn")
require("game.standard")
require("global")

local ChessDomain = {}
local loc_cache = {}
for y = 1, 8 do
    loc_cache[y] = {}
    for x = 1, 8 do loc_cache[y][x] = loc:new(x, y) end
end

function ChessDomain.Init(app_ctx)
    local init_state = app_ctx.rts_grid
    local init_map = standard()

    local lua_grid_index = 1
    for y = 0, 7 do
        for x = 0, 7 do
            local current_loc = loc_cache[y + 1][x + 1]
            init_state.chess.grid[lua_grid_index - 1] = init_map[current_loc] or 0
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
-- Helper for subtle visual highlights on the external grid
local function pop_isometric_tile(ext_state, app_ctx, chess_x, chess_y, terrain_id)
    local w = app_ctx.cfg_sim.world.map_width
    local h = app_ctx.cfg_sim.world.map_height
    local cx = math.floor(w / 2)
    local cz = math.floor(h / 2)

    -- Center the 8x8 board on the main grid
    local iso_x = (cx - 4) + (chess_x - 1)
    local iso_y = (cz - 4) + (chess_y - 1)
    local tile_idx = iso_y * w + iso_x

    local head = ext_state.head_idx
    ext_state.tiles[head].tile_idx = tile_idx

    -- Implement a subtle, non-invasive visual style
    ext_state.tiles[head].terrain_type = terrain_id
    ext_state.tiles[head].elevation = Fixed.from_float(0.5) -- Tiny visual bump, not a pillar

    ext_state.head_idx = (ext_state.head_idx + 1) % 2048
    if ext_state.modification_count < 2048 then
        ext_state.modification_count = ext_state.modification_count + 1
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

            -- THE CROSS-POLLINATION: The move is legal, render it visually!
            -- Give the 'from' tile a subtle shadow (terrain 13) and the 'to' tile a subtle glow (terrain 14)
            pop_isometric_tile(ext_state, app_ctx, f_x, f_y, 13)
            pop_isometric_tile(ext_state, app_ctx, t_x, t_y, 14)

            -- Write to FFI
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
