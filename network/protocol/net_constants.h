// net_constants.h - Network Protocol Constants & Frame States
// Contains: CFG_MAX_PLAYERS, CFG_HISTORY_LEN, CFG_RING_SIZE, CFG_MAX_PACKET_SIZE, FRAME_STATE_*
#pragma once
#include <stdint.h>
#include <stddef.h>

enum {
    CFG_MAX_PLAYERS = 8,
    CFG_HISTORY_LEN = 15,      // Tied to LOOKAHEAD_CAP
    CFG_RING_SIZE = 512,
    CFG_MAX_PACKET_SIZE = 4096,

    FRAME_STATE_EMPTY = 0,
    FRAME_STATE_PREDICTED = 1,
    FRAME_STATE_CONFIRMED = 2
};
