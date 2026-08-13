// net_rollback_memory.h - Lockstep Rollback Ring Buffers & Frame Memory
// Contains: NetworkFrame, RollbackBuffer
#pragma once

typedef struct __attribute__((aligned(4))) {
    uint32_t tick;
    uint32_t state_checksum;
    uint32_t remote_checksum;
    uint8_t state;
    uint8_t remote_peer_id;
    uint16_t _pad;
    PlayerCommand commands[CFG_MAX_PLAYERS][2];
} NetworkFrame;

typedef struct __attribute__((aligned(64))) {
    uint32_t head_tick;
    uint32_t confirmed_tick;
    uint32_t rollback_target;
    uint8_t is_rollback_active;
    uint8_t _pad[3];
    NetworkFrame frames[CFG_RING_SIZE];
} RollbackBuffer;
