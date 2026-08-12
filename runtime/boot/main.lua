-- runtime/boot/main.lua
require("runtime.boot.path_weaver")
io.stdout:setvbuf("no")

local ffi = require("ffi")
local core_abi = require("core_abi")
local sys_time = require("network.session.sys_time") -- [ADDED] UNIFIED TIMER

require("type_math")
require("type_render")
require("ctx_types")

local cfg_gfx = require("config_gfx")
local cfg_sim = require("config_sim")

-- [THE LOCAL CANVAS] 3MB struct for Vulkan and Raycasting (Ignored by Network)
local total_grid_cells = cfg_sim.world.map_width * cfg_sim.world.map_height
ffi.cdef(string.format([[
    typedef struct {
        uint16_t terrain[8][%d];
        int32_t elevation[8][%d];
    } VisualCanvas;
]], total_grid_cells, total_grid_cells))

local WindowAPI = require("window_api")
local EngineAPI = require("engine_api")
local net_driver = require("netcode")

local app_ctx = { cfg_gfx = cfg_gfx, cfg_sim = cfg_sim }

local math = require("math")
local vmath = require("vmath")
local seq = require("sequence").init(app_ctx)
local render_queue = require("render_queue").init(app_ctx)
local Game = require("game_state").init(app_ctx)
local Raycast = require("raycast")
local Fixed = require("fixed_math")
local TenantRegistry = require("tenant_registry")
local graphics_mod = require("graphics_pipeline")
local manifest = require("pipeline_manifest")
local Teardown = require("teardown")

-- [SHATTER CHUNKS]
local Boot = require("weaver_boot")
local VRAM = require("weaver_vram")
local Lifecycle = require("tenant_lifecycle")
local memory = require("memory")
local camera_mod = require("camera")

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

