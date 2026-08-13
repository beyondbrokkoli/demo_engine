-- build/net_codegen.lua
local TIER = arg[1] or "medium"

local TIERS = {
    optimal = 15,
    medium  = 30,
    legacy  = 60
}

local lookahead = assert(TIERS[TIER], "[FATAL] Invalid tier. Use optimal, medium, or legacy.")

-- 1. CALCULATE CONSTELLATION
local CFG_MAX_PLAYERS = 8
local CFG_RING_SIZE = 512
local CFG_MAX_PACKET_SIZE = 4096

local lockstep_size = 60 + (lookahead * 16)

-- 2. ASSERT INVARIANTS
assert(lookahead < (CFG_RING_SIZE / 4), "[FATAL] Lookahead exceeds safe ring buffer wrapping limits!")
assert(lockstep_size <= 1200, "[FATAL] Packet size exceeds safe MTU thresholds! UDP fragmentation imminent.")

print(string.format("[CODEGEN] Scaling Network Tier: %s (%d-tick lookahead)", TIER:upper(), lookahead))
print(string.format("[CODEGEN] LockstepPacket size reduced to %d bytes", lockstep_size))

-- 3. CHUNK DEFINITIONS
local chunks = {}

-- Config & Constants
chunks["net_constants.h"] = string.format([[
// net_constants.h - Network Protocol Constants & Frame States
// Contains: CFG_MAX_PLAYERS, CFG_HISTORY_LEN, CFG_RING_SIZE, CFG_MAX_PACKET_SIZE, FRAME_STATE_*
#pragma once
#include <stdint.h>
#include <stddef.h>

enum {
    CFG_MAX_PLAYERS = %d,
    CFG_HISTORY_LEN = %d,      // Tied to LOOKAHEAD_CAP
    CFG_RING_SIZE = %d,
    CFG_MAX_PACKET_SIZE = %d,

    FRAME_STATE_EMPTY = 0,
    FRAME_STATE_PREDICTED = 1,
    FRAME_STATE_CONFIRMED = 2
};
]], CFG_MAX_PLAYERS, lookahead, CFG_RING_SIZE, CFG_MAX_PACKET_SIZE)

-- Wire Packets & Commands
chunks["net_wire_packets.h"] = [[
// net_wire_packets.h - Wire Protocol, Packets & Input Commands
// Contains: PlayerCommand, LockstepPacket, IcePunchPacket, RxPacket
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
]]

-- Ring Buffers & Memory Layout
chunks["net_rollback_memory.h"] = [[
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
]]

-- Game World State Data
chunks["net_world_state.h"] = [[
// net_world_state.h - Game Entities & Deterministic Simulation World State
// Contains: LabChessState, LabPlayerEntity, LabWorldState
#pragma once

typedef struct {
    int8_t grid[64];
    uint8_t flags;
    uint8_t en_passant;
    uint16_t halfmove;
    uint32_t history[100];
} LabChessState;

typedef struct {
    int32_t x;
    int32_t y;
    uint32_t status;
} LabPlayerEntity;

typedef struct __attribute__((aligned(8))) {
    uint32_t global_tick;
    LabPlayerEntity players[CFG_MAX_PLAYERS];
    LabChessState chess;
} LabWorldState;
]]

-- C Host API / FFI Bridge
chunks["net_ffi_bridge.h"] = [[
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
]]

-- 4. FORGE THE FILES
local function write_file(filename, content)
    local f = assert(io.open("network/protocol/" .. filename, "w"))
    f:write(content)
    f:close()
end

for filename, content in pairs(chunks) do
    write_file(filename, content)
end

-- 5. GENERATE THE UMBRELLA HEADER (For the C-Compiler)
local umbrella = [[
// c/shared_structs.h - PURE BRUTALIST NETCODE (UMBRELLA)
// AUTO-GENERATED BY build/net_codegen.lua
#pragma once
#include "net_constants.h"
#include "net_wire_packets.h"
#include "net_rollback_memory.h"
#include "net_world_state.h"
#include "net_ffi_bridge.h"
]]
write_file("shared_structs.h", umbrella)

print("[CODEGEN] Chunked structs successfully forged. Architecture split into 5 domain files.")
