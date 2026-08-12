-- build/task_c_objects.lua
return function(ctx)
    if ctx.target == "shaders" then return end

    print("[3/3] Compiling Double Paradigm C-Core...")

    if ctx.platform == "linux" then
        -- 1. Build the Bottom-Up Pure Netcode (Shared Library)
        print(" |- Compiling pure netcode (libvx_net.so)...")
        ctx.run_cmd("gcc network/transport/vx_net_state.c network/transport/vx_net_io.c network/transport/vx_net_stun.c -O3 -march=x86-64-v3 -shared -fPIC -o bin/libvx_net.so")

        -- 2. Build the Top-Down Host Unity Build
        print(" |- Compiling host engine (boot.elf)...")
        local linux_build = "gcc host/boot/main.c -O3 -march=x86-64-v3 -Wl,-E -I/usr/include/luajit-2.1 -lglfw -lvulkan -lluajit-5.1 -lm -lpthread -o bin/boot.elf"

        if not ctx.run_cmd(linux_build) then
            print(" [WARNING] Host compilation failed.")
        else
            print(" |- Linux build complete.")
        end

    elseif ctx.platform == "win" then
        local LUA_INC = "C:/msys64/mingw64/include/luajit-2.1"

        -- 1. Build the Bottom-Up Pure Netcode (DLL)
        print(" |- Compiling pure netcode (vx_net.dll)...")
        ctx.run_cmd(string.format('gcc network/transport/vx_net_state.c network/transport/vx_net_io.c network/transport/vx_net_stun.c -O3 -march=x86-64-v3 -shared -lws2_32 -o bin/vx_net.dll'))

        -- 2. Build the Top-Down Host Unity Build (Does NOT link ws2_32 anymore)
        print(" |- Compiling host engine (boot.exe)...")
        local win_build = string.format(
            'gcc host/boot/main.c -O3 -march=x86-64-v3 -Wl,--export-all-symbols,--no-insert-timestamp -I"%s" -I"%s/Include" -L"%s/Lib" -lglfw3 -lvulkan-1 -lluajit-5.1 -lm -o bin/boot.exe',
            LUA_INC, ctx.vulkan_sdk_path, ctx.vulkan_sdk_path
        )

        if not ctx.run_cmd(win_build) then
            print(" [WARNING] Windows host compilation failed.")
        else
            print(" |- Windows build complete. Packing dependencies...")
            ctx.run_cmd("cp C:/msys64/mingw64/bin/glfw3.dll bin/")
            ctx.run_cmd("cp C:/msys64/mingw64/bin/lua51.dll bin/")
            ctx.run_cmd("cp C:/msys64/mingw64/bin/libwinpthread-1.dll bin/")
        end
    end
end
