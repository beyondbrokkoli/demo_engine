/* host/state/state_types.c */

/* ── Engine Constants */
// OS-Level Commands (Main Thread)
#define OS_CMD_IDLE          0
#define OS_CMD_BOOT_WINDOW   1
#define OS_CMD_KILL_WINDOW   2

// Render-Level Commands (Render Thread)
#define RND_CMD_IDLE         0
#define RND_CMD_REBUILD_WSI  1
#define RND_CMD_HALT         2
#define RND_CMD_INJECT_TENANT 3  // <-- NEW: Async window injection

#define MAX_WINDOWS          4
#define RING_SIZE            16
#define TRANSFER_RING_SIZE   16

/* ── Core Data Types */
typedef struct {
    _Atomic(void*)  vk_instance;
    _Atomic(void*)  vk_surface;
    _Atomic int     glfw_cmd;
    _Atomic int     render_cmd;  // <-- Decoupled render synchronization channel
    _Atomic int     glfw_arg_w;
    _Atomic int     glfw_arg_h;
    _Atomic int     last_key_pressed;
    _Atomic uint32_t wasd_mask;
    _Atomic float   mouse_dx;
    _Atomic float   mouse_dy;
    _Atomic float   mouse_x;
    _Atomic float   mouse_y;
    _Atomic int     mouse_captured;
    _Atomic int     window_resized;
    _Atomic int     win_w;
    _Atomic int     win_h;
    _Atomic float   click_x;
    _Atomic float   click_y;
    _Atomic int     mouse_left;
    _Atomic int     mouse_right;
    _Atomic int     key_space;
    uint8_t         _pad[36];    // <-- Reduced from 40 to maintain 128 bytes
} TenantMailbox;

_Static_assert(sizeof(TenantMailbox) == 128, "TenantMailbox must prevent false sharing");

typedef struct {
    alignas(64) _Atomic int ready_index;
    _Atomic int is_running;
    _Atomic int lua_finished;
    _Atomic int active_window;
    alignas(64) TenantMailbox tenants[MAX_WINDOWS];
} IPC_Mailbox;

typedef struct {
    IPC_Mailbox mailbox;
    int render_index;
    int write_index;
} EngineState;

typedef struct {
    alignas(64) RenderPacket packets[RING_SIZE];
    alignas(64) _Atomic int  ready_idx[MAX_WINDOWS];
    alignas(64) _Atomic int  local_read[MAX_WINDOWS];
    alignas(64) int          active_ring_slots[MAX_WINDOWS][10];
    alignas(64) _Atomic uint32_t locked_mask;
} RenderRing;

typedef struct {
    uint64_t src_buffer;
    uint64_t dst_buffer;
    uint64_t size;
    uint64_t timeline_sem;
    uint64_t signal_val;
    int      target_window_id;
    uint32_t _pad;
    alignas(64) _Atomic int status;
} TransferJob;
