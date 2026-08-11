/* tenant/tenant_callbacks_state.c */

/* ── File-Local State (Strictly isolated to callbacks) */
static bool    s_is_fullscreen[MAX_WINDOWS] = {false};
static int     s_win_x[MAX_WINDOWS] = {0};
static int     s_win_y[MAX_WINDOWS] = {0};
static int     s_win_w[MAX_WINDOWS] = {1280};
static int     s_win_h[MAX_WINDOWS] = {720};

static double  last_mx[MAX_WINDOWS] = {0.0};
static double  last_my[MAX_WINDOWS] = {0.0};
static bool    first_mouse[MAX_WINDOWS] = {true, true, true, true};

static atomic_flag s_mouse_lock = ATOMIC_FLAG_INIT; // Preserved for future God Buffer

void glfw_framebuffer_size_callback(GLFWwindow* window, int width, int height) {
    if (width == 0 || height == 0) return;
    int id = (int)(intptr_t)glfwGetWindowUserPointer(window);
    if (id < 0 || id >= MAX_WINDOWS) return;

    S(g_engine.mailbox.tenants[id].win_w, width);
    S(g_engine.mailbox.tenants[id].win_h, height);
    S(g_engine.mailbox.tenants[id].window_resized, 1);
}
