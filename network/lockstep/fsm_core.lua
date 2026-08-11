-- network/fsm_core.lua
local bit = require("bit")
local ffi = require("ffi")
local pacing = require("network.lockstep.fsm_pacing")
local simulator = require("network.lockstep.fsm_simulator")

local FSM = {}

function FSM.init(app_ctx, domain_module)
    local MAX_PLAYERS     = ffi.C.CFG_MAX_PLAYERS
    local RING_MASK       = ffi.C.CFG_RING_SIZE - 1

    local LOOKAHEAD_CAP   = app_ctx.cfg_net.LOOKAHEAD_CAP
    local DESYNC_SWEEP    = app_ctx.cfg_net.DESYNC_SWEEP
    local LOCAL_HORIZON   = app_ctx.cfg_net.LOCAL_HORIZON -- [NEW] Fetch from config

    local SimulateTick = domain_module.SimulateTick
    local HashState    = domain_module.HashState
    local GetStateSize = domain_module.GetStateSize
    local PollInput    = domain_module.PollInput

    local STATE_SIZE   = GetStateSize()

    return {
        tick_playing_state = function(ctx, FIXED_DT)
            local remote_highest = pacing.calculate_horizons(ctx, FIXED_DT, MAX_PLAYERS, LOOKAHEAD_CAP)

            while ctx.accumulator >= FIXED_DT do
                simulator.prepare_frame(ctx, RING_MASK)

                local c_idx = bit.band(ctx.sim_tick_count, RING_MASK)
                local my_full_cmd = ctx.rollback_arena.frames[c_idx].commands[ctx.net_identity]

                PollInput(ctx.sim_tick_count, my_full_cmd)

                -- [CHANGED] Pass LOCAL_HORIZON instead of HISTORY_HORIZON
                simulator.execute_rollback(ctx, STATE_SIZE, SimulateTick, HashState, RING_MASK, LOCAL_HORIZON)

                if ctx.sim_tick_count <= remote_highest + LOOKAHEAD_CAP then
                    simulator.simulate_forward(ctx, STATE_SIZE, SimulateTick, HashState, RING_MASK)
                    simulator.audit_desyncs(ctx, RING_MASK, DESYNC_SWEEP)
                end

                ctx.accumulator = ctx.accumulator - FIXED_DT
            end
        end
    }
end

return FSM
