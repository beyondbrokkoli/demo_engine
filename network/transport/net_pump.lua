-- network/net_pump.lua
local ffi = require("ffi")
local net = require("network.transport.network")
local history_buffer = require("network.lockstep.history_buffer")
local wire_codec = require("network.lockstep.wire_codec")

local Pump = {}

function Pump.init(app_ctx)
    local MAX_PLAYERS = ffi.C.CFG_MAX_PLAYERS
    local MAX_BURST_PACKETS = app_ctx.cfg_net.MAX_BURST_PACKETS
    local DESYNC_SWEEP = app_ctx.cfg_net.DESYNC_SWEEP

    local global_in_buffer = ffi.new("RxPacket[?]", MAX_BURST_PACKETS)

    local buffer = history_buffer.init(app_ctx)
    local codec = wire_codec.init(app_ctx)

    return {
        send_dynamic_history = function(ctx)
            local current_tick = ctx.rollback_arena.head_tick
            local conf_tick = ctx.rollback_arena.confirmed_tick

            local out_pkt, final_size = codec.build_outbound(ctx, current_tick, conf_tick)

            local needs_relay = false
            for p = 0, MAX_PLAYERS - 1 do
                if p ~= ctx.net_identity and ctx.peer_active[p] then
                    if ctx.p2p_established and ctx.p2p_established[p] then
                        net.SendTo(out_pkt, final_size, p)
                    else
                        needs_relay = true
                    end
                end
            end

            if needs_relay then
                net.SendTo(out_pkt, final_size, MAX_PLAYERS)
            end
        end,

        intercept_network = function(ctx, current_tick)
            local count = net.RecvAll(global_in_buffer, MAX_BURST_PACKETS)
            local header_size = codec.get_header_size()

            for i = 0, count - 1 do
                local rx_pkt = global_in_buffer[i]

                if rx_pkt.len < header_size then goto skip_packet end

                local pkt = ffi.cast("LockstepPacket*", rx_pkt.data)

                if pkt.history_count > ffi.C.CFG_HISTORY_LEN then goto skip_packet end

                local pid = pkt.player_id
                if pid == ctx.net_identity or pid >= MAX_PLAYERS or not ctx.peer_active[pid] then goto skip_packet end
                if pkt.frame_tick < ctx.rollback_arena.confirmed_tick then goto skip_packet end

                -- Update Acks
                local relevant_ack = pkt.peer_acks[ctx.net_identity]
                if relevant_ack > ctx.peer_ack_of_me[pid] then
                    ctx.peer_ack_of_me[pid] = relevant_ack
                end

                local payload_highest_tick = pkt.base_tick + pkt.history_count - 1
                if pkt.base_tick <= ctx.peer_highest_tick[pid] + 1 and payload_highest_tick > ctx.peer_highest_tick[pid] then
                    ctx.peer_highest_tick[pid] = payload_highest_tick
                end

                -- Pass raw pointers strictly bounded to the simulation domain
                buffer.integrate(
                    ctx.rollback_arena,
                    pkt.commands,
                    pkt.base_tick,
                    pkt.history_count,
                    pid,
                    current_tick
                )

                buffer.audit_checksum(
                    ctx.rollback_arena,
                    pkt.state_checksum,
                    pkt.checksum_tick,
                    current_tick,
                    DESYNC_SWEEP
                )

                ::skip_packet::
            end
        end
    }
end

return Pump
