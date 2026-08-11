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
