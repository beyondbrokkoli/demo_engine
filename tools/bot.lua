require("runtime.boot.path_weaver")
-- tools/bot.lua
io.stdout:setvbuf("no")

local ffi = require("ffi")
local bit = require("bit") -- [ADDED] Required to pack the chess coordinates

-- 1. BEDROCK TIMING SUBSYSTEM
ffi.cdef[[
void Sleep(uint32_t dwMilliseconds);
int usleep(uint32_t usec);
int QueryPerformanceCounter(int64_t *lpPerformanceCount);
int QueryPerformanceFrequency(int64_t *lpFrequency);
typedef struct { long tv_sec; long tv_nsec; } timespec;
int clock_gettime(int clk_id, timespec *tp);
]]

local function sys_sleep(ms)
    if jit.os == "Windows" then ffi.C.Sleep(ms) else ffi.C.usleep(ms * 1000) end
end

local get_time_hires
if jit.os == "Windows" then
    local freq = ffi.new("int64_t[1]")
    ffi.C.QueryPerformanceFrequency(freq)
    local inv_freq = 1.0 / tonumber(freq[0])
    get_time_hires = function()
        local count = ffi.new("int64_t[1]")
        ffi.C.QueryPerformanceCounter(count)
        return tonumber(count[0]) * inv_freq
    end
else
    local CLOCK_MONOTONIC = 1
    get_time_hires = function()
        local ts = ffi.new("timespec")
        ffi.C.clock_gettime(CLOCK_MONOTONIC, ts)
        return tonumber(ts.tv_sec) + (tonumber(ts.tv_nsec) * 1e-9)
    end
end

-- 2. SPARSE SIMULATION MEMORY
local cfg_sim = require("config_sim")
local app_ctx = { cfg_sim = cfg_sim }
local Game = require("game_state").init(app_ctx)

-- 3. THE BOT ORCHESTRATOR
local net_driver = require("netcode")

local function main()
    local raw_lobby, raw_size
    if tonumber(arg[1]) and arg[2] then
        raw_lobby = arg[2]
        raw_size = arg[3]
    else
        raw_lobby = arg[1]
        raw_size = arg[2]
    end

    if not raw_lobby or not raw_size then
        print("[FATAL] Invalid boot arguments. Usage: <exe> <lobby_id_or_'host'> <target_size>")
        os.exit(1)
    end

    local target_lobby_id = (raw_lobby:lower() == "host") and nil or raw_lobby
    local target_lobby_size = tonumber(raw_size) or 8
    local local_port = 0
    math.randomseed(os.time() + tonumber(tostring({}):sub(8), 16))

    local state_ptr = Game.InitState()
    local state_size = Game.GetStateSize()

    print(string.format("[BOT:%d] Booting Headless Chaos Node (Target Size: %d)...", local_port, target_lobby_size))

    local net_engine = net_driver.init(local_port, target_lobby_id, target_lobby_size, state_ptr, state_size)

    local last_time = get_time_hires()
    local tick_count = 0

    while true do
        local current_time = get_time_hires()
        local frame_time = math.max(0.001, math.min(current_time - last_time, 0.25))
        last_time = current_time

        -- [INJECT CHAOS]
        if tick_count > 0 then
            -- CHANNEL 0: The Isometric Fuzzer
            -- Dropped the chance to 5% so it doesn't visually drown out the chess moves
            if math.random() > 0.95 then
                local random_idx = math.random(0, 65535)
                net_driver.inject_local_command(net_engine, 1, random_idx)
            end

            -- CHANNEL 1: The Chess Oracle Fuzzer
            -- Fires constantly. Out of ~4096 combinations, roughly 20-30 are legal at any time.
            -- This will hit a successful, legal move roughly once every 1-2 seconds.
            if math.random() > 0.1 then
                local from_idx = math.random(0, 63)
                local to_idx = math.random(0, 63)

                -- Pack coordinates: (from_idx << 8) | to_idx
                local packed_move = bit.bor(bit.lshift(from_idx, 8), to_idx)

                -- Opcode 2 routes straight to the Chess Domain
                net_driver.inject_local_command(net_engine, 2, packed_move)
            end
        end

        net_driver.pump_network(net_engine, frame_time)

        tick_count = tick_count + 1
        if tick_count % 600 == 0 then
            print(string.format("[BOT:%d] Heartbeat - Sparse Mods Tracked: %d", local_port, state_ptr.modification_count))
        end

        sys_sleep(16)
    end
end

main()
