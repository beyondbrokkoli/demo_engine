-- network/session/netcode.lua
require("runtime.boot.path_weaver")
io.stdout:setvbuf("no")

local ffi = require("ffi")

local structs = require("network.protocol.structs")
local net_utils = require("network.session.net_utils")
local net_pump = require("network.transport.net_pump")
local fsm_core = require("network.lockstep.fsm_core")
local net = require("network.transport.network")
local create_lab_domain = require("worlds.router_plugin")
local config_net = require("network.protocol.config_net")
local config_sim = require("ssot.config_sim")

local MAX_PLAYERS = ffi.C.CFG_MAX_PLAYERS
local RING_SIZE   = ffi.C.CFG_RING_SIZE
local RELAY_PORT  = 49152

local NetCore = {}

-- Change signature to accept target_lobby_size
function NetCore.init(local_port, target_lobby_id, target_lobby_size, ext_state_ptr, ext_state_size)
    -- [FORCE EPHEMERAL] Unlink completely from manual ports
    local_port = 0
    print(string.format("[LAB] Initializing Headless Node on Port %d...", local_port))

    local my_local_ip = net_utils.get_local_ip()

    -- Forward target_lobby_size down to the topology bootstrapper
    local session_token, local_id, p2p_established, active_peers = net_utils.BootstrapNetworkTopology(
        local_port,
        my_local_ip,
        target_lobby_id,
        target_lobby_size
    )

    local app_ctx = {
        -- [FIXED] Pass the real config module instead of a hardcoded inline table!
        -- Now DESYNC_SWEEP will properly be 510, matching the deep time machine.
        cfg_net = config_net,
        cfg_sim = config_sim, -- [ADDED]
        net_identity = local_id,
        session_token = session_token,
        rollback_arena = ffi.new("RollbackBuffer"),
        peer_active = active_peers,
        p2p_established = p2p_established,
        peer_highest_tick = ffi.new("uint32_t[?]", MAX_PLAYERS),
        peer_ack_of_me = ffi.new("uint32_t[?]", MAX_PLAYERS),
        sim_tick_count = 1,
        accumulator = 0.0,
        rts_grid = ffi.new("LabWorldState"),
        snapshot_ring = ffi.new("LabWorldState[?]", RING_SIZE),

        -- [TOW TRUCK] Link the external visual memory for the domain to modify
        ext_state_ptr = ext_state_ptr,
        ext_state_size = ext_state_size,
        -- Allocate a raw byte ring-buffer to snapshot the visual state for rollbacks (approx 400MB)
        ext_snapshot_ring = ffi.new("uint8_t[?]", ext_state_size * RING_SIZE)
    }

    math.randomseed(os.time() + local_id)

    local lab_domain = create_lab_domain(app_ctx)
    local pump = net_pump.init(app_ctx)
    local fsm = fsm_core.init(app_ctx, lab_domain)

    -- [FIX] ANCHOR SNAPSHOT ZERO
    -- Before the FSM begins, save the absolute starting state to index 0.
    -- If we rollback to Tick 1, this prevents the engine from restoring uninitialized memory.
    local STATE_SIZE = lab_domain.GetStateSize()
    ffi.copy(app_ctx.snapshot_ring[0], app_ctx.rts_grid, STATE_SIZE)

    if app_ctx.ext_state_ptr and app_ctx.ext_state_size > 0 then
        ffi.copy(app_ctx.ext_snapshot_ring, app_ctx.ext_state_ptr, app_ctx.ext_state_size)
    end

    return {
        ctx = app_ctx,
        domain = lab_domain,
        pump = pump,
        fsm = fsm,
        heartbeat_acc = 0.0,
        diag_rollbacks = 0,
        diag_resim_frames = 0,
        diag_stalls = 0
    }
end

function NetCore.pump_network(engine, dt)
    -- 1. SPIRAL OF DEATH PROTECTION
    if dt > 0.25 then dt = 0.25 end

    -- 2. UNCONDITIONAL TIME GATHERING
    engine.ctx.accumulator = engine.ctx.accumulator + dt
    engine.heartbeat_acc = engine.heartbeat_acc + dt

    -- 3. HIGH-FREQUENCY NETWORK INTERCEPT
    engine.pump.intercept_network(engine.ctx, engine.ctx.sim_tick_count)

    local TICK_RATE = 1.0 / engine.ctx.cfg_net.TICK_RATE

    -- 4. THE PROTECTED FSM VAULT
    if engine.ctx.accumulator >= TICK_RATE then
        if engine.ctx.rollback_arena.is_rollback_active == 1 then
            engine.diag_rollbacks = engine.diag_rollbacks + 1
            engine.diag_resim_frames = engine.diag_resim_frames + (engine.ctx.sim_tick_count - engine.ctx.rollback_arena.rollback_target)
        end

        local tick_before = engine.ctx.sim_tick_count
        engine.fsm.tick_playing_state(engine.ctx, TICK_RATE)

        if engine.ctx.sim_tick_count == tick_before then
            engine.diag_stalls = engine.diag_stalls + 1
        end

        -- 5. NETWORK FLUSH
        if engine.ctx.sim_tick_count > tick_before then
            engine.pump.send_dynamic_history(engine.ctx)
        end
    end

    -- Heartbeat Reporting
    if engine.heartbeat_acc >= 1.0 then
        print(string.format("[HEARTBEAT] Node: %d | Tick: %5d | Conf: %5d | Hash: 0x%08X | Rollbacks: %2d (Resim: %3d) | Stalls: %2d",
            engine.ctx.net_identity,
            engine.ctx.sim_tick_count,
            engine.ctx.rollback_arena.confirmed_tick,
            engine.domain.HashState(engine.ctx.rts_grid),
            engine.diag_rollbacks,
            engine.diag_resim_frames,
            engine.diag_stalls
        ))

        engine.diag_rollbacks = 0
        engine.diag_resim_frames = 0
        engine.diag_stalls = 0
        engine.heartbeat_acc = engine.heartbeat_acc - 1.0
    end

    return engine.ctx.rts_grid
end

function NetCore.inject_local_command(engine, opcode, target_pos)
    if engine.ctx.sim_tick_count < 60 then
        return
    end

    -- [FIXED] Route to the correct mailbox based on opcode
    if opcode == 1 then
        engine.ctx.pending_ui_cmd = {
            opcode = opcode,
            target_pos = target_pos
        }
    elseif opcode == 2 then
        engine.ctx.pending_chess_cmd = {
            opcode = opcode,
            target_pos = target_pos
        }
    end
end

return NetCore
