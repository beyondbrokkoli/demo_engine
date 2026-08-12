-- build/task_invariants.lua
local ffi = require("ffi") -- We need FFI to reflect on the loaded cdef

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

    -- --- NEW: Math Struct & FFI Alignment Asserts ---
    print(" |- [HARNESS] Validating Math Struct FFI Alignments...")

    local vec4 = found["vec4_t"]
    local mat4 = found["mat4_t"]
    assert(vec4, "[FATAL] Gremlin removed vec4_t!")
    assert(mat4, "[FATAL] Gremlin removed mat4_t!")

    -- 1. Check that the Lua AST was constructed with the correct properties
    assert(vec4.force_align and vec4.align == 16, "[FATAL INVARIANT] vec4_t missing force_align=16 in AST")
    assert(mat4.force_align and mat4.align == 16, "[FATAL INVARIANT] mat4_t missing force_align=16 in AST")

    -- 2. The Ultimate Test: Ask LuaJIT FFI how it actually parsed the generated string!
    -- If our cdef generation failed to include __attribute__((aligned(16))), this will catch it.
    local ffi_vec4_size = ffi.sizeof("vec4_t")
    local ffi_vec4_align = ffi.alignof("vec4_t")
    local ffi_mat4_size = ffi.sizeof("mat4_t")
    local ffi_mat4_align = ffi.alignof("mat4_t")

    assert(ffi_vec4_size == 16, string.format("[FATAL INVARIANT] vec4_t FFI size mismatch! Expected 16, got %d", ffi_vec4_size))
    assert(ffi_vec4_align == 16, string.format("[FATAL INVARIANT] vec4_t FFI alignment broken! Expected 16, got %d", ffi_vec4_align))

    assert(ffi_mat4_size == 64, string.format("[FATAL INVARIANT] mat4_t FFI size mismatch! Expected 64, got %d", ffi_mat4_size))
    assert(ffi_mat4_align == 16, string.format("[FATAL INVARIANT] mat4_t FFI alignment broken! Expected 16, got %d", ffi_mat4_align))

    print(" |- [HARNESS] All system-critical invariants passed.")
end
