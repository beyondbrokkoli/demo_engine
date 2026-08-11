-- runtime/services/tenant/tenant_lifecycle.lua
local ffi = require("ffi")
local swapchain_mod = require("swapchain")
local renderer_mod = require("renderer")
local graphics_mod = require("graphics_pipeline")

local Lifecycle = {}

function Lifecycle.process_state_machine(win_id, tenant, WindowAPI, EngineAPI, vk_rt, desc, manifest, cfg_gfx, TenantRegistry)
    -- Early Escape State
    if WindowAPI.get_last_key(win_id) == cfg_gfx.key.esc then
        if not tenant.kill_state then
            tenant.suspended = true
            tenant.kill_state = 1
            tenant.kill_wait = 0
            WindowAPI.trigger_wsi_rebuild(win_id)
        end
    end

    if WindowAPI.is_key_down(win_id, cfg_gfx.key.f5) then
        ffi.C.vx_sys_dump_ring_state(win_id)
    end

    -- [PHASE-GATE DYNAMIC TEARDOWN]
    if tenant.kill_state == 1 then
        if WindowAPI.is_tenant_idle(win_id) == 1 then
            graphics_mod.Destroy(vk_rt.vk, vk_rt, tenant.gfx)
            renderer_mod.Destroy(vk_rt.vk, vk_rt.device, tenant.sync)
            swapchain_mod.Destroy(vk_rt.vk, vk_rt, tenant.sc)

            local surface_ptr = WindowAPI.get_surface(win_id)
            if surface_ptr ~= nil then
                local vk_surface = ffi.cast("VkSurfaceKHR", surface_ptr)
                vk_rt.vk.vkDestroySurfaceKHR(vk_rt.instance, vk_surface, nil)
            end

            ffi.C.vx_sys_set_cmd(win_id, cfg_gfx.sys.kill, 0, 0)
            tenant.kill_state = 2
        end
        return true -- Skip Render
    elseif tenant.kill_state == 2 then
        if WindowAPI.get_surface(win_id) == nil and WindowAPI.is_tenant_idle(win_id) == 1 then
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
