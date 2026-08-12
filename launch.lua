-- launch.lua
local sys = require("tools.cli_sys")
local cmd_history = {}

local function get_latest_lobby_id()
    local last_id = nil
    local f = io.open("logs/host.log", "r")
    if f then
        for line in f:lines() do
            local lobby_id = line:match("LOBBY_ID:%s*(%S+)")
            if lobby_id then last_id = lobby_id end
        end
        f:close()
    end
    return last_id
end

local function read_line()
    local buf = ""
    local cursor = 0
    local hist_idx = #cmd_history + 1

    -- Decoupled redraw function to handle cursor offsets
    local function redraw()
        io.write("\r\27[Kweaver> " .. buf)
        if cursor < #buf then
            -- \r resets to col 1. 'weaver> ' is 8 chars.
            io.write("\r\27[" .. (8 + cursor) .. "C")
        end
        io.flush()
    end

    io.write("weaver> ")
    io.flush()

    while true do
        local c = ""

        -- Native character fetching
        if sys.target == "win" then
            local code = sys.getch()
            if code == 224 or code == 0 then
                local ext = sys.getch()
                c = (ext == 72) and "UP" or (ext == 80) and "DOWN"
                 or (ext == 75) and "LEFT" or (ext == 77) and "RIGHT" or "IGNORE"
            elseif code == 27 then c = "IGNORE"
            elseif code == 13 then c = "ENTER"
            elseif code == 8 or code == 127 then c = "BACKSPACE"
            elseif code == 9 then c = "TAB"
            elseif code == 3 then c = "CTRLC"
            else c = string.char(code) end
        else
            local char = io.read(1)
            if not char then c = "EOF"
            elseif char == "\n" or char == "\r" then c = "ENTER"
            elseif char == "\127" or char == "\8" then c = "BACKSPACE"
            elseif char == "\t" then c = "TAB"
            elseif char == "\3" then c = "CTRLC"
            elseif char == "\27" then
                local b = io.read(1)
                if b == "[" then
                    local d = io.read(1)
                    c = (d == "A") and "UP" or (d == "B") and "DOWN"
                     or (d == "C") and "RIGHT" or (d == "D") and "LEFT" or "IGNORE"
                else c = "IGNORE" end
            else c = char end
        end

        -- State Machine
        if c == "EOF" or c == "CTRLC" then
            return nil
        elseif c == "ENTER" then
            io.write("\n")
            buf = buf:gsub("\r", "")
            if buf ~= "" and cmd_history[#cmd_history] ~= buf then
                table.insert(cmd_history, buf)
            end
            return buf
        elseif c == "BACKSPACE" then
            if cursor > 0 then
                buf = buf:sub(1, cursor - 1) .. buf:sub(cursor + 1)
                cursor = cursor - 1
                redraw()
            end
        elseif c == "LEFT" then
            if cursor > 0 then
                cursor = cursor - 1
                redraw()
            end
        elseif c == "RIGHT" then
            if cursor < #buf then
                cursor = cursor + 1
                redraw()
            end
        elseif c == "UP" or c == "DOWN" then
            if c == "UP" and hist_idx > 1 then hist_idx = hist_idx - 1
            elseif c == "DOWN" and hist_idx < #cmd_history then hist_idx = hist_idx + 1
            elseif c == "DOWN" and hist_idx == #cmd_history then hist_idx = #cmd_history + 1 end

            buf = cmd_history[hist_idx] or ""
            cursor = #buf
            redraw()
        elseif c == "TAB" then
            -- host_headless injected here
            local cmds = {"swarm", "lab", "host", "host_headless", "client", "attach", "clean", "orphans", "exit", "quit", "status"}
            local is_second_word = buf:find(" ")

            if not is_second_word then
                local matches = {}
                for _, cmd in ipairs(cmds) do
                    if cmd:sub(1, #buf) == buf then table.insert(matches, cmd) end
                end
                if #matches == 1 then buf = matches[1] .. " " end
            else
                local cmd_str, args_str = buf:match("^(%S+)%s+(.*)$")
                local latest_id = get_latest_lobby_id()
                local partial = args_str:match("(%S*)$")

                if partial then
                    if #partial == 4 and partial:match("^[0-9a-fA-F]+$") then
                        buf = buf:sub(1, -(#partial + 1)) .. partial:upper() .. " "
                    elseif latest_id and latest_id:sub(1, #partial) == partial:upper() then
                        buf = buf:sub(1, -(#partial + 1)) .. latest_id .. " "
                    end
                end
            end
            cursor = #buf
            redraw()
        elseif c ~= "IGNORE" then
            buf = buf:sub(1, cursor) .. c .. buf:sub(cursor + 1)
            cursor = cursor + 1
            redraw()
        end
    end
end

local function await_lobby_id()
    print("[CLI] Awaiting Matchmaker LOBBY_ID...")
    local attempts = 0
    while attempts < 50 do
        local id = get_latest_lobby_id()
        if id then
            print("\n========================================")
            print(" >> ACTIVE LOBBY ID: " .. id)
            print("========================================\n")
            return id
        end
        sys.sleep_ms(100)
        attempts = attempts + 1
    end
    print("[CLI] Timed out waiting for LOBBY_ID. Check logs/host.log manually.")
end

local function main_loop()
    print("=======================================================")
    print(" Weaver CLI Orchestrator (Lua V2 - Raw Mode)")
    print(" Platform: " .. string.upper(sys.target))
    print("=======================================================\n")

    while true do
        local input = read_line()
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
                os.remove("logs/host.log")
            end

            local full_cmd = sys.launcher .. " " .. input
            print("[CLI] Executing: " .. full_cmd)
            sys.run_shell_cmd(full_cmd)

            if cmd == "swarm" or cmd == "lab" or cmd == "host" or cmd == "host_headless" then
                await_lobby_id()
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
