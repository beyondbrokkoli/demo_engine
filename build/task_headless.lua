-- build/task_headless.lua
local helpers = require("tools.helpers")

return function(build_env)
    print("[4/4] Compiling Headless Host (Unity Build)...")

    if build_env.platform == "linux" then
        local linux_build = "gcc host/boot/main_headless.c -O3 -march=x86-64-v3 -Wl,-E -I/usr/include/luajit-2.1 -lluajit-5.1 -lm -lpthread -o bin/boot_headless.elf"

        if not helpers.run_cmd(linux_build) then
            print(" [WARNING] Headless host compilation failed.")
        else
            print(" |- Linux headless executable (boot_headless.elf) compiled.")
        end

    elseif build_env.platform == "win" then
        local LUA_INC = "C:/msys64/mingw64/include/luajit-2.1"

        local win_build = string.format(
            'gcc host/boot/main_headless.c -O3 -march=x86-64-v3 -Wl,--export-all-symbols,--no-insert-timestamp -I"%s" -lluajit-5.1 -lm -o bin/boot_headless.exe',
            LUA_INC
        )

        if not helpers.run_cmd(win_build) then
            print(" [WARNING] Windows headless compilation failed.")
        else
            print(" |- Windows headless executable (boot_headless.exe) compiled.")
        end
    end
end
