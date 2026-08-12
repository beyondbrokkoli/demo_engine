-- launch.lua
local sys = require("tools.cli_sys")
local lobby = require("tools.cli_lobby")
local readline = require("tools.cli_readline")

local function main_loop()
    print("=======================================================")
    print(" Weaver CLI Orchestrator (Lua V2 - Raw Mode)")
    print(" Platform: " .. string.upper(sys.target))
    print("=======================================================\n")

    while true do
        local input = readline.read()
        if not input then
            print("\n[CLI] EOF/Ctrl+C detected.")
            sys.check_orphans()
            break
        end

        local args = {}
        for w in input:gmatch("%S+") do table.insert(args, w) end
        local cmd = args[1]

        if cmd == "exit" or cmd == "quit" then
            sys.check_orphans()
            print("[CLI] Exiting Weaver Orchestrator. Goodbye!")
            break
        elseif cmd == "orphans" or cmd == "status" then
            sys.check_orphans()
        elseif cmd == "clean" then
            print("[CLI] Issuing sweep command...")
            sys.run_shell_cmd(sys.launcher .. " clean")
        elseif cmd == "swarm" or cmd == "lab" or cmd == "host" or cmd == "host_headless" or cmd == "client" or cmd == "attach" then
            if cmd == "swarm" or cmd == "lab" or cmd == "host" or cmd == "host_headless" then
                lobby.clear_log()
            end

            local full_cmd = sys.launcher .. " " .. input
            print("[CLI] Executing: " .. full_cmd)
            sys.run_shell_cmd(full_cmd)

            if cmd == "swarm" or cmd == "lab" or cmd == "host" or cmd == "host_headless" then
                lobby.await_id()
            end
        elseif cmd ~= nil and cmd ~= "" then
            print("[CLI] Unknown command: " .. cmd)
        end
    end
end

sys.set_raw_mode(true)
local status, err = pcall(main_loop)
sys.set_raw_mode(false)

if not status then
    print("\n[FATAL ERROR] " .. tostring(err))
end
