local ffi = require("ffi")
local target = arg[1]

if target ~= "linux" and target ~= "win" then
    print("[FATAL] Usage: luajit launch.lua <linux|win>")
    os.exit(1)
end

local launcher = target == "linux" and "./launch.sh" or "launch.bat"

if target == "win" then
    ffi.cdef[[
        int _getch(void);
        void Sleep(uint32_t dwMilliseconds);
    ]]
else
    ffi.cdef[[
        int usleep(unsigned int usec);
    ]]
end

local function sleep_ms(ms)
    if target == "win" then
        ffi.C.Sleep(ms)
    else
        ffi.C.usleep(ms * 1000)
    end
end

local function check_orphans()
    print("\n[ORPHANS] Scanning for active Weaver nodes...")
    local count = 0

    if target == "linux" then
        local f = io.popen("pgrep -a -f 'boot.*\\.elf'")
        if f then
            for line in f:lines() do
                print("  |- " .. line)
                count = count + 1
            end
            f:close()
        end
    else
        local f = io.popen('tasklist 2>nul | findstr /I "boot.exe boot_headless.exe"')
        if f then
            for line in f:lines() do
                print("  |- " .. line:gsub("%s+", " "))
                count = count + 1
            end
            f:close()
        end
    end

    if count == 0 then
        print("  |- No orphaned Weaver processes found. Clean slate.")
    else
        print("  |- Found " .. count .. " running node(s). (Type 'clean' to sweep them)")
    end
    print("")
end

-- RAW INPUT & HISTORY BUFFERING
local cmd_history = {}
local function get_latest_lobby_id()
    local last_id = nil
    -- Non-blocking read of the log to find the most recent ID
    local f = io.open("logs/host.log", "r")
    if f then
        for line in f:lines() do
            local lobby_id = line:match("LOBBY_ID:%s*(%S+)")
            if lobby_id then
                last_id = lobby_id
            end
        end
        f:close()
    end
    return last_id
