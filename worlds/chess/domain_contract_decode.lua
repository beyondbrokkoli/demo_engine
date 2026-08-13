-- worlds/chess/domain_contract_decode.lua
local bit = require("bit")
local Base = require("worlds.chess.domain_base")

local loc_cache = Base._loc_cache

local function DecodePhase(state, cmd)
    -- 0. COMMAND UNPACKING
    local packed = cmd.target_pos
    local from_idx = bit.rshift(packed, 8)
    local to_idx = bit.band(packed, 0xFF)

    -- If there's no command this tick, exit immediately to save CPU cycles.
    -- We return 'false' to signal the router to abort the pipeline.
    if from_idx == 0 and to_idx == 0 then
        return false
    end

    -- 1. THE BLANK SLATE
    local temp_map = Map:new(0)
    local freshmap = Map:new(false)
    local lua_grid_index = 1

    local flags = state.chess.flags
    local is_white_turn = bit.band(flags, 0x80) == 0x80
    local current_turn = is_white_turn and 1 or 2

    -- 2. DECODE FFI STATE TO LUACHESS
    for y = 0, 7 do
        for x = 0, 7 do
            local current_loc = loc_cache[y + 1][x + 1]
            local piece = state.chess.grid[lua_grid_index - 1]
            temp_map[current_loc] = piece

            -- RECONSTRUCTING CASTLING RIGHTS
            if piece == 1 and (y + 1) == 2 then freshmap[current_loc] = true end
            if piece == -1 and (y + 1) == 7 then freshmap[current_loc] = true end
            if piece == 8 and (y + 1) == 1 then freshmap[current_loc] = true end
            if piece == -8 and (y + 1) == 8 then freshmap[current_loc] = true end

            if piece == 4 and (y + 1) == 1 then
                if x == 7 and bit.band(flags, 0x08) ~= 0 then freshmap[current_loc] = true end
                if x == 0 and bit.band(flags, 0x04) ~= 0 then freshmap[current_loc] = true end
            end
            if piece == -4 and (y + 1) == 8 then
                if x == 7 and bit.band(flags, 0x02) ~= 0 then freshmap[current_loc] = true end
                if x == 0 and bit.band(flags, 0x01) ~= 0 then freshmap[current_loc] = true end
            end

            lua_grid_index = lua_grid_index + 1
        end
    end

    -- 3. DECODE EN PASSANT
    local eptoken = nil
    if state.chess.en_passant ~= 255 then
        local ep_x = (state.chess.en_passant % 8) + 1
        local ep_y = math.floor(state.chess.en_passant / 8) + 1
        eptoken = { x = ep_x, y = ep_y, id = is_white_turn and -7 or 7 }
    end

    -- Pass everything the subsequent phases need
    return true, from_idx, to_idx, temp_map, freshmap, current_turn, eptoken, is_white_turn
end

return DecodePhase
