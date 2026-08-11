-- network/session/net_utils.lua
local http = require("network.session.http_client")
local matchmaker = require("network.session.matchmaker")
local ice = require("network.session.ice_handshake")

local NetUtils = {}

-- Maintained as a wrapper to preserve backward compatibility with netcode.lua
function NetUtils.get_local_ip()
    return http.get_local_ip()
end

function NetUtils.BootstrapNetworkTopology(local_port, my_local_ip, target_lobby_id, target_lobby_size)
    -- 1. HTTP Configuration & Topology Gathering
    local session_token, status_data, pub_ip, pub_port, actual_port = matchmaker.acquire_session(
        local_port, my_local_ip, target_lobby_id, target_lobby_size
    )

    -- 2. UDP Peer-to-Peer Resolution & Relay Fallback
    local local_id, p2p_established, active_peers = ice.punch_through(
        session_token, status_data, pub_ip, pub_port, my_local_ip, actual_port
    )

    print("[DEBUG-NET] Bootstrapper complete. Yielding control to FSM.")
    return session_token, local_id, p2p_established, active_peers, status_data
end

return NetUtils
