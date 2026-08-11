-- network/fsm_simulator.lua
local bit = require("bit")
local ffi = require("ffi")
local structs = require("network.protocol.structs")

local Simulator = {}

function Simulator.prepare_frame(ctx, RING_MASK)
    local c_idx = bit.band(ctx.sim_tick_count, RING_MASK)
    local frame = ctx.rollback_arena.frames[c_idx]

    -- Tenet II: The Sterile Tick
    if frame.tick ~= ctx.sim_tick_count then
        structs.zero_memory(frame, "NetworkFrame")
        frame.tick = ctx.sim_tick_count
    end

    -- [THE TRUE PREDICTION]
    -- We predict forward unconditionally for any peer that hasn't delivered this tick yet.
    if ctx.sim_tick_count > 1 then
        local prev_idx = bit.band(ctx.sim_tick_count - 1, RING_MASK)
        local prev_frame = ctx.rollback_arena.frames[prev_idx]
        local MAX_PLAYERS = ffi.C.CFG_MAX_PLAYERS

        for p = 0, MAX_PLAYERS - 1 do
            if p ~= ctx.net_identity and ctx.peer_active[p] then
                -- If we haven't received actual network data for this peer at this tick...
                if ctx.sim_tick_count > ctx.peer_highest_tick[p] then
                    local dst = ffi.cast("uint64_t*", frame.commands[p])
                    local src = ffi.cast("uint64_t*", prev_frame.commands[p])
                    dst[0] = src[0]
                    dst[1] = src[1]
                end
            end
        end
    end

    ctx.rollback_arena.head_tick = ctx.sim_tick_count
end

function Simulator.execute_rollback(ctx, STATE_SIZE, SimulateTick, HashState, RING_MASK, HISTORY_HORIZON)
    if ctx.rollback_arena.is_rollback_active == 0 then return end

    local t_tgt = ctx.rollback_arena.rollback_target

    if (ctx.sim_tick_count - t_tgt) > HISTORY_HORIZON then
        print(string.format("[FATAL] Rollback horizon exceeded memory limit! Target: %d | Head: %d", t_tgt, ctx.sim_tick_count))
        os.exit(1)
    end

    -- 1. Restore the pristine state from history
    local r_idx = bit.band(t_tgt - 1, RING_MASK)
    ffi.copy(ctx.rts_grid, ctx.snapshot_ring[r_idx], STATE_SIZE)

    -- [RESTORE INJECTION] Tow Truck: Restore Vulkan graphical state
    ffi.copy(
        ctx.ext_state_ptr,
        ctx.ext_snapshot_ring + (r_idx * ctx.ext_state_size),
        ctx.ext_state_size
    )
    -- 2. Fast-forward simulation back to the present
    local MAX_PLAYERS = ffi.C.CFG_MAX_PLAYERS
    for t = t_tgt, ctx.sim_tick_count - 1 do
        local f_idx = bit.band(t, RING_MASK)
        local f = ctx.rollback_arena.frames[f_idx]

        -- [THE MISSING RE-PREDICTION LOGIC]
        -- If we are in the future relative to a remote peer's highest confirmed tick,
        -- we must overwrite the stale prediction with their last known input.
        local prev_idx = bit.band(t - 1, RING_MASK)
        local prev_f = ctx.rollback_arena.frames[prev_idx]

        for p = 0, MAX_PLAYERS - 1 do
            if p ~= ctx.net_identity and ctx.peer_active[p] then
                if t > ctx.peer_highest_tick[p] then
                    local dst = ffi.cast("uint64_t*", f.commands[p])
                    local src = ffi.cast("uint64_t*", prev_f.commands[p])
                    dst[0] = src[0]
                    dst[1] = src[1]
                end
            end
        end

        SimulateTick(ctx.rts_grid, f.commands, t)
        f.state_checksum = HashState(ctx.rts_grid)
        ffi.copy(ctx.snapshot_ring[f_idx], ctx.rts_grid, STATE_SIZE)

        -- [SAVE INJECTION] Tow Truck: Save Vulkan graphical state during fast-forward
        ffi.copy(
            ctx.ext_snapshot_ring + (f_idx * ctx.ext_state_size),
            ctx.ext_state_ptr,
            ctx.ext_state_size
        )
    end

    ctx.rollback_arena.is_rollback_active = 0
end

function Simulator.simulate_forward(ctx, STATE_SIZE, SimulateTick, HashState, RING_MASK)
    local c_idx = bit.band(ctx.sim_tick_count, RING_MASK)
    local frame = ctx.rollback_arena.frames[c_idx]

    SimulateTick(ctx.rts_grid, frame.commands, ctx.sim_tick_count)
    frame.state_checksum = HashState(ctx.rts_grid)

    ffi.copy(ctx.snapshot_ring[c_idx], ctx.rts_grid, STATE_SIZE)

    -- [SAVE INJECTION] Tow Truck: Save Vulkan graphical state during forward tick
    ffi.copy(
        ctx.ext_snapshot_ring + (c_idx * ctx.ext_state_size),
        ctx.ext_state_ptr,
        ctx.ext_state_size
    )
    ctx.sim_tick_count = ctx.sim_tick_count + 1
end

function Simulator.audit_desyncs(ctx, RING_MASK, DESYNC_SWEEP)
    local conf_tick = ctx.rollback_arena.confirmed_tick
    local sweep_start = math.max(0, conf_tick - DESYNC_SWEEP)

    for v_tick = sweep_start, conf_tick do
        local v_idx = bit.band(v_tick, RING_MASK)
        local v_frame = ctx.rollback_arena.frames[v_idx]

        -- Tenet VI: Rejoice in the Fatal Crash
        if v_frame.tick == v_tick and v_frame.state_checksum ~= 0 and v_frame.remote_checksum ~= 0 then
            if v_frame.state_checksum ~= v_frame.remote_checksum then
                print(string.format("[FATAL DESYNC] Tick: %d | Local: 0x%08X | Remote: 0x%08X",
                    v_tick, v_frame.state_checksum, v_frame.remote_checksum))
                os.exit(1)
            end
        end
    end
end

return Simulator
