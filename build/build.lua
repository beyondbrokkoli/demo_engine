-- build/build.lua
local target_platform = arg[1]
local build_target = arg[2]

if target_platform ~= "linux" and target_platform ~= "win" then
    print(" [FATAL] Missing or invalid target platform!")
    print(" Usage: luajit build/build.lua <linux|win> [shaders]")
    os.exit(1)
end

if target_platform == "win" then
    os.execute("if not exist bin mkdir bin >nul 2>&1")
    os.execute("if not exist generated mkdir generated >nul 2>&1")
else
    os.execute("mkdir -p bin generated 2>/dev/null")
end

-- Strictly Build Environment data. Centralized paths.
local msys_base = os.getenv("MSYS2_PATH") or "C:/msys64/mingw64"

local build_env = {
    platform = target_platform,
    target = build_target,

    -- Toolchain Paths
    vulkan_sdk_path = os.getenv("VULKAN_SDK") or "C:/VulkanSDK/1.4.341.1",
    msys_path       = msys_base,
    lua_inc_linux   = "/usr/include/luajit-2.1",
    lua_inc_win     = msys_base .. "/include/luajit-2.1",

    shaders = {
        { src = "shaders/render.vert", dst = "bin/render_vert.spv" },
        { src = "shaders/render.frag", dst = "bin/render_frag.spv" }
    }
}

print(" WEAVER V2 HYBRID BUILD AUTOMATION")
print(" Target Platform: " .. string.upper(build_env.platform))

require("build.task_invariants")(build_env)
require("build.export_c_hdr")(build_env)
require("build.export_glsl")(build_env)
require("build.task_shaders")(build_env)
require("build.task_c_objects")(build_env)
require("build.task_headless")(build_env)

print("\n[SUCCESS] Weaver V2 Hybrid build complete!")
