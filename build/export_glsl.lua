return function(ctx)
    print("[1/4B] Generating GLSL SSoT...")
    local out = io.open("generated/registry.glsl", "wb")
    out:write("// AUTO-GENERATED SSoT - DO NOT MODIFY\n#ifndef REGISTRY_GLSL\n#define REGISTRY_GLSL\n\n// --- CONSTANTS ---\n")

    for _, k in ipairs(ctx.get_sorted_keys(ctx.cfg_gfx.mode or {})) do
        out:write(string.format("const uint MODE_%s = %dU;\n", string.upper(k), ctx.cfg_gfx.mode[k]))
    end
    for _, k in ipairs(ctx.get_sorted_keys(ctx.cfg_sim.world or {})) do
        local val = ctx.cfg_sim.world[k]
        if type(val) == "number" then
            out:write(string.format(math.floor(val) == val and "const uint WORLD_%s = %dU;\n" or "const float WORLD_%s = %.1f;\n", string.upper(k), val))
        end
    end

    out:write("\n// --- std430 SSBO DEFINITIONS ---\n")
    for _, struct in ipairs(ctx.struct_specs) do
        -- The combinatorial negative check is gone, replaced by a pure data-driven intent
        if struct.targets.glsl then
            out:write(string.format("struct %s {\n", struct.name))
            for _, m in ipairs(struct.members) do
                local arr_str = type(m.count) == "table" and string.format("[%d][%d]", m.count[1], m.count[2]) or (m.count and string.format("[%d]", m.count) or "")
                if m.is_pad then
                    out:write(string.format("    // Engine injected pad: %s[%s]\n", m.type, tostring(m.count)))
                else
                    local glsl_type = (m.type == "float") and "float" or (string.find(m.type, "mat4") and "mat4" or "uint")
                    out:write(string.format("    %s %s%s;\n", glsl_type, m.name, arr_str))
                end
            end
            out:write("};\n\n")
        end
    end
    out:write("#endif // REGISTRY_GLSL\n")
    out:close()
    print(" |- SSoT synchronization complete.\n")
end
