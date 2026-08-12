-- runtime/boot/main.lua
local EngineAPI = require("runtime.boot.engine_api")
local setup_state = require("runtime.boot.main_setup")
local main_loop = require("runtime.boot.main_loop")

local function main()
    -- 1. Run initialization & retrieve payload with state and dependencies
    local deps = setup_state(arg)

    -- 2. Execute the primary runtime multiplexing loop
    main_loop.run(deps)

    -- 3. Phase Gate Teardown using payload references
    deps.Teardown.execute_phase_gate({
        TenantRegistry = deps.TenantRegistry,
        WindowAPI = deps.WindowAPI,
        EngineAPI = deps.EngineAPI,
        vk_rt = deps.vk_rt,
        cfg_gfx = deps.cfg_gfx,
        desc = deps.desc,
        memory = deps.memory,
        engine_ctx = deps.engine_ctx,
        net = deps.net_driver,
        sys_sleep = sys_sleep
    })
end

main()
EngineAPI.mark_finished()
