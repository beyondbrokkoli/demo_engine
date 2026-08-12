// net_01_constants.h - The Constellation
#pragma once
#include <stdint.h>
#include <stddef.h>

enum {
    CFG_MAX_PLAYERS = 8,
    CFG_HISTORY_LEN = 30,      // Tied to LOOKAHEAD_CAP
    CFG_RING_SIZE = 512,
    CFG_MAX_PACKET_SIZE = 4096,

    FRAME_STATE_EMPTY = 0,
    FRAME_STATE_PREDICTED = 1,
    FRAME_STATE_CONFIRMED = 2
};
