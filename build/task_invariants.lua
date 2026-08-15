-- build/task_invariants.lua
local ffi = require("ffi")

return function(build_env)
    print(" |- [HARNESS] Running Invariant Asserts...")

    -- Fetch specs and explicitly load the FFI cdef so we can validate it
    local struct_specs, cdef_str = require("ssot.ctx_types")()
    pcall(function() ffi.cdef(cdef_str) end)

    local found = {}
    for _, struct in ipairs(struct_specs) do found[struct.name] = struct end

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

    assert(r_packet.layout.mode == "aligned" and r_packet.layout.align == 64, "[FATAL INVARIANT] RenderPacket not 64-byte aligned!")

    local d_cmd = found["DrawCommand"]
    assert(d_cmd, "[FATAL] Gremlin removed DrawCommand!")

    assert(d_cmd.layout.mode == "aligned" and d_cmd.layout.align == 64, "[FATAL INVARIANT] DrawCommand must be 64-byte aligned to prevent L1 cache false-sharing!")

    print(" |- [HARNESS] Validating Math Struct FFI Alignments...")

    local vec4 = found["vec4_t"]
    local mat4 = found["mat4_t"]
    assert(vec4, "[FATAL] Gremlin removed vec4_t!")
    assert(mat4, "[FATAL] Gremlin removed mat4_t!")

    assert((vec4.layout.mode == "std430" or vec4.layout.mode == "aligned") and vec4.layout.align == 16, "[FATAL INVARIANT] vec4_t missing layout.align=16 in AST")
    assert((mat4.layout.mode == "std430" or mat4.layout.mode == "aligned") and mat4.layout.align == 16, "[FATAL INVARIANT] mat4_t missing layout.align=16 in AST")

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
