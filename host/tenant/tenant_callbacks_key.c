/* tenant/tenant_callbacks_key.c */

void glfw_key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    int id = (int)(intptr_t)glfwGetWindowUserPointer(window);
    if (id < 0 || id >= MAX_WINDOWS) return;

    S(g_engine.mailbox.active_window, id);

    if (action == GLFW_PRESS || action == GLFW_RELEASE) {
        uint32_t bit = 0;
        if      (key == GLFW_KEY_W) bit = 1;
        else if (key == GLFW_KEY_S) bit = 2;
        else if (key == GLFW_KEY_A) bit = 4;
        else if (key == GLFW_KEY_D) bit = 8;
        else if (key == GLFW_KEY_E) bit = 16;
        else if (key == GLFW_KEY_Q) bit = 32;

        if (bit) {
            uint32_t mask = L(g_engine.mailbox.tenants[id].wasd_mask);
            uint32_t new_mask;
            do {
                new_mask = (action == GLFW_PRESS) ? (mask | bit) : (mask & ~bit);
            } while (!CWX(g_engine.mailbox.tenants[id].wasd_mask, mask, new_mask));
        }
    }

    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
        S(g_engine.mailbox.tenants[id].last_key_pressed, GLFW_KEY_ESCAPE);
    }
    if (key == GLFW_KEY_SPACE) {
        S(g_engine.mailbox.tenants[id].key_space, (action != GLFW_RELEASE) ? 1 : 0);
    }

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

    if (action == GLFW_PRESS) {
        if (key == GLFW_KEY_1 || key == GLFW_KEY_2 || key == GLFW_KEY_3 || key == GLFW_KEY_4 ||
            key == GLFW_KEY_F5 || key == GLFW_KEY_ENTER || key == GLFW_KEY_KP_ENTER) {
            S(g_engine.mailbox.tenants[id].last_key_pressed, key);
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
