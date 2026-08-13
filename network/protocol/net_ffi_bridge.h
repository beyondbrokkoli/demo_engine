// net_ffi_bridge.h - Host IPC & C/Lua FFI Network Bridge API
// Contains: vx_net_* host functions and memory layout assertions
#pragma once

int vx_net_host(int port);
int vx_net_connect(uint8_t peer_id, const char* ip, int port);
void vx_net_set_session(uint64_t token);
void vx_net_set_player_id(uint8_t id);
int vx_net_recv_all(RxPacket* out_buffer, int max_count);
void vx_net_send_to(void* data, size_t len, uint8_t target_peer);
void vx_net_set_relay_ip(const char* ip);
uint32_t vx_net_hash_state(const void* data, size_t length, uint32_t initial_hash);
int vx_net_stun_punch(const char* stun_server_ip, int stun_port, char* out_ip, int* out_port);
void vx_net_shutdown(void);

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
    _Static_assert(sizeof(PlayerCommand) == 8, "[FATAL] PlayerCommand must be exactly 8 bytes!");
    _Static_assert(sizeof(IcePunchPacket) == 40, "[FATAL] IcePunchPacket must be exactly 40 bytes!");
    _Static_assert(_Alignof(LockstepPacket) == 1, "[FATAL] LockstepPacket is not 1-byte aligned!");
#endif
