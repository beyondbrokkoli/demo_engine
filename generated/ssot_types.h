// AUTO-GENERATED SSoT - DO NOT MODIFY
#pragma once
#include <stdint.h>

// --- SIMULATION CONSTANTS ---
#define WORLD_GRID_CELLS 262144
#define WORLD_MAP_HEIGHT 256
#define WORLD_MAP_WIDTH 256
#define WORLD_OFFSET_X 2560
#define WORLD_OFFSET_Z 2560
#define WORLD_SPACING 20

// --- MEMORY STRUCTURES ---
typedef struct __attribute__((aligned(16))) {
    float x;
    float y;
    float z;
    float w;
} vec4_t;

typedef struct __attribute__((aligned(16))) {
    float m[16];
} mat4_t;

