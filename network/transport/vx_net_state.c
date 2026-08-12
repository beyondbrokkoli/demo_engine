/* network/transport/vx_net_state.c */
#include "vx_net_internal.h"

NetContext g_net = {
    .sock = NET_INVALID,
    .session_token = 0,
    .local_id = 0
};

uint32_t g_relay_ip_addr = 0;

#if defined(_WIN32)
static int net_wsa_initialized = 0;
#endif

static inline int net_set_nonblocking(int sock) {
#if defined(_WIN32)
    u_long mode = 1;
    return ioctlsocket(sock, FIONBIO, &mode) == 0 ? 0 : -1;
#else
    int flags = fcntl(sock, F_GETFL, 0);
    return (flags < 0) ? -1 : fcntl(sock, F_SETFL, flags | O_NONBLOCK);
#endif
}

static inline void net_cleanup_platform(void) {
#if defined(_WIN32)
    if (net_wsa_initialized) {
        WSACleanup();
        net_wsa_initialized = 0;
    }
#endif
}

static inline int net_init_platform(void) {
#if defined(_WIN32)
    if (!net_wsa_initialized) {
        WSADATA wsa;
        if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) return -1;
        net_wsa_initialized = 1;
    }
#endif
    return 0;
}

EXPORT void vx_net_set_relay_ip(const char* ip) {
    if (ip) g_relay_ip_addr = inet_addr(ip);
}

EXPORT void vx_net_shutdown(void) {
    if (g_net.sock != NET_INVALID) {
        NET_CLOSE(g_net.sock);
        g_net.sock = NET_INVALID;
    }
    net_cleanup_platform();
}

EXPORT int vx_net_host(int port) {
    if (g_net.sock != NET_INVALID) vx_net_shutdown();
    if (net_init_platform() < 0) return -1;

    vx_socket_t sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock == NET_INVALID) return -1;

    int opt = 1;
    int buf_size = 1024 * 1024;
#if defined(_WIN32)
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (const char*)&opt, sizeof(opt));
    setsockopt(sock, SOL_SOCKET, SO_RCVBUF, (const char*)&buf_size, sizeof(buf_size));
    setsockopt(sock, SOL_SOCKET, SO_SNDBUF, (const char*)&buf_size, sizeof(buf_size));
#else
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    setsockopt(sock, SOL_SOCKET, SO_RCVBUF, &buf_size, sizeof(buf_size));
    setsockopt(sock, SOL_SOCKET, SO_SNDBUF, &buf_size, sizeof(buf_size));
#endif

    if (net_set_nonblocking(sock) < 0) {
        NET_CLOSE(sock);
        return -1;
    }

    struct sockaddr_in local = {0};
    local.sin_family = AF_INET;
    local.sin_addr.s_addr = htonl(INADDR_ANY);
    local.sin_port = htons((uint16_t)port);

    if (bind(sock, (struct sockaddr*)&local, sizeof(local)) == NET_ERROR) {
        NET_CLOSE(sock);
        return -1;
    }

    struct sockaddr_in bound_addr;
    socklen_t len = sizeof(bound_addr);
    if (getsockname(sock, (struct sockaddr*)&bound_addr, &len) == NET_ERROR) {
        NET_CLOSE(sock);
        return -1;
    }

#if defined(_WIN32)
    DWORD dwBytesReturned = 0;
    BOOL bNewBehavior = FALSE;
    WSAIoctl(sock, SIO_UDP_CONNRESET, &bNewBehavior, sizeof(bNewBehavior), NULL, 0, &dwBytesReturned, NULL, NULL);
#endif

    g_net.sock = sock;
    return ntohs(bound_addr.sin_port);
}

EXPORT int vx_net_connect(uint8_t peer_id, const char* ip, int port) {
    if (g_net.sock == NET_INVALID || !ip || peer_id >= 8) return -1;

    g_net.peers[peer_id].addr.sin_family = AF_INET;
    g_net.peers[peer_id].addr.sin_port = htons((uint16_t)port);

    if (inet_pton(AF_INET, ip, &g_net.peers[peer_id].addr.sin_addr) <= 0) {
        struct hostent* he = gethostbyname(ip);
        if (!he || he->h_addrtype != AF_INET) return -1;
        memcpy(&g_net.peers[peer_id].addr.sin_addr, he->h_addr_list[0], he->h_length);
    }

    g_net.peers[peer_id].addr_len = sizeof(struct sockaddr_in);
    g_net.peers[peer_id].active = 1;
    return 0;
}

EXPORT void vx_net_set_session(uint64_t token) { g_net.session_token = token; }
EXPORT void vx_net_set_player_id(uint8_t id) { g_net.local_id = id; }
