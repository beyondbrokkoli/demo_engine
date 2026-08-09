-- network/lab_domain.lua
local ffi = require("ffi")
local net = require("network")
local Fixed = require("fixed_math") -- [RESTORED] Bring back the native math!

return function(app_ctx)
    local MAX_PLAYERS = ffi.C.CFG_MAX_PLAYERS

    return {
        GetStateSize = function() return ffi.sizeof("LabWorldState") end,

        PollInput = function(tick, my_cmd_array)
            -- 1. Read from the Tow Truck's Mailbox
            if app_ctx.pending_ui_cmd then
                my_cmd_array[0].opcode = app_ctx.pending_ui_cmd.opcode
                my_cmd_array[0].target_pos = app_ctx.pending_ui_cmd.target_pos

                -- Consume the input so we don't spam it every tick
                app_ctx.pending_ui_cmd = nil
            else
                -- Neutral / Idle State
                my_cmd_array[0].opcode = 0
                my_cmd_array[0].target_pos = 0
            end

            -- Clear payload as we aren't using it yet
            my_cmd_array[1].opcode = 0
        end,

        SimulateTick = function(state_ptr, commands, tick)
            local state = ffi.cast("LabWorldState*", state_ptr)
            state.global_tick = tick

            -- Cast the raw block of bytes to the new 24KB sparse GameState
            local g_state = ffi.cast("GameState*", app_ctx.ext_state_ptr)

            for p = 0, MAX_PLAYERS - 1 do
                local cmd_primary = commands[p][0]

                if cmd_primary.opcode == 1 then -- OP_TOGGLE_TILE
                    local idx = cmd_primary.target_pos
                    local target_terrain = 10 + p

                    -- 1. Scan the sparse array for this specific tile & player
                    local current_elev = 0
                    local found_i = -1

                    for i = 0, g_state.modification_count - 1 do
                        if g_state.tiles[i].tile_idx == idx and (g_state.tiles[i].terrain_type == target_terrain or g_state.tiles[i].terrain_type == 0) then
                            current_elev = g_state.tiles[i].elevation
                            found_i = i
                            break
                        end
                    end

                    -- 2. The Toggle Logic
                    local new_elev = (current_elev > 0) and 0 or Fixed.from_float(15.0)
                    local new_terrain = (current_elev > 0) and 0 or target_terrain

                    -- 3. Update in-place, or Append to the sparse array using wrap-around
                    if found_i >= 0 then
                        g_state.tiles[found_i].elevation = new_elev
                        g_state.tiles[found_i].terrain_type = new_terrain
                    else
                        -- [THE WRAP-AROUND PATCH]
                        local head = g_state.head_idx

                        g_state.tiles[head].tile_idx = idx
                        g_state.tiles[head].elevation = new_elev
                        g_state.tiles[head].terrain_type = new_terrain

                        -- Advance the pointer and wrap back to 0 if it hits 2048
                        g_state.head_idx = (g_state.head_idx + 1) % 2048

                        -- Cap modification_count so the renderer doesn't read out of bounds
                        if g_state.modification_count < 2048 then
                            g_state.modification_count = g_state.modification_count + 1
                        end
                    end
                end
            end
        end,

        HashState = function(state_ptr)
            -- 1. Hash the tiny internal netcode state
            local hash1 = net.HashState(state_ptr, ffi.sizeof("LabWorldState"), 0)

            -- 2. Chain that hash into the massive 400MB visual grid!
            return net.HashState(app_ctx.ext_state_ptr, app_ctx.ext_state_size, hash1)
        end
    }
end
