-- network/session/ice_handshake.lua
local ffi = require("ffi")
local cfg_net = require("network.protocol.config_net")
local net = require("network.transport.network")
local sys_time = require("network.session.sys_time")

local M = {}

function M.punch_through(session_token, status_data, my_pub_ip, my_pub_port, my_local_ip, local_port)
    print("[DEBUG-NET] Matchmaker sequence complete. Proceeding to peer evaluation...")

    local local_id = 0
    for i, p in ipairs(status_data.players) do
        if p.public_ip == my_pub_ip and tonumber(p.public_port) == my_pub_port and p.local_ip == my_local_ip and p.local_port == local_port then
            local_id = i - 1; break
        end
    end

    net.SetPlayerId(local_id)
    net.SetSession(session_token)

    local p2p_established = {}
    local p2p_heard = {}
    local active_peers = {}

    for i, p in ipairs(status_data.players) do
        local peer_id = i - 1
        if peer_id ~= local_id then
            active_peers[peer_id] = true
            -- [FIX]: Removed pre-emptive IP assumptions. We let the ICE loop discover the truth.
        end
    end

    local real_time_remaining = status_data.start_time - status_data.server_time
    local sync_start_time = sys_time.get_time_hires()

    print(string.format("[DEBUG-NET] Entering TRUE ICE Handshake... (Time remaining: %.2fs)", real_time_remaining))

    if real_time_remaining > 0 then
        local ice_packet_size = ffi.sizeof("IcePunchPacket")
        local handshake_buffer = ffi.new("RxPacket[32]")
        local scratch_ice = ffi.new("IcePunchPacket")

        while (sys_time.get_time_hires() - sync_start_time) < real_time_remaining do
            -- 1. PING PHASE: Spray candidates or Ack locked routes
            for peer_id, active in pairs(active_peers) do
                if active then
                    local ping_pkt = ffi.new("IcePunchPacket")
                    ping_pkt.session_token = session_token
                    ping_pkt.player_id = local_id
                    ping_pkt.is_ping = p2p_heard[peer_id] and 1 or 0

                    if not p2p_heard[peer_id] then
                        -- [CANDIDATE SPRAYING]: We don't know the route yet. Hit everything.
                        local p = status_data.players[peer_id + 1]

                        -- Route A: Local Candidate
                        local target_local = (p.local_ip == my_local_ip) and "127.0.0.1" or p.local_ip
                        net.Connect(peer_id, target_local, tonumber(p.local_port))
                        net.SendTo(ping_pkt, ice_packet_size, peer_id)

                        -- Route B: Public Candidate
                        net.Connect(peer_id, p.public_ip, tonumber(p.public_port))
                        net.SendTo(ping_pkt, ice_packet_size, peer_id)
                    else
                        -- [ACKNOWLEDGE]: C-Layer has auto-locked the winning IP.
                        -- Just pump acks down the established pipe so they can lock too.
                        net.SendTo(ping_pkt, ice_packet_size, peer_id)
                    end
                end
            end

            -- 2. RECV PHASE: Listen for the truth
            local count = net.RecvAll(handshake_buffer, 32)
            for i = 0, count - 1 do
                local rx_pkt = handshake_buffer[i]
                if rx_pkt.len >= ice_packet_size then
                    ffi.copy(scratch_ice, rx_pkt.data, ice_packet_size)
                    if scratch_ice.session_token == session_token then
                        local sender = scratch_ice.player_id

                        if not p2p_heard[sender] then
                            -- The C layer just bound this sender to the winning IP!
                            print(string.format("[DEBUG-NET] Peer %d route locked!", sender))
                            p2p_heard[sender] = true
                        end

                        if scratch_ice.is_ping >= 1 and not p2p_established[sender] then
                            print(string.format("[DEBUG-NET] ICE Handshake successful with peer %d!", sender))
                            p2p_established[sender] = true
                        end
                    end
                end
            end
            sys_time.sleep(50)
        end
    end

    local needs_relay = false
    local fallback_peer = 0

    for peer_id, active in pairs(active_peers) do
        if active and not p2p_established[peer_id] then
            print(string.format("[DEBUG-NET] Peer %d failed ICE handshake. Falling back to RELAY.", peer_id))
            net.Connect(peer_id, cfg_net.RELAY_IP, cfg_net.RELAY_PORT)
            p2p_established[peer_id] = true
            needs_relay = true
            fallback_peer = peer_id
        end
    end

    net.SetRelayIP(cfg_net.RELAY_IP)

    if needs_relay then
        local reg_pkt = ffi.new("IcePunchPacket")
        reg_pkt.session_token = session_token
        reg_pkt.player_id = local_id
        reg_pkt.is_ping = 0
        net.SendTo(reg_pkt, ffi.sizeof("IcePunchPacket"), fallback_peer)
    end

    return local_id, p2p_established, active_peers
end

return M
