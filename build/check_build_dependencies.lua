-- check_deps.lua
local target = arg[1]
if target ~= "linux" and target ~= "win" then
    print("[FATAL] Usage: luajit check_deps.lua <linux|win>")
    os.exit(1)
end

local function check_file(path, label)
    local f = io.open(path, "r")
    if f then
        f:close()
        print(string.format(" [OK] %-25s : %s", label, path))
        return true
    end
    print(string.format(" [FAIL] %-23s : %s (Missing)", label, path))
    return false
end

local function check_cmd(cmd, is_win)
    local check_str = is_win and ("where " .. cmd .. " >nul 2>nul") or ("command -v " .. cmd .. " >/dev/null 2>&1")
    local res = os.execute(check_str)
    local success = (res == true or res == 0)

    if success then
        print(string.format(" [OK] %-25s : Found in PATH", "Binary: " .. cmd))
    else
        print(string.format(" [FAIL] %-23s : Not found in PATH", "Binary: " .. cmd))
    end
    return success
end

print("=== Verifying Build Dependencies for " .. string.upper(target) .. " ===")
local all_good = true

if target == "linux" then
    all_good = check_cmd("gcc", false) and all_good
    all_good = check_cmd("luajit", false) and all_good

    -- Inferred from task_shaders.lua compiling .spv
    check_cmd("glslc", false)

    print("\n--- Linux Headers & Libs ---")
    all_good = check_file("/usr/include/luajit-2.1/lua.h", "LuaJIT Headers") and all_good
    all_good = check_file("/usr/include/GLFW/glfw3.h", "GLFW Headers") and all_good
    all_good = check_file("/usr/include/vulkan/vulkan.h", "Vulkan Headers") and all_good
    all_good = check_file("/usr/lib/libvulkan.so", "Vulkan Loader (.so)") and all_good
    all_good = check_file("/usr/lib/libluajit-5.1.so", "LuaJIT Lib (.so)") and all_good

elseif target == "win" then
    all_good = check_cmd("gcc", true) and all_good

    print("\n--- MSYS2 MinGW64 Headers & Libs ---")
    local msys_base = "C:/msys64/mingw64"
    all_good = check_file(msys_base .. "/include/luajit-2.1/lua.h", "LuaJIT Headers") and all_good
    all_good = check_file(msys_base .. "/include/GLFW/glfw3.h", "GLFW Headers") and all_good
    all_good = check_file(msys_base .. "/bin/glfw3.dll", "GLFW DLL") and all_good
    all_good = check_file(msys_base .. "/bin/lua51.dll", "LuaJIT DLL") and all_good
    all_good = check_file(msys_base .. "/bin/libwinpthread-1.dll", "PThread DLL") and all_good

    print("\n--- Native Windows Vulkan SDK ---")
    local vk_sdk = "C:/VulkanSDK/1.4.341.1"
    all_good = check_file(vk_sdk .. "/Include/vulkan/vulkan.h", "Vulkan Headers") and all_good
    all_good = check_file(vk_sdk .. "/Lib/vulkan-1.lib", "Vulkan Link Lib") and all_good
end

print("\n----------------------------------------")
if all_good then
    print("[SUCCESS] All essential build dependencies are present.")
else
    print("[WARNING] One or more missing dependencies detected. Build may fail.")
end
