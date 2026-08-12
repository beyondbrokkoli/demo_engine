/* network/transport/vx_net_stun.c */
#include "vx_net_internal.h"

EXPORT int vx_net_stun_punch(const char* stun_server_ip, int stun_port, char* out_ip, int* out_port) {
    if (g_net.sock == NET_INVALID) return 0;

    struct sockaddr_in stun_addr = {0};
    stun_addr.sin_family = AF_INET;
    stun_addr.sin_port = htons((uint16_t)stun_port);
    inet_pton(AF_INET, stun_server_ip, &stun_addr.sin_addr);

    uint8_t req[20] = {0};
    req[0] = 0x00; req[1] = 0x01;
    req[4] = 0x21; req[5] = 0x12; req[6] = 0xA4; req[7] = 0x42;
    for(int i = 8; i < 20; i++) req[i] = i;

    sendto(g_net.sock, (const char*)req, 20, 0, (struct sockaddr*)&stun_addr, sizeof(stun_addr));

    uint8_t resp[1024];
    struct sockaddr_in from;
    socklen_t from_len = sizeof(from);

    for (int wait = 0; wait < 50; wait++) {
        ssize_t recvd = recvfrom(g_net.sock, (char*)resp, sizeof(resp), 0, (struct sockaddr*)&from, &from_len);
        if (recvd >= 20) {
            uint16_t msg_len = (resp[2] << 8) | resp[3];
            int offset = 20;
            while (offset < 20 + msg_len && offset + 4 <= recvd) {
                uint16_t attr_type = (resp[offset] << 8) | resp[offset+1];
                uint16_t attr_len = (resp[offset+2] << 8) | resp[offset+3];

                if (attr_type == 0x0020) {
                    if (attr_len >= 8 && (offset + 12) <= recvd) {
                        uint8_t family = resp[offset+5];
                        if (family == 0x01) {
                            uint16_t xport = (resp[offset+6] << 8) | resp[offset+7];
                            uint32_t xip = (resp[offset+8] << 24) | (resp[offset+9] << 16) | (resp[offset+10] << 8) | resp[offset+11];

                            *out_port = xport ^ 0x2112;
                            uint32_t real_ip = xip ^ 0x2112A442;
                            snprintf(out_ip, 16, "%d.%d.%d.%d", (real_ip >> 24) & 0xFF, (real_ip >> 16) & 0xFF, (real_ip >> 8) & 0xFF, real_ip & 0xFF);
                            return 1;
                        }
                    }
                }
                int padded_len = (attr_len + 3) & ~3;
                offset += 4 + padded_len;
            }
        }
#if defined(_WIN32)
        Sleep(10);
#else
        usleep(10000);
#endif
    }
    return 0;
}