local function main()
    -- 1. RELAXED FLOODGATE (1 or 2 arguments allowed)
    if not arg[1] or arg[3] then
        print("[FATAL] Invalid argument count. Usage: <exe> <lobby_id_or_'host'> [target_size]")
        os.exit(1)
    end

    local raw_lobby = arg[1]
    local raw_size = arg[2]
    local is_host = (raw_lobby:lower() == "host")

    -- 2. VALIDATE LOBBY ID (Exactly 4 uppercase hex chars, unless 'host')
    if not is_host then
        if #raw_lobby ~= 4 or not raw_lobby:match("^[0-9A-F]+$") then
            print(string.format("[FATAL] Invalid Lobby ID '%s'. Must be exactly 4 uppercase hex characters (e.g., B31F) or 'host'.", raw_lobby))
            os.exit(1)
        end
    end

    -- 3. VALIDATE TARGET SIZE
    local target_lobby_size = nil
    if raw_size then
        target_lobby_size = tonumber(raw_size)
        if not target_lobby_size then
            print(string.format("[FATAL] Invalid target size '%s'. Must be a numeric value.", raw_size))
            os.exit(1)
        end
    elseif is_host then
        -- Host must dictate the lobby size; clients get it from the matchmaker.
        print("[FATAL] Host must specify target size. Usage: <exe> host <size>")
        os.exit(1)
    end

    local target_lobby_id = is_host and nil or raw_lobby

    -- Force port 0 for OS ephemeral assignment
    local local_port = 0
    math.randomseed(os.time() + tonumber(tostring({}):sub(8), 16))

    local ctx = {
        total_tiles = cfg_sim.world.map_width * cfg_sim.world.map_height,
        ssot_render_ptr = Game.InitState()
    }

    local net_engine = net_driver.init(local_port, target_lobby_id, target_lobby_size, ctx.ssot_render_ptr, Game.GetStateSize())

    -- [CHUNKED BOOT]
    local engine_ctx = Boot.run_sequence(seq.boot, WindowAPI, sys_sleep)

    local vk_rt = engine_ctx.vk_runtime
    local sc = engine_ctx.sc_state
    local desc = engine_ctx.desc_state
    local gfx = engine_ctx.gfx_state
    local sync = engine_ctx.sync_state

    print("[LUA IO] Host Bedrock Online. Booting Multiplexer Tenants...")
    EngineAPI.setup_transfer(vk_rt.tIndex or 0)
    EngineAPI.start_thread()

    TenantRegistry.boot_tenant(vk_rt, 0, cfg_gfx.win.w, cfg_gfx.win.h, cfg_gfx.cfg.frame_slots)
    TenantRegistry.active[0].gfx = graphics_mod.Init(
        vk_rt.vk, vk_rt, cfg_gfx.win.w, cfg_gfx.win.h,
        desc.pipelineLayout, TenantRegistry.active[0].sc.format, manifest.graphics
    )
    TenantRegistry.boot_tenant(vk_rt, 1, cfg_gfx.win.w, cfg_gfx.win.h, cfg_gfx.cfg.frame_slots)
    TenantRegistry.active[1].gfx = graphics_mod.Init(
        vk_rt.vk, vk_rt, cfg_gfx.win.w, cfg_gfx.win.h,
        desc.pipelineLayout, TenantRegistry.active[1].sc.format, manifest.graphics
    )
    TenantRegistry.boot_tenant(vk_rt, 2, cfg_gfx.win.w, cfg_gfx.win.h, cfg_gfx.cfg.frame_slots)
    TenantRegistry.active[2].gfx = graphics_mod.Init(
        vk_rt.vk, vk_rt, cfg_gfx.win.w, cfg_gfx.win.h,
        desc.pipelineLayout, TenantRegistry.active[2].sc.format, manifest.graphics
    )
    TenantRegistry.boot_tenant(vk_rt, 3, cfg_gfx.win.w, cfg_gfx.win.h, cfg_gfx.cfg.frame_slots)
    TenantRegistry.active[3].gfx = graphics_mod.Init(
        vk_rt.vk, vk_rt, cfg_gfx.win.w, cfg_gfx.win.h,
        desc.pipelineLayout, TenantRegistry.active[3].sc.format, manifest.graphics
    )

    -- [CHUNKED VRAM]
    local vram_template = VRAM.init_static_buffers(memory, cfg_sim, ctx.total_tiles)

    local MAX_DRAW_COMMANDS = 1024
    local RENDER_QUEUE_SIZE = 120
    ctx.render_queues = ffi.new("DrawCommand[?]", MAX_DRAW_COMMANDS * RENDER_QUEUE_SIZE * 2)

    local total_time = 0.0
    local master_ptr = ffi.cast("float*", memory.Mapped["MASTER_GPU_BLOCK"])
    local active_render_mode = cfg_gfx.mode.dual
    local prev_mouse_left = { [0] = false, [1] = false, [2] = false, [3] = false }
    local last_time = sys_time.get_time_hires()

    local visual_canvas = ffi.new("VisualCanvas")
    local visual_canvas_size = ffi.sizeof("VisualCanvas")

    print("[NET] Visual Scene loaded. Cameras unlocked.")

    while EngineAPI.is_running() do
        local current_time = sys_time.get_time_hires()
        local frame_time = math.max(0.001, math.min(current_time - last_time, 0.25))
        last_time = current_time

        local sim_state = net_driver.pump_network(net_engine, frame_time)

        -- [THE TRANSLATION BRIDGE]
        -- 1. Wipe the visual canvas clean (Takes ~0.1ms via FFI memset)
        ffi.fill(visual_canvas, visual_canvas_size, 0)

        -- 2. Paint the 24KB sparse simulation state onto the 3MB visual canvas
        local state = ctx.ssot_render_ptr
        local count = state.modification_count

        -- If the buffer wrapped, the oldest entry is at head_idx. Otherwise, it's at 0.
        local start_idx = (count < 2048) and 0 or state.head_idx

        for i = 0, count - 1 do
            local actual_idx = (start_idx + i) % 2048
            local mod = state.tiles[actual_idx]

            -- We paint everything to Layer 0. The renderer and raycaster don't care about network player layers.
            visual_canvas.terrain[0][mod.tile_idx] = mod.terrain_type
            visual_canvas.elevation[0][mod.tile_idx] = mod.elevation
        end

        local active_win_id = ffi.C.vx_input_get_active_window()

        for win_id in pairs(TenantRegistry.active) do
            if win_id ~= active_win_id then prev_mouse_left[win_id] = false end
        end

        if active_win_id >= 0 and TenantRegistry.active[active_win_id] then
            local tenant = TenantRegistry.active[active_win_id]
            local is_down = WindowAPI.is_mouse_down(active_win_id, 0)

            if is_down and not prev_mouse_left[active_win_id] then
                local click_x, click_y = WindowAPI.get_click_pos(active_win_id)

                -- [POINTER SWAP] Pass visual_canvas instead of ssot_render_ptr
                local clicked_idx = Raycast.matrix_raycast_terrain(
                    click_x, click_y, tenant.width, tenant.height,
                    tenant.inv_vp, visual_canvas, 0
                )
                if clicked_idx ~= 65535 then
                    net_driver.inject_local_command(net_engine, 1, clicked_idx)
                end
            end
            prev_mouse_left[active_win_id] = is_down
        end

        total_time = total_time + frame_time

        for win_id, tenant in pairs(TenantRegistry.active) do
            local skip_render = Lifecycle.process_state_machine(
                win_id, tenant, WindowAPI, EngineAPI, vk_rt, desc, manifest, cfg_gfx, TenantRegistry
            )

            if skip_render then goto continue_tenant end

            if win_id == active_win_id then
                local mouse_x, mouse_y = WindowAPI.get_mouse_pos(win_id)
                camera_mod.update(tenant.cam, frame_time, mouse_x, mouse_y, tenant.width, tenant.height, win_id)
            end

            camera_mod.get_matrices(tenant.cam, tenant.width, tenant.height, tenant.pc.viewProj, tenant.inv_vp)

            local write_idx = EngineAPI.acquire_render_packet(win_id)
            if write_idx == -1 then goto continue_tenant end

            tenant.pc.total_time = total_time
            tenant.pc.dt = frame_time

            -- [POINTER SWAP] Pass visual_canvas instead of ssot_render_ptr
            render_queue.PackFrame(
                tenant, write_idx, tenant.pc, visual_canvas, vram_template,
                ctx.render_queues, active_render_mode, master_ptr, memory,
                tenant.gfx, desc, tenant.sc, ctx.total_tiles, 0
            )

            EngineAPI.commit_render_packet(win_id, write_idx)

            ::continue_tenant::
        end
        sys_time.sleep(1)
    end

    Teardown.execute_phase_gate({
        TenantRegistry = TenantRegistry, WindowAPI = WindowAPI, EngineAPI = EngineAPI,
        vk_rt = vk_rt, cfg_gfx = cfg_gfx, desc = desc, memory = memory, engine_ctx = engine_ctx,
        net = net_driver, sys_sleep = sys_sleep
    })
end

main()
EngineAPI.mark_finished()
