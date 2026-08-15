-- build/task_c_objects.lua
local helpers = require("tools.helpers")

return function(build_env)
    if build_env.target == "shaders" then return end

    print("[3/3] Compiling Double Paradigm C-Core...")

    if build_env.platform == "linux" then
        print(" |- Compiling pure netcode (libvx_net.so)...")
        helpers.run_cmd("gcc network/transport/vx_net_state.c network/transport/vx_net_io.c network/transport/vx_net_stun.c -O3 -march=x86-64-v3 -shared -fPIC -o bin/libvx_net.so")

        print(" |- Compiling host engine (boot.elf)...")
        local linux_build = string.format("gcc host/boot/main.c -O3 -march=x86-64-v3 -Wl,-E -I%s -lglfw -lvulkan -lluajit-5.1 -lm -lpthread -o bin/boot.elf", build_env.lua_inc_linux)

        helpers.run_cmd(linux_build)
        print(" |- Linux build complete.")

    elseif build_env.platform == "win" then
        print(" |- Compiling pure netcode (vx_net.dll)...")
        helpers.run_cmd('gcc network/transport/vx_net_state.c network/transport/vx_net_io.c network/transport/vx_net_stun.c -O3 -march=x86-64-v3 -shared -lws2_32 -o bin/vx_net.dll')

        print(" |- Compiling host engine (boot.exe)...")
        local win_build = string.format(
            'gcc host/boot/main.c -O3 -march=x86-64-v3 -Wl,--export-all-symbols,--no-insert-timestamp -I"%s" -I"%s/Include" -L"%s/Lib" -lglfw3 -lvulkan-1 -lluajit-5.1 -lm -o bin/boot.exe',
            build_env.lua_inc_win, build_env.vulkan_sdk_path, build_env.vulkan_sdk_path
        )

        helpers.run_cmd(win_build)

        print(" |- Windows build complete. Packing dependencies...")
        helpers.run_cmd(string.format('cp "%s/bin/glfw3.dll" bin/', build_env.msys_path))
        helpers.run_cmd(string.format('cp "%s/bin/lua51.dll" bin/', build_env.msys_path))
        helpers.run_cmd(string.format('cp "%s/bin/libwinpthread-1.dll" bin/', build_env.msys_path))
    end
end
