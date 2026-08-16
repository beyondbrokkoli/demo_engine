-- runtime/services/tenant/tenant_lifecycle.lua
local ffi = require("ffi")
local swapchain_mod = require("runtime.services.gpu.swapchain")
local renderer_mod = require("runtime.presentation.graphics.renderer")
local graphics_mod = require("runtime.presentation.graphics.graphics_pipeline")

local Lifecycle = {}

-- [PATCHED] Added 'memory' to the parameters
function Lifecycle.process_state_machine(win_id, tenant, WindowAPI, EngineAPI, vk_rt, desc, manifest, cfg_gfx, TenantRegistry, memory)

    -- [ASYNC BOOT HANDSHAKE]
    if tenant.boot_state then
        if tenant.boot_state == 1 then
            -- Phase 1: Poll for OS Surface
            local surface_ptr = WindowAPI.get_surface(win_id)
            if surface_ptr ~= nil then
                tenant.boot_state = 2
            end
            return true -- Skip Render, still waiting

        elseif tenant.boot_state == 2 then
            -- Phase 2: Surface acquired! Bake Vulkan objects safely.
            -- Because we are in the main Lua thread and NOT executing vkQueueWaitIdle,
            -- this does not block the C Render Thread from servicing other active windows.
            local surface_ptr = WindowAPI.get_surface(win_id)
            tenant.sc = swapchain_mod.Init(vk_rt.vk, vk_rt, tenant.width, tenant.height, nil, surface_ptr)
            tenant.sync = renderer_mod.InitSync(vk_rt.vk, vk_rt.device, tenant.sc.imageCount)
            tenant.gfx = graphics_mod.Init(vk_rt.vk, vk_rt, tenant.width, tenant.height, desc.pipelineLayout, tenant.sc.format, manifest.graphics)

            local wsi = ffi.new("RenderThreadInit")
            wsi.device = vk_rt.device
            wsi.queue = vk_rt.queue
            wsi.transfer_queue = vk_rt.transferQueue
            wsi.swapchain = tenant.sc.handle
            wsi.max_frames_in_flight = tenant.sc.imageCount

            for i = 0, tenant.sc.imageCount - 1 do
                wsi.swapchain_images[i] = ffi.cast("uint64_t", tenant.sc.images[i])
                wsi.swapchain_views[i]  = ffi.cast("uint64_t", tenant.sc.imageViews[i])
                wsi.image_available[i] = tenant.sync.imageAvailable[i]
                wsi.render_finished[i] = tenant.sync.renderFinished[i]
                wsi.in_flight[i]       = tenant.sync.inFlight[i]
            end

            -- Copied from tenant_registry.lua
            local vk, dev = vk_rt.vk, vk_rt.device
            wsi.vkWaitForFences = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkWaitForFences"))
            wsi.vkAcquireNextImageKHR = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkAcquireNextImageKHR"))
            wsi.vkResetFences = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkResetFences"))
            wsi.vkQueueSubmit = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkQueueSubmit"))
            wsi.vkQueuePresentKHR = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkQueuePresentKHR"))
            wsi.pfnBegin = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkCmdBeginRenderingKHR"))
            wsi.pfnEnd = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkCmdEndRenderingKHR"))
            wsi.pfnSetCullMode = vk.vkGetDeviceProcAddr(dev, "vkCmdSetCullModeEXT")
            wsi.pfnSetFrontFace = vk.vkGetDeviceProcAddr(dev, "vkCmdSetFrontFaceEXT")
            wsi.pfnSetPrimitiveTopology = vk.vkGetDeviceProcAddr(dev, "vkCmdSetPrimitiveTopologyEXT")
            wsi.pfnSetDepthTestEnable = vk.vkGetDeviceProcAddr(dev, "vkCmdSetDepthTestEnableEXT")
            wsi.pfnSetDepthWriteEnable = vk.vkGetDeviceProcAddr(dev, "vkCmdSetDepthWriteEnableEXT")
            wsi.pfnSetDepthCompareOp = vk.vkGetDeviceProcAddr(dev, "vkCmdSetDepthCompareOpEXT")

            -- Push the WSI struct to C-Core
            EngineAPI.allocate_tenant(win_id, wsi, vk_rt.qIndex, vk_rt.tIndex)
            EngineAPI.init_stream(win_id, wsi)

            -- Phase 3: Initiate Injection Handshake
            WindowAPI.inject_tenant(win_id) -- 3 = RND_CMD_INJECT_TENANT
            tenant.boot_state = 3
            return true -- Skip Render

        elseif tenant.boot_state == 3 then
            -- Phase 4: Await C Render Thread Acknowledgment
            if WindowAPI.is_tenant_idle(win_id) == 1 then
                tenant.boot_state = nil
                tenant.suspended = false
                print(string.format("[UI BOOTSTRAP] Tenant %d successfully injected!", win_id))

                -- [VRAM COLOR STREAM INJECTION]
                -- The first fully awakened window pipelines the global VRAM transfer
                if not TenantRegistry.global_vram_transferred then
                    print(string.format("[VRAM] Window %d streaming global Palette to GPU...", win_id))
                    memory.TransferAsync(win_id, "PALETTE_STAGING", "PALETTE_HAVEN", 16384)
                    TenantRegistry.global_vram_transferred = true
                end
            end
            return true -- Skip Render
        end
    end

    -- Early Escape State
    if WindowAPI.get_last_key(win_id) == cfg_gfx.key.esc then
        if not tenant.kill_state then
            tenant.suspended = true
            tenant.kill_state = 1
            tenant.kill_wait = 0
            -- [FIX] Removed WindowAPI.trigger_wsi_rebuild(win_id).
            -- The phase-gate below now issues the explicit RND_CMD_HALT command.
        end
    end

    if WindowAPI.is_key_down(win_id, cfg_gfx.key.f5) then
        ffi.C.vx_sys_dump_ring_state(win_id)
    end

    -- [PHASE-GATE DYNAMIC TEARDOWN]
    if tenant.kill_state == 1 then
        -- 1. Request Render Thread to halt and idle the queue
        ffi.C.vx_sys_set_render_cmd(win_id, 2) -- 2 = RND_CMD_HALT
        tenant.kill_state = 2
        return true -- Skip Render

    elseif tenant.kill_state == 2 then
        -- 2. Wait for C Render Thread to acknowledge and idle
        if WindowAPI.is_tenant_idle(win_id) == 1 then

            -- SAFE TO DESTROY VULKAN RESOURCES
            graphics_mod.Destroy(vk_rt.vk, vk_rt, tenant.gfx)
            renderer_mod.Destroy(vk_rt.vk, vk_rt.device, tenant.sync)
            swapchain_mod.Destroy(vk_rt.vk, vk_rt, tenant.sc)

            local surface_ptr = WindowAPI.get_surface(win_id)
            if surface_ptr ~= nil then
                local vk_surface = ffi.cast("VkSurfaceKHR", surface_ptr)
                vk_rt.vk.vkDestroySurfaceKHR(vk_rt.instance, vk_surface, nil)
            end

            -- 3. Trigger GLFW Window Teardown
            ffi.C.vx_sys_set_glfw_cmd(win_id, 2, 0, 0) -- 2 = OS_CMD_KILL_WINDOW
            tenant.kill_state = 3
        end
        return true -- Skip Render

    elseif tenant.kill_state == 3 then
        -- 4. Wait for Main C Thread to destroy the GLFW window
        if WindowAPI.get_surface(win_id) == nil then
            TenantRegistry.active[win_id] = nil
            local active_count = 0
            for _ in pairs(TenantRegistry.active) do active_count = active_count + 1 end
            if active_count == 0 then EngineAPI.shutdown() end
        end
        return true -- Skip Render
    end

    -- Suspension / WSI Rebuild
    if WindowAPI.get_resize_state(win_id) and not tenant.suspended then
        WindowAPI.trigger_wsi_rebuild(win_id)
        tenant.suspended = true
        return true -- Skip Render
    end

    if tenant.suspended then
        if WindowAPI.get_resize_state(win_id) then
            WindowAPI.trigger_wsi_rebuild(win_id)
            return true
        end

        local new_w, new_h = WindowAPI.get_window_size(win_id)
        if new_w > 0 and new_h > 0 then
            tenant.width, tenant.height = new_w, new_h
            tenant.suspended = false

            graphics_mod.Destroy(vk_rt.vk, vk_rt, tenant.gfx)
            renderer_mod.Destroy(vk_rt.vk, vk_rt.device, tenant.sync)

            local old_sc_handle = tenant.sc.handle
            for i = 0, tenant.sc.imageCount - 1 do
                vk_rt.vk.vkDestroyImageView(vk_rt.device, tenant.sc.imageViews[i], nil)
            end

            tenant.sc = swapchain_mod.Init(vk_rt.vk, vk_rt, new_w, new_h, old_sc_handle, WindowAPI.get_surface(win_id))
            tenant.gfx = graphics_mod.Init(vk_rt.vk, vk_rt, new_w, new_h, desc.pipelineLayout, tenant.sc.format, manifest.graphics)
            tenant.sync = renderer_mod.InitSync(vk_rt.vk, vk_rt.device, tenant.sc.imageCount)
            vk_rt.vk.vkDestroySwapchainKHR(vk_rt.device, old_sc_handle, nil)

            local wsi = ffi.new("RenderThreadInit")
            wsi.device = vk_rt.device
            wsi.queue = vk_rt.queue
            wsi.transfer_queue = vk_rt.transferQueue
            wsi.swapchain = tenant.sc.handle
            wsi.max_frames_in_flight = tenant.sc.imageCount

            for i = 0, tenant.sc.imageCount - 1 do
                wsi.swapchain_images[i] = ffi.cast("uint64_t", tenant.sc.images[i])
                wsi.swapchain_views[i]  = ffi.cast("uint64_t", tenant.sc.imageViews[i])
                wsi.image_available[i] = tenant.sync.imageAvailable[i]
                wsi.render_finished[i] = tenant.sync.renderFinished[i]
                wsi.in_flight[i]       = tenant.sync.inFlight[i]
            end

            local vk, dev = vk_rt.vk, vk_rt.device
            wsi.vkWaitForFences = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkWaitForFences"))
            wsi.vkAcquireNextImageKHR = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkAcquireNextImageKHR"))
            wsi.vkResetFences = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkResetFences"))
            wsi.vkQueueSubmit = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkQueueSubmit"))
            wsi.vkQueuePresentKHR = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkQueuePresentKHR"))
            wsi.pfnBegin = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkCmdBeginRenderingKHR"))
            wsi.pfnEnd = ffi.cast("void*", vk.vkGetDeviceProcAddr(dev, "vkCmdEndRenderingKHR"))
            wsi.pfnSetCullMode = vk.vkGetDeviceProcAddr(dev, "vkCmdSetCullModeEXT")
            wsi.pfnSetFrontFace = vk.vkGetDeviceProcAddr(dev, "vkCmdSetFrontFaceEXT")
            wsi.pfnSetPrimitiveTopology = vk.vkGetDeviceProcAddr(dev, "vkCmdSetPrimitiveTopologyEXT")
            wsi.pfnSetDepthTestEnable = vk.vkGetDeviceProcAddr(dev, "vkCmdSetDepthTestEnableEXT")
            wsi.pfnSetDepthWriteEnable = vk.vkGetDeviceProcAddr(dev, "vkCmdSetDepthWriteEnableEXT")
            wsi.pfnSetDepthCompareOp = vk.vkGetDeviceProcAddr(dev, "vkCmdSetDepthCompareOpEXT")

            EngineAPI.init_stream(win_id, wsi)
        end
        return true -- Skip Render this frame to let pipeline settle
    end

    return false
end

return Lifecycle
