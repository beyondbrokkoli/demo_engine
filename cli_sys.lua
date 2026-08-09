-- cli_sys.lua
local ffi = require("ffi")
local Sys = {}

Sys.target = arg[1]
if Sys.target ~= "linux" and Sys.target ~= "win" then
    print("[FATAL] Usage: luajit launch.lua <linux|win>")
    os.exit(1)
end

Sys.launcher = Sys.target == "linux" and "./launch.sh" or "launch.bat"

if Sys.target == "win" then
    ffi.cdef[[
        int _getch(void);
        void Sleep(uint32_t dwMilliseconds);
    ]]
else
    ffi.cdef[[
        int usleep(unsigned int usec);
    ]]
end

function Sys.sleep_ms(ms)
    if Sys.target == "win" then
        ffi.C.Sleep(ms)
    else
        ffi.C.usleep(ms * 1000)
    end
end

function Sys.check_orphans()
    print("\n[ORPHANS] Scanning for active Weaver nodes...")
    local count = 0
    local cmd = Sys.target == "linux" 
        and "pgrep -a -f 'boot.*\\.elf'" 
        or 'tasklist 2>nul | findstr /I "boot.exe boot_headless.exe"'

    local f = io.popen(cmd)
    if f then
        for line in f:lines() do
            print("  |- " .. (Sys.target == "win" and line:gsub("%s+", " ") or line))
            count = count + 1
        end
        f:close()
    end

    if count == 0 then
        print("  |- No orphaned Weaver processes found. Clean slate.")
    else
        print("  |- Found " .. count .. " running node(s). (Type 'clean' to sweep them)")
    end
    print("")
end

function Sys.run_shell_cmd(cmd)
    if Sys.target == "linux" then os.execute("stty sane") end
    os.execute(cmd)
    if Sys.target == "linux" then os.execute("stty cbreak -echo") end
end

function Sys.set_raw_mode(enable)
    if Sys.target == "linux" then
        if enable then
            os.execute("stty sane")
            os.execute("stty cbreak -echo")
        else
            os.execute("stty sane")
        end
    end
end

-- Expose _getch for the Windows read_line loop
Sys.getch = Sys.target == "win" and ffi.C._getch or nil

return Sys
