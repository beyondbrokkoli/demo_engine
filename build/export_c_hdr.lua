-- build/export_c_hdr.lua
local helpers = require("tools.helpers")

return function(build_env)
    print("[1/4A] Generating Domain-Specific C Headers...")

    -- Fetch the layouts (ignoring the FFI string side-effect)
    local struct_specs, _ = require("ssot.ctx_types")()
    local cfg_gfx = require("ssot.config_gfx")
    local cfg_sim = require("ssot.config_sim")

    local domain_files = {
        render  = { path = "generated/ssot_render.h", file = nil },
        sim     = { path = "generated/ssot_types.h",  file = nil }
    }

    for _, d in pairs(domain_files) do
        d.file = io.open(d.path, "wb")
        d.file:write("// AUTO-GENERATED SSoT - DO NOT MODIFY\n#pragma once\n#include <stdint.h>\n\n")
    end

    domain_files.render.file:write("// --- GRAPHICS CONSTANTS ---\n")
    for _, k in ipairs(helpers.get_sorted_keys(cfg_gfx.mode or {})) do
        domain_files.render.file:write(string.format("#define MODE_%s %d\n", string.upper(k), cfg_gfx.mode[k]))
    end

    domain_files.sim.file:write("// --- SIMULATION CONSTANTS ---\n")
    for _, k in ipairs(helpers.get_sorted_keys(cfg_sim.world or {})) do
        local val = cfg_sim.world[k]
        if type(val) == "number" then
            domain_files.sim.file:write(string.format(math.floor(val) == val and "#define WORLD_%s %d\n" or "#define WORLD_%s %.1ff\n", string.upper(k), val))
        end
    end

    for _, d in pairs(domain_files) do d.file:write("\n// --- MEMORY STRUCTURES ---\n") end

    for _, struct in ipairs(struct_specs) do
        if struct.targets.c then
            local out = domain_files[struct.domain].file
            local attr = ""
            if struct.layout.mode == "aligned" or struct.layout.mode == "std430" then
                attr = string.format("__attribute__((aligned(%d)))", struct.computed_align or struct.layout.align or 8)
            end

            out:write(string.format("typedef struct %s {\n", attr))

            for _, m in ipairs(struct.members) do
                local arr_str = ""
                if type(m.count) == "table" then
                    for _, dim in ipairs(m.count) do arr_str = arr_str .. string.format("[%d]", dim) end
                elseif m.count then arr_str = string.format("[%d]", m.count)
                end
                out:write(string.format("    %s %s%s;\n", m.type, m.name, arr_str))
            end

            out:write("} " .. struct.name .. ";\n\n")
        end
    end

    for _, d in pairs(domain_files) do d.file:close() end
    print(" |- Domain headers generated successfully in generated/.")
end
