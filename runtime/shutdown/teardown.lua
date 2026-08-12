local ffi = require("ffi")

local Teardown = {}

function Teardown.execute_phase_gate(env)
    print("\n[LUA IO] Render Loop Terminated. Commencing Teardown...")

    -- 1. THE MASTERSTROKE: Phase-Gate isolation
    for win_id, tenant in pairs(env.TenantRegistry.active) do
        env.WindowAPI.trigger_wsi_rebuild(win_id)
    end

    -- 2. THE OMNISCIENCE POLL
    print("[LUA IO] Waiting for C-Core Render Multiplexer to acknowledge teardown...")
    local all_idle = false
    while not all_idle do
        all_idle = true
        for win_id, _ in pairs(env.TenantRegistry.active) do
            if env.WindowAPI.is_tenant_idle(win_id) == 0 then
                all_idle = false
                break
            end
        end
        if not all_idle then env.sys_sleep(1) end
    end
    print("[LUA IO] Absolute C-Core Idle Confirmed.")

    env.vk_rt.vk.vkDeviceWaitIdle(env.vk_rt.device)

    local graphics_mod = require("runtime.presentation.graphics.graphics_pipeline")
    local renderer_mod = require("runtime.presentation.graphics.renderer")
    local swapchain_mod = require("runtime.services.gpu.swapchain")

    for win_id, tenant in pairs(env.TenantRegistry.active) do
        print(string.format("[TEARDOWN] Purging Remaining Tenant %d...", win_id))
        graphics_mod.Destroy(env.vk_rt.vk, env.vk_rt, tenant.gfx)
        renderer_mod.Destroy(env.vk_rt.vk, env.vk_rt.device, tenant.sync)
        swapchain_mod.Destroy(env.vk_rt.vk, env.vk_rt, tenant.sc)

        local surface_ptr = env.WindowAPI.get_surface(win_id)
        if surface_ptr ~= nil then
            local vk_surface = ffi.cast("VkSurfaceKHR", surface_ptr)
            env.vk_rt.vk.vkDestroySurfaceKHR(env.vk_rt.instance, vk_surface, nil)
        end
        env.WindowAPI.destroy(win_id)
    end

    env.EngineAPI.kill_thread()
    require("runtime.presentation.graphics.compute_pipeline").Destroy(env.vk_rt.vk, env.vk_rt, env.engine_ctx.comp_state)
    require("runtime.services.gpu.descriptors").Destroy(env.vk_rt.vk, env.vk_rt.device, env.desc)

    env.memory.DestroyBuffer("MASTER_GPU_BLOCK", env.vk_rt)
    env.memory.DestroyBuffer("MASTER_INDEX_BLOCK", env.vk_rt)
    env.memory.DestroyBuffer("PALETTE_STAGING", env.vk_rt)
    env.memory.DestroyBuffer("PALETTE_HAVEN", env.vk_rt)

    env.memory.DestroyTransferSubsystem(env.vk_rt)

    require("runtime.services.gpu.vulkan_core").Destroy(env.vk_rt, env.cfg_gfx.cfg)

    -- [!] NETCODE TEARDOWN
    -- Placed at the very end to ensure no graphical callbacks try to read
    -- network state while we are closing the sockets.
    print("[TEARDOWN] Dismantling Network Core...")
    require("network.transport.network").Shutdown()

    print("[LUA IO] Teardown Complete. Safe Exit.")
end

return Teardown
