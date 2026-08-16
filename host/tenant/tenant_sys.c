/* tenant/tenant_sys.c */

EXPORT int vx_sys_is_tenant_idle(int win_id) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return 1;
    int busy = L(g_render_busy[win_id]);
    int os_cmd = L(g_engine.mailbox.tenants[win_id].glfw_cmd);
    int rnd_cmd = L(g_engine.mailbox.tenants[win_id].render_cmd);
    return (busy == 0 && os_cmd == OS_CMD_IDLE && rnd_cmd == RND_CMD_IDLE) ? 1 : 0;
}

EXPORT int vx_sys_get_resize_state(int win_id) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return 0;
    return atomic_load_explicit(
        &g_engine.mailbox.tenants[win_id].window_resized,
        memory_order_acquire);
}

EXPORT const char** vx_sys_glfw_extensions(uint32_t* count) {
    return glfwGetRequiredInstanceExtensions(count);
}

EXPORT void vx_sys_publish_instance(int win_id, void* instance) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return;
    S(g_engine.mailbox.tenants[win_id].vk_instance, instance);
}

EXPORT void* vx_sys_get_surface(int win_id) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return NULL;
    return L(g_engine.mailbox.tenants[win_id].vk_surface);
}

EXPORT void vx_sys_set_glfw_cmd(int win_id, int cmd, int w, int h) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return;
    S_R(g_engine.mailbox.tenants[win_id].glfw_arg_w, w);
    S_R(g_engine.mailbox.tenants[win_id].glfw_arg_h, h);
    S(g_engine.mailbox.tenants[win_id].glfw_cmd, cmd);
}

EXPORT void vx_sys_set_render_cmd(int win_id, int cmd) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return;
    S(g_engine.mailbox.tenants[win_id].render_cmd, cmd);
}

EXPORT void vx_sys_window_size(int win_id, int* w, int* h) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) {
        *w = 0; *h = 0;
        return;
    }
    *w = L(g_engine.mailbox.tenants[win_id].win_w);
    *h = L(g_engine.mailbox.tenants[win_id].win_h);
}
