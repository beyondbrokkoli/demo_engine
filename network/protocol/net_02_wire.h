// net_02_wire.h - Packet Definitions
#pragma once
#pragma pack(push, 1)

typedef struct {
    uint32_t target_pos;
    uint16_t target_id;
    uint8_t opcode;
    uint8_t flags;
} PlayerCommand;

typedef struct {
    uint64_t session_token;
    uint8_t player_id;
    uint8_t is_ping;
    uint8_t history_count;
    uint8_t _reserved;
    uint32_t frame_tick;
    uint32_t checksum_tick;
    uint32_t state_checksum;
    uint32_t base_tick;
    uint32_t peer_acks[CFG_MAX_PLAYERS];
    PlayerCommand commands[CFG_HISTORY_LEN][2];
} LockstepPacket;

typedef struct {
    uint64_t session_token;
    uint8_t player_id;
    uint8_t is_ping;
    uint16_t _reserved16;
    uint32_t frame_tick;
    uint32_t checksum_tick;
    uint32_t state_checksum;
    uint32_t base_tick;
    uint32_t padding[3];
} IcePunchPacket;

#pragma pack(pop)

typedef struct {
    uint16_t len;
    uint8_t data[CFG_MAX_PACKET_SIZE];
} RxPacket;
