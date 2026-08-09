-- worlds/router_plugin.lua
local ffi = require("ffi")
local net = require("network.transport.network")

local isometric_domain = require("worlds.isometric.domain")
local chess_domain = require("worlds.chess.domain")

return function(app_ctx)
    local MAX_PLAYERS = ffi.C.CFG_MAX_PLAYERS

    -- 1. Grab the visual state pointer at boot
    local boot_ext_state = ffi.cast("GameState*", app_ctx.ext_state_ptr)

    isometric_domain.Init(app_ctx)
    -- 2. Pass it into the Chess Domain so it can paint the initial 8x8 grid
    chess_domain.Init(app_ctx, boot_ext_state)

    return {
        GetStateSize = function() return ffi.sizeof("LabWorldState") end,

        PollInput = function(tick, my_cmd_array)
            isometric_domain.Poll(app_ctx, my_cmd_array[0])
            chess_domain.Poll(app_ctx, my_cmd_array[1])
        end,

        SimulateTick = function(state_ptr, commands, tick)
            local state = ffi.cast("LabWorldState*", state_ptr)
            local tick_ext_state = ffi.cast("GameState*", app_ctx.ext_state_ptr)
            state.global_tick = tick

            for p = 0, MAX_PLAYERS - 1 do
                if commands[p][0].opcode == 1 then
                    isometric_domain.ApplyContract(tick_ext_state, commands[p][0], p, app_ctx)
                end
                if commands[p][1].opcode == 2 then
                    -- 3. Pass it during the simulation loop so valid moves can clear/draw tiles
                    chess_domain.ApplyContract(state, tick_ext_state, commands[p][1], p, app_ctx)
                end
            end
        end,

        HashState = function(state_ptr)
            local hash1 = net.HashState(state_ptr, ffi.sizeof("LabWorldState"), 0)
            return net.HashState(app_ctx.ext_state_ptr, app_ctx.ext_state_size, hash1)
        end
    }
end
