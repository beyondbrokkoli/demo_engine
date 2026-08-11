-- network/session/matchmaker.lua
local ffi = require("ffi")
local json_util = require("network.protocol.json_util")
local cfg_net = require("network.protocol.config_net")
local net = require("network.transport.network")
local sys_time = require("network.session.sys_time")
local http = require("network.session.http_client")

local M = {}

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

function M.acquire_session(local_port, my_local_ip, target_lobby_id, target_lobby_size)
    target_lobby_size = target_lobby_size or cfg_net.MAX_PLAYERS

    local actual_port = net.Host(local_port)
    if not actual_port then
        print(string.format("[FATAL] Failed to bind local UDP port %d. Is it already in use?", local_port))
        os.exit(1)
    end

    print(string.format("[DEBUG-NET] Local UDP socket successfully bound to port %d.", actual_port))
    print(string.format("[DEBUG-NET] Firing STUN Punch to %s:%d...", cfg_net.STUN_SERVER, cfg_net.STUN_PORT))

    local stun_ok, my_pub_ip, my_pub_port = net.StunPunch(cfg_net.STUN_SERVER, cfg_net.STUN_PORT)
    if not stun_ok then
        print("[DEBUG-NET] STUN Punch timeout/fail. Falling back to Local IP.")
        my_pub_ip, my_pub_port = my_local_ip, actual_port
    else
        print(string.format("[DEBUG-NET] STUN Success: %s:%d", tostring(my_pub_ip), my_pub_port))
    end

    local payload = json_util.encode({
        public_ip = my_pub_ip, public_port = my_pub_port,
        local_ip = my_local_ip, local_port = actual_port,
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
        local response = http.post(cfg_net.MATCHMAKER_URL .. "/host", payload, actual_port)

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
        local response = http.post(cfg_net.MATCHMAKER_URL .. "/join/" .. lobby_id, payload, actual_port)

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

    return session_token, status_data, my_pub_ip, my_pub_port, actual_port
end

return M
