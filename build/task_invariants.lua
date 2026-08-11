-- build/task_invariants.lua

return function(ctx)
    print(" |- [HARNESS] Running Invariant Asserts...")
    local found = {}
    for _, struct in ipairs(ctx.struct_specs) do found[struct.name] = struct end

    local rt_init = found["RenderThreadInit"]
    assert(rt_init, "[FATAL] Gremlin removed RenderThreadInit!")

    local wsi_found, swapchain_arr_found = false, false
    for _, m in ipairs(rt_init.members) do
        if m.name == "swapchain" and m.type == "VkSwapchainKHR" then wsi_found = true end
        if m.name == "swapchain_images" and m.count == 10 then swapchain_arr_found = true end
    end
    assert(wsi_found, "[FATAL INVARIANT] RenderThreadInit missing VkSwapchainKHR. Mux broken!")
    assert(swapchain_arr_found, "[FATAL INVARIANT] RenderThreadInit swapchain_images missing/altered!")

    local r_packet = found["RenderPacket"]
    assert(r_packet, "[FATAL] Gremlin removed RenderPacket!")
    local target_win_found = false
    for _, m in ipairs(r_packet.members) do
        if m.name == "target_window_id" and m.type == "uint32_t" then target_win_found = true end
    end
    assert(target_win_found, "[FATAL INVARIANT] RenderPacket missing 'target_window_id'.")
    assert(r_packet.force_align and r_packet.align == 64, "[FATAL INVARIANT] RenderPacket not 64-byte aligned!")

    -- NEW: DrawCommand cache-line invariants
    local d_cmd = found["DrawCommand"]
    assert(d_cmd, "[FATAL] Gremlin removed DrawCommand!")
    assert(d_cmd.force_align and d_cmd.align == 64, "[FATAL INVARIANT] DrawCommand must be 64-byte aligned to prevent L1 cache false-sharing!")

    -- NOTE: LockstepPacket invariants are now enforced at compile-time by C11 _Static_assert
    -- inside network/shared_structs.h. The Lua top-down builder no longer cares.

    print(" |- [HARNESS] All system-critical invariants passed.")
end
