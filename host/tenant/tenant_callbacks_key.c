/* tenant/tenant_callbacks_key.c */

void glfw_key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    int id = (int)(intptr_t)glfwGetWindowUserPointer(window);
    if (id < 0 || id >= MAX_WINDOWS) return;

    S(g_engine.mailbox.active_window, id);

    // --- GOD BUFFER ROUTING ---
    // Safely clamp bounds and write the GLFW action (PRESS=1, RELEASE=0, REPEAT=2)
    if (key >= 0 && key < 512) {
        S(g_engine.mailbox.tenants[id].keys[key], (uint8_t)action);
    }

    // --- OS-LEVEL INTERCEPTS ---
    if (key == GLFW_KEY_F11 && action == GLFW_PRESS) {
        if (!s_is_fullscreen[id]) {
            glfwGetWindowPos(window, &s_win_x[id], &s_win_y[id]);
            glfwGetWindowSize(window, &s_win_w[id], &s_win_h[id]);
            GLFWmonitor* monitor = glfwGetPrimaryMonitor();
            const GLFWvidmode* mode = glfwGetVideoMode(monitor);
            glfwSetWindowMonitor(window, monitor, 0, 0, mode->width, mode->height, mode->refreshRate);
            s_is_fullscreen[id] = true;
            printf("[C-CORE] Tenant %d: Native Fullscreen Engaged (%dx%d @ %dHz)\n",
                   id, mode->width, mode->height, mode->refreshRate);
        } else {
            glfwSetWindowMonitor(window, NULL, s_win_x[id], s_win_y[id], s_win_w[id], s_win_h[id], 0);
            s_is_fullscreen[id] = false;
            printf("[C-CORE] Tenant %d: Windowed Mode Restored\n", id);
        }
    }

    if (key == GLFW_KEY_F10 && action == GLFW_PRESS) {
        int is_cap = L(g_engine.mailbox.tenants[id].mouse_captured);
        is_cap = !is_cap;
        S(g_engine.mailbox.tenants[id].mouse_captured, is_cap);
        if (is_cap) {
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_CAPTURED);
            printf("[C-CORE] Tenant %d: Mouse Clamped to Window (F10)\n", id);
        } else {
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
            printf("[C-CORE] Tenant %d: Mouse Freed (F10)\n", id);
        }
    }

    if (key == GLFW_KEY_F5 && action == GLFW_PRESS) {
        printf("\n>>> NATIVE OS KEY INTERCEPT: F5 <<<\n");
        for (int i = 0; i < MAX_WINDOWS; i++) {
            vx_sys_dump_ring_state(i);
        }
        fflush(stdout);
    }
}
