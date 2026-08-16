-- runtime/services/tenant/tenant_registry.lua
local ffi = require("ffi")
local WindowAPI = require("runtime.boot.window_api")
local EngineAPI = require("runtime.boot.engine_api")
local camera_mod = require("runtime.simulation.camera")

local TenantRegistry = {
    active = {},
    global_vram_transferred = false
}

function TenantRegistry.async_boot_tenant(vk_rt, win_id, width, height, frame_slots)
    print(string.format("[UI BOOTSTRAP] Async Booting Tenant %d...", win_id))

    -- 1. Publish Instance to Multiplexer & Request OS Window
    EngineAPI.publish_instance(win_id, vk_rt.instance)
    WindowAPI.boot(win_id, width, height)

    -- 2. Construct the Skeleton Lua Tenant Struct
    local tenant = {
        win_id = win_id,
        suspended = true,   -- Start suspended so main loop doesn't render it
        boot_state = 1,     -- 1 = Polling for Surface
        width = width,
        height = height,
        sc = nil,           -- Vulkan objects are deferred
        sync = nil,
        gfx = nil,
        cam = camera_mod.new(),
        pc = ffi.new("PushConstants"),
        inv_vp = ffi.new("mat4_t")
    }

    tenant.pc.aos_current_idx, tenant.pc.aos_prev_idx, tenant.pc.dt = 0, 0, 0.0

    -- Inject skeleton into the game loop. The Lifecycle state machine takes over from here.
    TenantRegistry.active[win_id] = tenant
    return tenant
end

return TenantRegistry
