-- build/task_shaders.lua
local helpers = require("tools.helpers")

return function(build_env)
    print("[2/4] Compiling GLSL Shaders to SPIR-V...")
    local glslc = (build_env.platform == "win") and (build_env.vulkan_sdk_path .. "/Bin/glslc.exe") or "glslc"

    for _, sh in ipairs(build_env.shaders) do
        local cmd = string.format('%s %s -o %s', glslc, sh.src, sh.dst)

        -- helpers.run_cmd will halt the build if the shader has a syntax error
        helpers.run_cmd(cmd)
        print(" |- Compiled: " .. sh.dst)
    end
    print(" |- Shader phase complete.\n")
end
