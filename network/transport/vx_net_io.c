/* network/transport/vx_net_io.c */
#include "vx_net_internal.h"

EXPORT uint32_t vx_net_hash_state(const void* data, size_t length, uint32_t initial_hash) {
    const uint8_t* bytes = (const uint8_t*)data;
    uint32_t hash = (initial_hash == 0) ? 0x811C9DC5 : initial_hash;
    for (size_t i = 0; i < length; ++i) {
        hash ^= bytes[i];
        hash *= 0x01000193;
    }
    return hash;
}

EXPORT void vx_net_send_to(void* data, size_t len, uint8_t target_peer) {
    if (g_net.sock == NET_INVALID || !data || target_peer >= 8) return;
    if (!g_net.peers[target_peer].active) return;

    sendto(g_net.sock, (const char*)data, len, 0,
           (struct sockaddr*)&g_net.peers[target_peer].addr,
           g_net.peers[target_peer].addr_len);
}

EXPORT int vx_net_recv_all(RxPacket* out_buffer, int max_count) {
    if (g_net.sock == NET_INVALID || !out_buffer) return 0;
    struct sockaddr_in from;
    socklen_t from_len = sizeof(from);
    int count = 0;

    while (count < max_count) {
        ssize_t recvd = recvfrom(g_net.sock,
                                 (char*)out_buffer[count].data,
                                 CFG_MAX_PACKET_SIZE,
                                 0,
                                 (struct sockaddr*)&from,
                                 &from_len);

        if (recvd < 0) break;

        uint8_t pid = 255;
        uint64_t token = 0;

        if (recvd == sizeof(IcePunchPacket)) {
            IcePunchPacket* punch = (IcePunchPacket*)out_buffer[count].data;
            token = punch->session_token;
            pid = punch->player_id;
        } else if (recvd >= offsetof(LockstepPacket, commands)) {
            LockstepPacket* lockstep = (LockstepPacket*)out_buffer[count].data;
            token = lockstep->session_token;
            pid = lockstep->player_id;
        } else {
            continue;
        }

        if (token != g_net.session_token) continue;

        if (pid < 8 && from.sin_addr.s_addr != g_relay_ip_addr) {
            g_net.peers[pid].addr = from;
            g_net.peers[pid].addr_len = from_len;
            g_net.peers[pid].active = 1;
        }

        out_buffer[count].len = (uint16_t)recvd;
        count++;
    }
    return count;
}
