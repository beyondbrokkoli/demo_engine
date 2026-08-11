return function(ctx)
    local specs = {
        {
            name = "RenderThreadInit",
            c_only = true, vk_shield = true, wire_format = false, force_align = false, glsl_std430 = false,
            members = {
                { type = "VkDevice", name = "device" },
                { type = "VkQueue", name = "queue" },
                { type = "VkQueue", name = "transfer_queue" },
                { type = "VkSwapchainKHR", name = "swapchain" },
                { type = "uint32_t", name = "max_frames_in_flight" },
                { type = "uint64_t", name = "swapchain_images", count = 10 },
                { type = "uint64_t", name = "swapchain_views", count = 10 },
                { type = "VkSemaphore", name = "image_available", count = 10 },
                { type = "VkSemaphore", name = "render_finished", count = 10 },
                { type = "VkFence", name = "in_flight", count = 10 },
                { type = "void*", name = "vkWaitForFences" },
                { type = "void*", name = "vkAcquireNextImageKHR" },
                { type = "void*", name = "vkResetFences" },
                { type = "void*", name = "vkQueueSubmit" },
                { type = "void*", name = "vkQueuePresentKHR" },
                { type = "void*", name = "pfnBegin" },
                { type = "void*", name = "pfnEnd" },
                { type = "void*", name = "pfnSetCullMode" },
                { type = "void*", name = "pfnSetFrontFace" },
                { type = "void*", name = "pfnSetPrimitiveTopology" },
                { type = "void*", name = "pfnSetDepthTestEnable" },
                { type = "void*", name = "pfnSetDepthWriteEnable" },
                { type = "void*", name = "pfnSetDepthCompareOp" }
            }
        },
        {
            name = "RtsTileInstance", align = 16,
            c_only = false, vk_shield = false, wire_format = false, force_align = false, glsl_std430 = true,
            members = {
                { type = "float", name = "px" }, { type = "float", name = "py" },
                { type = "float", name = "pz" }, { type = "uint32_t", name = "tile_data" }
            }
        },
        {
            name = "PushConstants", align = 16,
            c_only = false, vk_shield = false, wire_format = false, force_align = false, glsl_std430 = true,
            members = {
                { type = "mat4_t", name = "viewProj" }, { type = "uint32_t", name = "aos_current_idx" },
                { type = "uint32_t", name = "aos_prev_idx" }, { type = "float", name = "dt" },
                { type = "float", name = "total_time" }, { type = "uint32_t", name = "target_state" },
                { type = "uint32_t", name = "hover_idx" }, { type = "uint32_t", name = "flags" }
            }
        },
        {
            name = "DrawCommand", align = 64,
            c_only = true, vk_shield = false, wire_format = false, force_align = true, glsl_std430 = false,
            members = {
                { type = "uint64_t", name = "pipeline_id" }, { type = "uint64_t", name = "descriptor_set" },
                { type = "uint32_t", name = "index_count" }, { type = "uint32_t", name = "instance_count" },
                { type = "uint32_t", name = "first_index" }, { type = "int32_t", name = "vertex_offset" },
                { type = "uint32_t", name = "first_instance" }, { type = "uint16_t", name = "pc_offset" },
                { type = "uint16_t", name = "pc_size" }, { type = "uint8_t", name = "push_constants", count = 128 },
                { type = "int16_t", name = "scissor_x" }, { type = "int16_t", name = "scissor_y" },
                { type = "uint16_t", name = "scissor_w" }, { type = "uint16_t", name = "scissor_h" },
                { type = "uint8_t", name = "cull_mode" }, { type = "uint8_t", name = "depth_test" },
                { type = "uint8_t", name = "depth_write" }, { type = "uint8_t", name = "depth_compare_op" },
                { type = "uint8_t", name = "front_face" }, { type = "uint8_t", name = "topology" }
            }
        },
        {
            name = "RenderPacket", align = 64,
            c_only = true, vk_shield = false, wire_format = false, force_align = true, glsl_std430 = false,
            members = {
                { type = "DrawCommand*", name = "draw_queue" }, { type = "uint32_t", name = "draw_count" },
                { type = "uint32_t", name = "target_window_id" }, { type = "uint64_t", name = "gfx_layout" },
                { type = "uint64_t", name = "vertex_buffer" }, { type = "uint64_t", name = "index_buffer" },
                { type = "uint64_t", name = "swapchain_image" }, { type = "uint64_t", name = "swapchain_view" },
                { type = "uint64_t", name = "depth_image" }, { type = "uint64_t", name = "depth_view" },
                { type = "uint32_t", name = "width" }, { type = "uint32_t", name = "height" }
            }
        }
    }

    for _, s in ipairs(specs) do
        s.domain = "render"
        table.insert(ctx.specs, s)
    end
end
