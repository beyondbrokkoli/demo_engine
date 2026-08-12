-- worlds/chess/domain_terrain.lua
local ffi = require("ffi")
local Fixed = require("runtime.services.math.fixed_math")
local Base = require("worlds.chess.domain_base")

-- Maintain exact variable names internally
local CHUNK_SCALE = Base._CHUNK_SCALE

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

            -- 1. Search for existing tile to prevent ghosting and hash shifting
            local found_i = -1
            for i = 0, ext_state.modification_count - 1 do
                if ext_state.tiles[i].tile_idx == tile_idx then
                    found_i = i
                    break
                end
            end

            if found_i >= 0 then
                -- 2A. Update in-place (Rollback safe, head_idx remains static)
                ext_state.tiles[found_i].terrain_type = terrain_id
                ext_state.tiles[found_i].elevation = elev_val
            else
                -- 2B. Append new tile (Happens only once per visual square)
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
end

return {
    pop_isometric_chunk = pop_isometric_chunk
}
