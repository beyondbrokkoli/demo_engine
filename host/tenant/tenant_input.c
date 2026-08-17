/* tenant/tenant_input.c */

// --- NEW GOD BUFFER READS ---
EXPORT int vx_input_key_state(int win_id, int key) {
    if (win_id < 0 || win_id >= MAX_WINDOWS || key < 0 || key >= 512) return 0;
    return L(g_engine.mailbox.tenants[win_id].keys[key]);
}

EXPORT void vx_input_poll_keys(int win_id, uint8_t* out_buffer) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return;
    for(int i = 0; i < 512; i++) {
        out_buffer[i] = L(g_engine.mailbox.tenants[win_id].keys[i]);
    }
}

EXPORT int vx_input_get_active_window(void) {
    return L(g_engine.mailbox.active_window);
}

EXPORT int vx_input_mouse_btn(int win_id, int btn) {
    if (win_id < 0 || win_id >= MAX_WINDOWS || btn < 0 || btn >= 8) return 0;
    return L(g_engine.mailbox.tenants[win_id].mouse_btns[btn]);
}

// --- NEW POLL FUNCTION ---
EXPORT void vx_input_poll_mouse(int win_id, uint8_t* out_buffer) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return;
    for(int i = 0; i < 8; i++) {
        out_buffer[i] = L(g_engine.mailbox.tenants[win_id].mouse_btns[i]);
    }
}

EXPORT float vx_input_mouse_x(int win_id) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return 0.0f;
    return L(g_engine.mailbox.tenants[win_id].mouse_x);
}

EXPORT float vx_input_mouse_y(int win_id) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return 0.0f;
    return L(g_engine.mailbox.tenants[win_id].mouse_y);
}

EXPORT float vx_input_click_x(int win_id) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return -1.0f;
    return L(g_engine.mailbox.tenants[win_id].click_x);
}

EXPORT float vx_input_click_y(int win_id) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return -1.0f;
    return L(g_engine.mailbox.tenants[win_id].click_y);
}

EXPORT int vx_input_is_captured(int win_id) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return 0;
    return L(g_engine.mailbox.tenants[win_id].mouse_captured);
}

EXPORT float vx_input_mouse_dx(int win_id) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return 0.0f;
    return E_A(g_engine.mailbox.tenants[win_id].mouse_dx, 0.0f);
}

EXPORT float vx_input_mouse_dy(int win_id) {
    if (win_id < 0 || win_id >= MAX_WINDOWS) return 0.0f;
    return E_A(g_engine.mailbox.tenants[win_id].mouse_dy, 0.0f);
}

