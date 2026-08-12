-- runtime/boot/main_setup.lua
require("runtime.boot.path_weaver")
io.stdout:setvbuf("no")

local ffi = require("ffi")
local core_abi = require("runtime.boot.core_abi")
local sys_time = require("network.session.sys_time")
local cli_args = require("tools.cli_args")

require("ssot.type_math")
require("ssot.type_render")
require("ssot.ctx_types")

local cfg_gfx = require("ssot.config_gfx")
local cfg_sim = require("ssot.config_sim")

-- [THE LOCAL CANVAS] 3MB struct for Vulkan and Raycasting (Ignored by Network)
local total_grid_cells = cfg_sim.world.map_width * cfg_sim.world.map_height
ffi.cdef(string.format([[
    typedef struct {
        uint16_t terrain[8][%d];
        int32_t elevation[8][%d];
    } VisualCanvas;
]], total_grid_cells, total_grid_cells))

local WindowAPI = require("runtime.boot.window_api")
local EngineAPI = require("runtime.boot.engine_api")
local net_driver = require("network.session.netcode")

local app_ctx = { cfg_gfx = cfg_gfx, cfg_sim = cfg_sim }

local math = require("math")
local vmath = require("runtime.services.math.vmath")
local seq = require("runtime.presentation.graphics.sequence").init(app_ctx)
local render_queue = require("runtime.presentation.translation.render_queue").init(app_ctx)
local Game = require("runtime.simulation.game_state").init(app_ctx)
local Raycast = require("runtime.simulation.raycast")
local Fixed = require("runtime.services.math.fixed_math")
local TenantRegistry = require("runtime.services.tenants.tenant_registry")
local graphics_mod = require("runtime.presentation.graphics.graphics_pipeline")
local manifest = require("runtime.presentation.translation.pipeline_manifest")
local Teardown = require("runtime.shutdown.teardown")

-- [SHATTER CHUNKS]
local Boot = require("runtime.boot.weaver_boot")
local VRAM = require("runtime.services.gpu.weaver_vram")
local Lifecycle = require("runtime.services.tenants.tenant_lifecycle")
local memory = require("runtime.services.memory.memory")
local camera_mod = require("runtime.simulation.camera")

local function init_state(arg)
    local parsed = cli_args.parse(arg)

    -- Force port 0 for OS ephemeral assignment
    local local_port = 0
    math.randomseed(os.time() + tonumber(tostring({}):sub(8), 16))

    local ctx = {
        total_tiles = cfg_sim.world.map_width * cfg_sim.world.map_height,
        ssot_render_ptr = Game.InitState()
    }

    local net_engine = net_driver.init(
        local_port,
        parsed.lobby_id,
        parsed.size,
        ctx.ssot_render_ptr,
        Game.GetStateSize()
    )

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

    local visual_canvas = ffi.new("VisualCanvas")
    local visual_canvas_size = ffi.sizeof("VisualCanvas")

    print("[NET] Visual Scene loaded. Cameras unlocked.")

    -- Package and export everything the main loop and teardown phases need
    return {
        ffi = ffi,
        math = math,
        sys_time = sys_time,
        EngineAPI = EngineAPI,
        WindowAPI = WindowAPI,
        net_driver = net_driver,
        TenantRegistry = TenantRegistry,
        Raycast = Raycast,
        Lifecycle = Lifecycle,
        camera_mod = camera_mod,
        render_queue = render_queue,
        Teardown = Teardown,

        ctx = ctx,
        net_engine = net_engine,
        engine_ctx = engine_ctx,
        vk_rt = vk_rt,
        desc = desc,
        manifest = manifest,
        cfg_gfx = cfg_gfx,
        memory = memory,
        vram_template = vram_template,
        visual_canvas = visual_canvas,
        visual_canvas_size = visual_canvas_size
    }
end

return init_state
