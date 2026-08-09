-- build/ctx_build.lua
require("ffi")
local target_platform = arg[1]
local build_target = arg[2]

if target_platform ~= "linux" and target_platform ~= "win" then
    print(" [FATAL] Missing or invalid target platform!")
    print(" Usage: luajit build/ctx_build.lua <linux|win> [shaders]")
    os.exit(1)
end

if target_platform == "win" then
    os.execute("if not exist bin mkdir bin")
    os.execute("if not exist generated mkdir generated")
else
    os.execute("mkdir -p bin 2>/dev/null")
    os.execute("mkdir -p generated 2>/dev/null")
end

local ctx = {
    platform = target_platform,
    target = build_target,
    vulkan_sdk_path = "C:/VulkanSDK/1.4.341.1",
    shaders = {
        { src = "shaders/render.vert", dst = "bin/render_vert.spv" },
        { src = "shaders/render.frag", dst = "bin/render_frag.spv" }
    },

    -- Load the SSoT State natively! No sub-processes required.
    struct_specs = require("ssot.ctx_types").specs,
    cfg_gfx = require("ssot.config_gfx"),
    cfg_sim = require("ssot.config_sim"),

    -- Utility for exporters
    get_sorted_keys = function(t)
        local keys = {}
        for k in pairs(t) do table.insert(keys, k) end
        table.sort(keys)
        return keys
    end,
    run_cmd = function(cmd)
        local res = os.execute(cmd)
        return (res == true or res == 0)
    end
}

print(" WEAVER V2 HYBRID BUILD AUTOMATION")
print(" Target Platform: " .. string.upper(ctx.platform))

-- Execute the modular build pipeline
require("build.task_invariants")(ctx)
require("build.export_c_hdr")(ctx)
require("build.export_glsl")(ctx)
require("build.task_shaders")(ctx)
require("build.task_c_objects")(ctx)
require("build.task_headless")(ctx)

print("\n[SUCCESS] Weaver V2 Hybrid build complete!")
