-- runtime/services/tenant/tenant_registry.lua
local ffi = require("ffi")
local WindowAPI = require("runtime.boot.window_api")
local EngineAPI = require("runtime.boot.engine_api")
local swapchain = require("runtime.services.gpu.swapchain")
local renderer = require("runtime.presentation.graphics.renderer")
local camera_mod = require("runtime.simulation.camera")
local graphics_mod = require("runtime.presentation.graphics.graphics_pipeline")

local TenantRegistry = {
    active = {},
    pending_boots = {} -- Store our yielding coroutines
}

function TenantRegistry.boot_tenant_async(vk_rt, win_id, width, height, frame_slots, desc, manifest)
    -- Wrap the entire procedural boot sequence in a coroutine
    local boot_co = coroutine.create(function()
        print(string.format("[UI BOOTSTRAP] Booting Tenant %d asynchronously...", win_id))

        EngineAPI.publish_instance(win_id, vk_rt.instance)
        WindowAPI.boot(win_id, width, height)

        local surface = nil
        while surface == nil do
            coroutine.yield() -- The lock-free magic
            surface = WindowAPI.get_surface(win_id)
        end

        -- [VULKAN SAFETY]: Halt device briefly to safely allocate WSI
        vk_rt.vk.vkDeviceWaitIdle(vk_rt.device)

        local sc = swapchain.Init(vk_rt.vk, vk_rt, width, height, nil, surface)
        local sync = renderer.InitSync(vk_rt.vk, vk_rt.device, sc.imageCount)

        local wsi = ffi.new("RenderThreadInit")
        wsi.device = vk_rt.device
        wsi.queue = vk_rt.queue
        wsi.transfer_queue = vk_rt.transferQueue
        wsi.swapchain = sc.handle

        -- Tell the C-Core to modulo the CPU frames exactly to the hardware capability
        wsi.max_frames_in_flight = sc.imageCount

        for i = 0, sc.imageCount - 1 do
            wsi.swapchain_images[i] = ffi.cast("uint64_t", sc.images[i])
            wsi.swapchain_views[i]  = ffi.cast("uint64_t", sc.imageViews[i])
        end

        -- [ARMOR PATCH]: Map ALL hardware indices across the FFI boundary
        -- so the C-Core never reads a NULL pointer when using img_idx!
        for i = 0, sc.imageCount - 1 do
            wsi.image_available[i] = sync.imageAvailable[i];
            wsi.render_finished[i] = sync.renderFinished[i];
            wsi.in_flight[i]       = sync.inFlight[i];
        end

        -- FIX INJECTED: Populate required Dynamic Rendering and Sync function pointers
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

        EngineAPI.allocate_tenant(win_id, wsi, vk_rt.qIndex, vk_rt.tIndex);
        EngineAPI.init_stream(win_id, wsi);

        local tenant = {
            win_id = win_id,
            suspended = false,
            width = width,
            height = height,
            sc = sc,
            sync = sync,
            cam = camera_mod.new(),
            pc = ffi.new("PushConstants"),
            inv_vp = ffi.new("mat4_t")
        }
        tenant.pc.aos_current_idx, tenant.pc.aos_prev_idx, tenant.pc.dt = 0, 0, 0.0

        -- Shifted from main_setup.lua into the coroutine:
        tenant.gfx = graphics_mod.Init(
            vk_rt.vk, vk_rt, width, height,
            desc.pipelineLayout, tenant.sc.format, manifest.graphics
        )

        -- Expose to the main loop only when 100% ready
        TenantRegistry.active[win_id] = tenant
        print(string.format("[UI BOOTSTRAP] Tenant %d fully mapped and active.", win_id))
    end)

    -- Register the coroutine to be pumped
    TenantRegistry.pending_boots[win_id] = boot_co
end

return TenantRegistry
