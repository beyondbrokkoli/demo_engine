-- worlds/isometric/domain.lua
local ffi = require("ffi")
local Fixed = require("runtime.services.math.fixed_math")

local IsoDomain = {}

function IsoDomain.Init(app_ctx)
    -- Reserved for future isometric init logic
end

function IsoDomain.Poll(app_ctx, cmd_slot)
    if app_ctx.pending_ui_cmd then
        cmd_slot.opcode = app_ctx.pending_ui_cmd.opcode
        cmd_slot.target_pos = app_ctx.pending_ui_cmd.target_pos
        app_ctx.pending_ui_cmd = nil
    else
        cmd_slot.opcode = 0
    end
end

function IsoDomain.ApplyContract(ext_state, cmd, player_id, app_ctx)
    local idx = cmd.target_pos
    local target_terrain = 10 + player_id
    local current_elev, found_i = 0, -1

    for i = 0, ext_state.modification_count - 1 do
        -- [THE FIX] Removed the terrain_type ownership check.
        -- If a modification exists at this tile_idx, we claim it and modify it,
        -- preventing duplicate overlaps.
        if ext_state.tiles[i].tile_idx == idx then
            current_elev = ext_state.tiles[i].elevation
            found_i = i
            break
        end
    end

    local new_elev = (current_elev > 0) and 0 or Fixed.from_float(15.0)
    local new_terrain = (current_elev > 0) and 0 or target_terrain

    if found_i >= 0 then
        ext_state.tiles[found_i].elevation = new_elev
        ext_state.tiles[found_i].terrain_type = new_terrain
    else
        local head = ext_state.head_idx
        ext_state.tiles[head].tile_idx = idx
        ext_state.tiles[head].elevation = new_elev
        ext_state.tiles[head].terrain_type = new_terrain

        ext_state.head_idx = (ext_state.head_idx + 1) % 2048
        if ext_state.modification_count < 2048 then
            ext_state.modification_count = ext_state.modification_count + 1
        end
    end
end

return IsoDomain
