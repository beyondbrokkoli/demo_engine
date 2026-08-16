-- runtime/boot/main_setup.lua
require("runtime.boot.path_weaver")
io.stdout:setvbuf("no")

local ffi = require("ffi")
local core_abi = require("runtime.boot.core_abi")
local cli_args = require("tools.cli_args")

-- 1. Grab the SSoT factory and execute it to get the C definitions
local struct_specs, cdef_str = require("ssot.ctx_types")()

-- 2. Explicitly load the structs into the runtime FFI
ffi.cdef(cdef_str)

local cfg_gfx = require("ssot.config_gfx")
local cfg_sim = require("ssot.config_sim")

-- [THE LOCAL CANVAS] 3MB struct for Vulkan and Raycasting
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

local seq = require("runtime.presentation.graphics.sequence").init(app_ctx)
local render_queue = require("runtime.presentation.translation.render_queue").init(app_ctx)
local Game = require("runtime.simulation.game_state").init(app_ctx)
local TenantRegistry = require("runtime.services.tenants.tenant_registry")
local graphics_mod = require("runtime.presentation.graphics.graphics_pipeline")
local manifest = require("runtime.presentation.translation.pipeline_manifest")

-- [SHATTER CHUNKS]
local Boot = require("runtime.boot.weaver_boot")
local VRAM = require("runtime.services.gpu.weaver_vram")
local memory = require("runtime.services.memory.memory")

local function init_state(arg)
    local parsed = cli_args.parse(arg)
    local local_port = 0
    math.randomseed(os.time() + tonumber(tostring({}):sub(8), 16))

    local ctx = {
        total_tiles = cfg_sim.world.map_width * cfg_sim.world.map_height,
        ssot_render_ptr = Game.InitState()
    }

    local net_engine = net_driver.init(
        local_port, parsed.lobby_id, parsed.size, ctx.ssot_render_ptr, Game.GetStateSize()
    )

    local engine_ctx = Boot.run_sequence(seq.boot, WindowAPI, sys_sleep)
    local vk_rt = engine_ctx.vk_runtime
    local desc = engine_ctx.desc_state

    print("[LUA IO] Host Bedrock Online. Booting Multiplexer Tenants...")
    EngineAPI.setup_transfer(vk_rt.tIndex or 0)
    EngineAPI.start_thread()

    -- [PATCHED] Boot only the primary window (Tenant 0)
    for i = 0, 0 do
        TenantRegistry.async_boot_tenant(vk_rt, i, cfg_gfx.win.w, cfg_gfx.win.h, cfg_gfx.cfg.frame_slots)
    end

    local vram_template = VRAM.init_static_buffers(memory, cfg_sim, ctx.total_tiles)

    local MAX_DRAW_COMMANDS = 1024
    local RENDER_QUEUE_SIZE = 120
    ctx.render_queues = ffi.new("DrawCommand[?]", MAX_DRAW_COMMANDS * RENDER_QUEUE_SIZE * 2)

    local visual_canvas = ffi.new("VisualCanvas")
    local visual_canvas_size = ffi.sizeof("VisualCanvas")

    print("[NET] Visual Scene loaded. Cameras unlocked.")

    -- Return only runtime state and instantiated dependencies
    return {
        EngineAPI = EngineAPI,
        WindowAPI = WindowAPI,
        net_driver = net_driver,
        TenantRegistry = TenantRegistry,
        render_queue = render_queue,
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
