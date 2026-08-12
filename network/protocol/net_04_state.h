// net_04_state.h - Game Entities
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
