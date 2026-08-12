-- runtime/simulation/game_state.lua
local ffi = require("ffi")
local Fixed = require("runtime.services.math.fixed_math")

local Game = {}

function Game.init(app_ctx)
    local map_width = app_ctx.cfg_sim.world.map_width
    local map_height = app_ctx.cfg_sim.world.map_height
    local total_tiles = map_width * map_height

    if not pcall(ffi.sizeof, "GameState") then
        ffi.cdef(string.format([[
            typedef struct {
                uint32_t tile_idx;
                uint16_t terrain_type;
                int32_t elevation;
            } ModifiedTile;

            typedef struct {
                uint32_t rng_state[1];
                uint16_t modification_count; // Tracks how many tiles we've changed
                uint16_t head_idx;           // Used for the wrapping logic
                ModifiedTile tiles[2048];    // The capped array
            } GameState;
        ]], total_tiles, total_tiles))
    end

    return {
        GetStateSize = function() return ffi.sizeof("GameState") end,

        InitState = function()
            local state = ffi.new("GameState")

            local cx = math.floor(map_width / 2)
            local cz = math.floor(map_height / 2)
            local w = map_width
            local elev_val = Fixed.from_float(15.0)

            -- Helper to pack initial modifications into the sparse array
            local function add_tile(idx, terrain)
                local head = state.modification_count
                state.tiles[head].tile_idx = idx
                state.tiles[head].terrain_type = terrain
                state.tiles[head].elevation = elev_val
                state.modification_count = state.modification_count + 1
            end

            -- Paint the visual test pattern
            add_tile(cz * w + cx, 10)
            for x = cx + 1, cx + 5 do add_tile(cz * w + x, 11) end
            for z = cz + 1, cz + 5 do add_tile(z * w + cx, 12) end

            return state
        end
    }
end

return Game
