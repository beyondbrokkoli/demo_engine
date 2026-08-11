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
    local active_peers = {}

    for i, p in ipairs(status_data.players) do
        local peer_id = i - 1
        if peer_id ~= local_id then
            active_peers[peer_id] = true
            if p.public_ip == my_pub_ip or p.public_ip == "127.0.0.1" or my_pub_ip == "127.0.0.1" then
                local target_ip = (p.local_ip == my_local_ip) and "127.0.0.1" or p.local_ip
                print(string.format("[DEBUG-NET] Connecting to local peer %d at %s:%d", peer_id, target_ip, p.local_port))
                net.Connect(peer_id, target_ip, tonumber(p.local_port))
                p2p_established[peer_id] = true
            else
                print(string.format("[DEBUG-NET] Connecting to remote peer %d at %s:%d", peer_id, p.public_ip, p.public_port))
                net.Connect(peer_id, p.public_ip, tonumber(p.public_port))
            end
        end
    end

    local real_time_remaining = status_data.start_time - status_data.server_time
    local sync_start_time = sys_time.get_time_hires()

    print(string.format("[DEBUG-NET] Entering ICE Punch Handshake... (Time remaining: %.2fs)", real_time_remaining))

    if real_time_remaining > 0 then
        local ice_packet_size = ffi.sizeof("IcePunchPacket")
        local handshake_buffer = ffi.new("RxPacket[32]")
        local scratch_ice = ffi.new("IcePunchPacket")
        local p2p_heard = {}

        while (sys_time.get_time_hires() - sync_start_time) < real_time_remaining do
            for peer_id, active in pairs(active_peers) do
                if active and not p2p_established[peer_id] then
                    local ping_pkt = ffi.new("IcePunchPacket")
                    ping_pkt.session_token = session_token
                    ping_pkt.player_id = local_id
                    ping_pkt.is_ping = p2p_heard[peer_id] and 1 or 0
                    net.SendTo(ping_pkt, ice_packet_size, peer_id)
                end
            end

            local count = net.RecvAll(handshake_buffer, 32)
            for i = 0, count - 1 do
                local rx_pkt = handshake_buffer[i]
                if rx_pkt.len >= ice_packet_size then
                    ffi.copy(scratch_ice, rx_pkt.data, ice_packet_size)
                    if scratch_ice.session_token == session_token then
                        local sender = scratch_ice.player_id
                        p2p_heard[sender] = true
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