end
local function read_line()
    local buf = ""
    local hist_idx = #cmd_history + 1

    io.write("weaver> ")
    io.flush()

    while true do
        local c = ""

        if target == "win" then
            local code = ffi.C._getch()
            if code == 224 or code == 0 then
                local ext = ffi.C._getch()
                if ext == 72 then c = "UP"
                elseif ext == 80 then c = "DOWN"
                else c = "IGNORE" end
            elseif code == 27 then
                local bracket = ffi.C._getch()
                if bracket == 91 then
                    local dir = ffi.C._getch()
                    if dir == 65 then c = "UP"
                    elseif dir == 66 then c = "DOWN"
                    elseif dir == 67 or dir == 68 then c = "IGNORE"
                    else c = "IGNORE" end
                else c = "IGNORE" end
            elseif code == 13 then c = "ENTER"
            elseif code == 8 or code == 127 then c = "BACKSPACE"
            elseif code == 9 then c = "TAB" -- NEW: Catch Windows TAB
            elseif code == 3 then c = "CTRLC"
            else c = string.char(code) end
        else
            local char = io.read(1)
            if not char then c = "EOF"
            elseif char == "\n" or char == "\r" then c = "ENTER"
            elseif char == "\127" or char == "\8" then c = "BACKSPACE"
            elseif char == "\t" then c = "TAB" -- NEW: Catch Linux TAB
            elseif char == "\3" then c = "CTRLC"
            elseif char == "\27" then
                local b = io.read(1)
                if b == "[" then
                    local d = io.read(1)
                    if d == "A" then c = "UP"
                    elseif d == "B" then c = "DOWN"
                    elseif d == "C" or d == "D" then c = "IGNORE"
                    else c = "IGNORE" end
                else c = "IGNORE" end
            else c = char end
        end

        -- State Machine for our intercepted inputs
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
            if #buf > 0 then
                buf = buf:sub(1, -2)
                io.write("\r\27[Kweaver> " .. buf)
                io.flush()
            end
        elseif c == "TAB" then
            -- NEW: Smart Autocomplete Logic
            local cmds = {"swarm", "lab", "host", "client", "attach", "clean", "orphans", "exit", "quit", "status"}
            local is_second_word = buf:find(" ")

            if not is_second_word then
                -- Complete base commands
                local matches = {}
                for _, cmd in ipairs(cmds) do
                    if cmd:sub(1, #buf) == buf then
                        table.insert(matches, cmd)
                    end
                end
                if #matches == 1 then
                    buf = matches[1] .. " " -- Auto-append space
                end
            else
                -- Complete Arguments (Lobby ID)
                -- Extract the command and whatever follows it
                local cmd, args_str = buf:match("^(%S+)%s+(.*)$")
                local latest_id = get_latest_lobby_id()

                if latest_id then
                    if cmd == "client" then
                        -- client expects: <lobby_id>
                        if latest_id:sub(1, #args_str) == args_str then
                            buf = cmd .. " " .. latest_id
                        end
                    elseif cmd == "attach" then
                        -- attach expects: <bots> <lobby_id>
                        -- Look for: a number/string, one or more spaces, and an optional partial ID
                        local bots, space, partial_id = args_str:match("^(%S+)(%s+)(.*)$")

                        -- Only autocomplete if they have typed the bots AND a space
                        if bots and space then
                            if latest_id:sub(1, #partial_id) == partial_id then
                                buf = cmd .. " " .. bots .. space .. latest_id
                            end
                        end
                    end
                end
            end

            -- Redraw line with autocomplete
            io.write("\r\27[Kweaver> " .. buf)
            io.flush()
        elseif c == "UP" then
            if hist_idx > 1 then
                hist_idx = hist_idx - 1
                buf = cmd_history[hist_idx]
                io.write("\r\27[Kweaver> " .. buf)
                io.flush()
            end
        elseif c == "DOWN" then
            if hist_idx < #cmd_history then
                hist_idx = hist_idx + 1
                buf = cmd_history[hist_idx]
                io.write("\r\27[Kweaver> " .. buf)
                io.flush()
            elseif hist_idx == #cmd_history then
                hist_idx = #cmd_history + 1
                buf = ""
                io.write("\r\27[Kweaver> " .. buf)
                io.flush()
            end
        elseif c ~= "IGNORE" then
            buf = buf .. c
            io.write(c)
            io.flush()
        end
    end
end

local function await_lobby_id()
    print("[CLI] Awaiting Matchmaker LOBBY_ID...")
    local max_attempts = 50 -- 5 seconds (50 * 100ms)
    local attempts = 0

    while attempts < max_attempts do
        local f = io.open("logs/host.log", "r")
        if f then
            for line in f:lines() do
                -- Look for the string and grab the ID following it
                local lobby_id = line:match("LOBBY_ID:%s*(%S+)")
                if lobby_id then
                    f:close()
                    print("\n========================================")
                    print(" >> ACTIVE LOBBY ID: " .. lobby_id)
                    print("========================================\n")
                    return lobby_id
                end
            end
            f:close()
        end
        sleep_ms(100)
        attempts = attempts + 1
    end
    print("[CLI] Timed out waiting for LOBBY_ID. Check logs/host.log manually.")
end

-- Safely wrap os.execute so child processes don't inherit the raw terminal state
local function run_shell_cmd(cmd)
    if target == "linux" then os.execute("stty sane") end -- Restore cooked mode
    os.execute(cmd)
    if target == "linux" then os.execute("stty cbreak -echo") end -- Re-enter raw mode
end

-- ORCHESTRATOR LOOP
local function main_loop()
    print("=======================================================")
    print(" Weaver CLI Orchestrator (Lua V2 - Raw Mode)")
    print(" Platform: " .. string.upper(target))
    print(" Commands: swarm, lab, host, client, attach")
    print("           clean, orphans, exit")
    print("=======================================================\n")

    while true do
        local input = read_line()

        if not input then
            print("\n[CLI] EOF/Ctrl+C detected.")
            check_orphans()
            break
        end

        local args = {}
        for w in input:gmatch("%S+") do table.insert(args, w) end
        local cmd = args[1]

        if cmd == "exit" or cmd == "quit" then
            check_orphans()
            print("[CLI] Exiting Weaver Orchestrator. Goodbye!")
            break
        elseif cmd == "orphans" or cmd == "status" then
            check_orphans()
        elseif cmd == "clean" then
            print("[CLI] Issuing sweep command...")
            run_shell_cmd(launcher .. " clean")
        elseif cmd == "swarm" or cmd == "lab" or cmd == "host" or cmd == "client" or cmd == "attach" then
            -- Delete old log to ensure we don't fetch a stale Lobby ID
            if cmd == "swarm" or cmd == "lab" or cmd == "host" then
                os.remove("logs/host.log")
            end

            local full_cmd = launcher .. " " .. input
            print("[CLI] Executing: " .. full_cmd)
            run_shell_cmd(full_cmd)

            -- Automatically catch and print the newly generated Lobby ID
            if cmd == "swarm" or cmd == "lab" or cmd == "host" then
                await_lobby_id()
            end
        elseif cmd ~= nil and cmd ~= "" then
            print("[CLI] Unknown command: " .. cmd)
        end
    end
end

-- Safely execute the loop.
if target == "linux" then 
    os.execute("stty sane") -- FIX: Heal terminal state first
    os.execute("stty cbreak -echo") 
end
local status, err = pcall(main_loop)
if target == "linux" then os.execute("stty sane") end

if not status then
    print("\n[FATAL ERROR] " .. tostring(err))
end
