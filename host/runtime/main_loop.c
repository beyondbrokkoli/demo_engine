/* host/main_loop.c */

int main(int argc, char** argv) {
    // Capture args immediately for the Lua VM thread
    g_host_argc = argc;
    g_host_argv = argv;
    if (!glfwInit()) {
        printf("[C-FATAL]\n");
        return -1;
    }

    vx_init_mailbox();
    vmath_thread_t lua_thread = vmath_thread_start(lua_co_overlord_loop, NULL);
    GLFWwindow* windows[MAX_WINDOWS] = {NULL};

    while (vx_core_is_running()) {
        glfwPollEvents();

        for (int id = 0; id < MAX_WINDOWS; id++) {
            // Polling the glfw_cmd channel for OS lifecycle events
            int cmd = L(g_engine.mailbox.tenants[id].glfw_cmd);

            if (cmd == OS_CMD_BOOT_WINDOW && windows[id] == NULL) {
                int w = L_R(g_engine.mailbox.tenants[id].glfw_arg_w);
                int h = L_R(g_engine.mailbox.tenants[id].glfw_arg_h);

                glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
                glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);

                windows[id] = glfwCreateWindow(w, h, "Weaver Engine", NULL, NULL);
                glfwSetWindowUserPointer(windows[id], (void*)(intptr_t)id);
                glfwSetWindowSizeLimits(windows[id], 640, 360, GLFW_DONT_CARE, GLFW_DONT_CARE);
                glfwShowWindow(windows[id]);
                glfwSetWindowAttrib(windows[id], GLFW_FLOATING, GLFW_TRUE);
                glfwFocusWindow(windows[id]);
                glfwSetWindowAttrib(windows[id], GLFW_FLOATING, GLFW_FALSE);

                glfwSetFramebufferSizeCallback(windows[id], glfw_framebuffer_size_callback);
                glfwSetKeyCallback(windows[id], glfw_key_callback);
                glfwSetCursorPosCallback(windows[id], glfw_cursor_callback);
                glfwSetMouseButtonCallback(windows[id], glfw_mouse_button_callback);

                int fb_w, fb_h;
                glfwGetFramebufferSize(windows[id], &fb_w, &fb_h);
                S(g_engine.mailbox.tenants[id].win_w, fb_w);
                S(g_engine.mailbox.tenants[id].win_h, fb_h);

                void* instance = L(g_engine.mailbox.tenants[id].vk_instance);
                if (instance != NULL) {
                    VkSurfaceKHR surface;
                    if (glfwCreateWindowSurface((VkInstance)instance, windows[id], NULL, &surface) == VK_SUCCESS) {
                        S(g_engine.mailbox.tenants[id].vk_surface, (void*)surface);
                    }
                }
                S(g_engine.mailbox.tenants[id].glfw_cmd, OS_CMD_IDLE);
            }
            else if (cmd == OS_CMD_KILL_WINDOW && windows[id] != NULL) {
                S(g_wsi_state[id], 0);
                int timeout = 2000;
                int spin_count = 0;

                // With the new architecture, Lua guarantees the GPU is idle before 
                // sending OS_CMD_KILL_WINDOW, making this loop a near-instant fallthrough.
                // Kept as an absolute safety net.
                while ((L(g_render_busy[id]) || L(g_transfer_busy[id])) && timeout > 0) {
                    if (spin_count >= 2000) { timeout--; }
                    vx_spin_wait(&spin_count);
                }

                glfwDestroyWindow(windows[id]);
                windows[id] = NULL;
                S(g_engine.mailbox.tenants[id].vk_surface, NULL);
                S(g_engine.mailbox.tenants[id].glfw_cmd, OS_CMD_IDLE);
            }

            if (windows[id] && glfwWindowShouldClose(windows[id])) {
                S(g_engine.mailbox.tenants[id].last_key_pressed, GLFW_KEY_ESCAPE);
            }
        }
        SLEEP_MS(1);
    }

    int spin_count = 0;
    while (L(g_engine.mailbox.lua_finished) == 0) {
        vx_spin_wait(&spin_count);
    }
    vmath_thread_join(lua_thread);

    for (int i = 0; i < MAX_WINDOWS; i++) {
        if (windows[i]) glfwDestroyWindow(windows[i]);
    }

    glfwTerminate();
    return 0;
}
