-- network/session/net_utils.lua
local ffi = require("ffi")
local json_util = require("network.protocol.json_util")
local cfg_net = require("network.protocol.config_net")
local net = require("network.transport.network")

-- Injecting the refactored dependencies
local sys_time = require("network.session.sys_time")
local http = require("network.session.http_client")

local NetUtils = {}

-- Maintained as a wrapper to preserve backward compatibility with netcode.lua
function NetUtils.get_local_ip()
    return http.get_local_ip()
end

local function extract_true_64bit_token(json_string)
    local token_digits = json_string:match('"session_token"%s*:%s*(%d+)')
    assert(token_digits, "FATAL: Could not locate session_token digits in JSON payload")
    local val = ffi.cast("uint64_t", 0)
    for i = 1, #token_digits do
        local byte = string.byte(token_digits, i)
        if byte >= 48 and byte <= 57 then
            val = (val * 10) + (byte - 48)
        else
            break
        end
    end
    return val
end

function NetUtils.BootstrapNetworkTopology(local_port, my_local_ip, target_lobby_id, target_lobby_size)
    print(string.format("[DEBUG-NET] Bootstrapping Port: %d | Local IP: %s", local_port, tostring(my_local_ip)))

    target_lobby_size = target_lobby_size or cfg_net.MAX_PLAYERS

    local actual_port = net.Host(local_port)
    if not actual_port then
        print(string.format("[FATAL] Failed to bind local UDP port %d. Is it already in use?", local_port))
        os.exit(1)
    end

    local_port = actual_port
    print(string.format("[DEBUG-NET] Local UDP socket successfully bound to port %d.", local_port))

    print(string.format("[DEBUG-NET] Firing STUN Punch to %s:%d...", cfg_net.STUN_SERVER, cfg_net.STUN_PORT))
    local stun_ok, my_pub_ip, my_pub_port = net.StunPunch(cfg_net.STUN_SERVER, cfg_net.STUN_PORT)
    if not stun_ok then
        print("[DEBUG-NET] STUN Punch timeout/fail. Falling back to Local IP.")
        my_pub_ip, my_pub_port = my_local_ip, local_port
    else
        print(string.format("[DEBUG-NET] STUN Success: %s:%d", tostring(my_pub_ip), my_pub_port))
    end

    local payload = json_util.encode({
        public_ip = my_pub_ip, public_port = my_pub_port,
        local_ip = my_local_ip, local_port = local_port,
        target_size = target_lobby_size
    })

    print(string.format("[DEBUG-NET] Payload built (Target Size: %d) targeting URL: %s", target_lobby_size, cfg_net.MATCHMAKER_URL))

    local lobby_id = target_lobby_id
    if type(lobby_id) == "string" and lobby_id:lower() == "host" then
        lobby_id = nil
    end

    local session_token = nil

    if lobby_id == nil then
        print("[DEBUG-NET] Requesting new Lobby ID from Matchmaker...")
        local response = http.post(cfg_net.MATCHMAKER_URL .. "/host", payload, local_port)

        if not response or response == "" then
            print("[FATAL] Matchmaker unreachable (empty response).")
            os.exit(1)
        end

        local decoded = json_util.decode(response)
        if not decoded or not decoded.lobby_id then
            print("[FATAL] Matchmaker returned invalid JSON or missing lobby_id.")
            os.exit(1)
        end

        lobby_id = decoded.lobby_id
        print("LOBBY_ID: " .. lobby_id)
    else
        print("[DEBUG-NET] Joining existing Lobby ID: " .. tostring(lobby_id))
        local response = http.post(cfg_net.MATCHMAKER_URL .. "/join/" .. lobby_id, payload, local_port)

        if not response or response == "" then
            print(string.format("[FATAL] Failed to join lobby '%s'. Matchmaker unreachable.", lobby_id))
            os.exit(1)
        end

        local decoded = json_util.decode(response)
        if decoded and decoded.detail then
            if type(decoded.detail) == "string" then
                print(string.format("[FATAL] Matchmaker rejected join: %s", decoded.detail))
            else
                print("[FATAL] Matchmaker rejected join: Unprocessable Entity (Invalid Payload)")
            end
            os.exit(1)
        end
    end

    print(string.format("[DEBUG-NET] Entering Polling Loop for Lobby %s to lock...", lobby_id))
    local status_data = nil
    local poll_count = 0

    while true do
        local raw_res = http.get(cfg_net.MATCHMAKER_URL .. "/status/" .. lobby_id)
        poll_count = poll_count + 1

        if raw_res and raw_res ~= "" then
            status_data = json_util.decode(raw_res)

            if not status_data then
                print(string.format("[DEBUG-NET] Poll #%d | Warning: Failed to parse Matchmaker JSON.", poll_count))
            elseif status_data.detail then
                print(string.format("[FATAL] Matchmaker polling failed: %s",
                    type(status_data.detail) == "string" and status_data.detail or "Invalid Query"))
                os.exit(1)
            else
                if status_data.target_size then
                    target_lobby_size = status_data.target_size
                end

                if poll_count % 4 == 0 then
                    local current_players = status_data.players and #status_data.players or 0
                    print(string.format("[DEBUG-NET] Poll #%d | Status: %s | Players connected: %d/%d",
                        poll_count, tostring(status_data.status), current_players, target_lobby_size))
                end

                if status_data.status == "locked" then
                    print("[DEBUG-NET] Lobby Locked! Extracting Session Token...")
                    session_token = extract_true_64bit_token(raw_res)
                    break
                end
            end
        else
            print(string.format("[DEBUG-NET] Poll #%d | HTTP GET failed. Matchmaker offline?", poll_count))
        end

        sys_time.sleep(500)
    end

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

    print("[DEBUG-NET] Bootstrapper complete. Yielding control to FSM.")
    return session_token, local_id, p2p_established, active_peers, status_data
end

return NetUtils
