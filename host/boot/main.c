/* host/main.c */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <stdatomic.h>
#include <stdalign.h>
#include <pthread.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>
#include <vulkan/vulkan.h>
#ifdef _WIN32
    #define WIN32_LEAN_AND_MEAN
    #define NOMINMAX
    #include <windows.h>
    #include <timeapi.h>
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #pragma comment(lib, "winmm.lib")
#else
    #include <sys/socket.h>
    #include <netinet/in.h>
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <fcntl.h>
#endif
#define VX_ENABLE_VULKAN_STRUCTS

/* ── Engine Includes ── */
#include "../../generated/ssot_types.h"
#include "../../generated/ssot_render.h"
#include "../ipc/sys_sync.c"
#include "../state/state_types.c"
#include "../state/state_globals.c"
#include "../threading/thread_pool.c"
#include "../ipc/mailbox.c"
#include "lifecycle.c"
#include "../ipc/ring_stream.c"
#include "../tenant/tenant_callbacks_state.c"
#include "../tenant/tenant_callbacks_mouse.c"
#include "../tenant/tenant_callbacks_key.c"
#include "../tenant/tenant_input.c"
#include "../tenant/tenant_sys.c"
#include "../../render/debug/vk_debug.c"
#include "../../render/tenant/vk_tenant_alloc.c"
#include "../../render/transfer/vk_transfer_api.c"
#include "../../render/transfer/vk_transfer_loop.c"
#include "../../render/gpu/vk_draw.c"
#include "../../render/gpu/vk_record.c"
#include "../../render/gpu/vk_render_loop.c"
#include "../threading/thread_lifecycle.c"
// --- NEW: Global argument capture for the Unity Build ---
int g_host_argc;
char** g_host_argv;
#include "../lua/lua_vm.c"

/* ── Main Entry Point & GLFW Event Loop ── */
#include "../runtime/main_loop.c"
