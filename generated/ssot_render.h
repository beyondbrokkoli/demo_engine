// AUTO-GENERATED SSoT - DO NOT MODIFY
#pragma once
#include <stdint.h>

// --- GRAPHICS CONSTANTS ---
#define MODE_DUAL 0
#define MODE_GEOM 1
#define MODE_POINT_CLOUD_PASS 88
#define MODE_POINTS 2

// --- MEMORY STRUCTURES ---
typedef struct  {
    VkDevice device;
    VkQueue queue;
    VkQueue transfer_queue;
    VkSwapchainKHR swapchain;
    uint32_t max_frames_in_flight;
    uint8_t _pad_auto_0[4];
    uint64_t swapchain_images[10];
    uint64_t swapchain_views[10];
    VkSemaphore image_available[10];
    VkSemaphore render_finished[10];
    VkFence in_flight[10];
    void* vkWaitForFences;
    void* vkAcquireNextImageKHR;
    void* vkResetFences;
    void* vkQueueSubmit;
    void* vkQueuePresentKHR;
    void* pfnBegin;
    void* pfnEnd;
    void* pfnSetCullMode;
    void* pfnSetFrontFace;
    void* pfnSetPrimitiveTopology;
    void* pfnSetDepthTestEnable;
    void* pfnSetDepthWriteEnable;
    void* pfnSetDepthCompareOp;
} RenderThreadInit;

typedef struct __attribute__((aligned(16))) {
    float px;
    float py;
    float pz;
    uint32_t tile_data;
} RtsTileInstance;

typedef struct __attribute__((aligned(16))) {
    mat4_t viewProj;
    uint32_t aos_current_idx;
    uint32_t aos_prev_idx;
    float dt;
    float total_time;
    uint32_t target_state;
    uint32_t hover_idx;
    uint32_t flags;
    uint8_t _pad_tail[4];
} PushConstants;

typedef struct __attribute__((aligned(64))) {
    uint64_t pipeline_id;
    uint64_t descriptor_set;
    uint32_t index_count;
    uint32_t instance_count;
    uint32_t first_index;
    int32_t vertex_offset;
    uint32_t first_instance;
    uint16_t pc_offset;
    uint16_t pc_size;
    uint8_t push_constants[128];
    int16_t scissor_x;
    int16_t scissor_y;
    uint16_t scissor_w;
    uint16_t scissor_h;
    uint8_t cull_mode;
    uint8_t depth_test;
    uint8_t depth_write;
    uint8_t depth_compare_op;
    uint8_t front_face;
    uint8_t topology;
    uint8_t _pad_tail[10];
} DrawCommand;

typedef struct __attribute__((aligned(64))) {
    DrawCommand* draw_queue;
    uint32_t draw_count;
    uint32_t target_window_id;
    uint64_t gfx_layout;
    uint64_t vertex_buffer;
    uint64_t index_buffer;
    uint64_t swapchain_image;
    uint64_t swapchain_view;
    uint64_t depth_image;
    uint64_t depth_view;
    uint32_t width;
    uint32_t height;
    uint8_t _pad_tail[48];
} RenderPacket;

