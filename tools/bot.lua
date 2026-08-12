-- tools/bot.lua
require("runtime.boot.path_weaver")
io.stdout:setvbuf("no")

local ffi = require("ffi")
local bit = require("bit")
local sys_time = require("network.session.sys_time")
local cli_args = require("tools.cli_args")

local cfg_sim = require("ssot.config_sim")
local app_ctx = { cfg_sim = cfg_sim }
local Game = require("runtime.simulation.game_state").init(app_ctx)

-- 3. THE BOT ORCHESTRATOR
local net_driver = require("network.session.netcode")

local function main()
    local parsed = cli_args.parse(arg)

    -- Force port 0 for OS ephemeral assignment
    local local_port = 0
    math.randomseed(os.time() + tonumber(tostring({}):sub(8), 16))

    local state_ptr = Game.InitState()
    local state_size = Game.GetStateSize()

    -- Format the size for the print statement (handles the nil case for clients)
    local display_size = parsed.size and tostring(parsed.size) or "Matchmaker-assigned"
    print(string.format("[BOT:%d] Booting Headless Chaos Node (Target Size: %s)...", local_port, display_size))

    local net_engine = net_driver.init(
        local_port,
        parsed.lobby_id,
        parsed.size,
        state_ptr,
        state_size
    )

    local last_time = sys_time.get_time_hires()
    local tick_count = 0

    while true do
        local current_time = sys_time.get_time_hires()
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

        sys_time.sleep(16)
    end
end

main()
