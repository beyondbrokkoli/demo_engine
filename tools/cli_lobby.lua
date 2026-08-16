-- tools/cli_lobby.lua
local sys = require("tools.cli_sys")

local Lobby = {
    log_path = "logs/host.log",
    max_attempts = 50,
    poll_interval_ms = 200
}

function Lobby.clear_log()
    os.remove(Lobby.log_path)
end

function Lobby.get_latest_id()
    local last_id = nil
    local f = io.open(Lobby.log_path, "r")
    if f then
        for line in f:lines() do
            local lobby_id = line:match("LOBBY_ID:%s*(%S+)")
            if lobby_id then last_id = lobby_id end
        end
        f:close()
    end
    return last_id
end

function Lobby.await_id()
    print("[CLI] Awaiting Matchmaker LOBBY_ID...")
    local attempts = 0
    while attempts < Lobby.max_attempts do
        local id = Lobby.get_latest_id()
        if id then
            print("\n========================================")
            print(" >> ACTIVE LOBBY ID: " .. id)
            print("========================================\n")
            return id
        end
        sys.sleep_ms(Lobby.poll_interval_ms)
        attempts = attempts + 1
    end
    print("[CLI] Timed out waiting for LOBBY_ID. Check " .. Lobby.log_path .. " manually.")
end

return Lobby
