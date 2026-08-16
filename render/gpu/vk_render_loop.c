/* host/vk_render_loop.c */

THREAD_FUNC render_thread_loop(void* arg) {
    uint32_t t_frame[MAX_WINDOWS] = {0};

    while (L(g_render_thread_active) && L(g_engine.mailbox.is_running)) {
        for (int w = 0; w < MAX_WINDOWS; w++) {

            // 1. Poll the new decoupled render channel using your macro
            int cmd = L(g_engine.mailbox.tenants[w].render_cmd);

            // 2. Handle BOTH Rebuild and Halt commands
            if (cmd == RND_CMD_REBUILD_WSI || cmd == RND_CMD_HALT) {
                int timeout = 2000;
                int spin_count = 0;

                // Wait for any in-flight memory transfers
                while (L(g_transfer_busy[w]) && timeout > 0) {
                    if (spin_count >= 2000) { timeout--; }
                    vx_spin_wait(&spin_count);
                }

                RenderThreadInit* wsi = &g_window_wsi[w];
                if (wsi->device) {
                    // Gracefully idle this specific tenant's queues
                    if (wsi->queue) {
                        vkQueueWaitIdle(wsi->queue);
                    }
                    if (wsi->transfer_queue) {
                        vkQueueWaitIdle(wsi->transfer_queue);
                    }

                    if (g_render_cmd_pools[w]) {
                       vkResetCommandPool(wsi->device, g_render_cmd_pools[w], 0);
                    }
                    if (g_transfer_cmd_pools[w]) {
                        vkResetCommandPool(wsi->device, g_transfer_cmd_pools[w], 0);
                    }
                }

                // Suspend rendering for this tenant so it skips submission below
                S(g_wsi_state[w], 0);

                if (cmd == RND_CMD_REBUILD_WSI) {
                    // Only reset resize state if we are actually rebuilding
                    S(g_engine.mailbox.tenants[w].window_resized, 0);
                }

                // 3. Reset the RENDER command, leaving the OS command untouched
                S(g_engine.mailbox.tenants[w].render_cmd, RND_CMD_IDLE);
            }
        }
        for (int wid = 0; wid < MAX_WINDOWS; wid++) {
            int ready          = L(g_ring.ready_idx[wid]);
            int local_read_val = L(g_ring.local_read[wid]);
            if (ready == -1 || ready == local_read_val) {
                continue;
            }
            int offset = wid * 4;
            int new_local_read;
            if (local_read_val == -1) {
                new_local_read = offset + 0;
            } else {
                int curr_local = local_read_val - offset;
                new_local_read = offset + ((curr_local + 1) % 4);
            }
            S(g_ring.local_read[wid], new_local_read);
            int read_idx = new_local_read;
            RenderPacket*     p       = &g_ring.packets[read_idx];
            S(g_render_busy[wid], 1);
            RenderThreadInit* win_wsi = &g_window_wsi[wid];
            uint32_t frame_slots = win_wsi->max_frames_in_flight > 0
                                   ? win_wsi->max_frames_in_flight : 3;
            if (frame_slots > 3) frame_slots = 3;
            uint32_t current_frame  = t_frame[wid] % frame_slots;
            int      finished_slot  = g_ring.active_ring_slots[wid][current_frame];
            if (finished_slot != -1 && finished_slot != read_idx) {
                FA(g_ring.locked_mask, ~(1u << finished_slot));
            }
            g_ring.active_ring_slots[wid][current_frame] = read_idx;
            if (L(g_wsi_state[wid]) == 0 ||
                p->width == 0 || p->height == 0) {
                goto frame_done;
            }
            VkCommandBuffer cmd_buf = g_render_cmd_buffers[wid][current_frame];
            PFN_vkWaitForFences pfnWait =
                (PFN_vkWaitForFences)win_wsi->vkWaitForFences;
            VkResult wait_res = pfnWait(win_wsi->device, 1,
                &win_wsi->in_flight[current_frame], VK_TRUE, 2000000000);
            if (wait_res == VK_TIMEOUT) {
                printf("[C-WARN] Tenant %d: GPU Fence Timeout "
                       "(CPU Starvation). Dropping frame to maintain "
                       "lock parity.\n", wid);
                goto frame_done;
            }
            PFN_vkAcquireNextImageKHR pfnAcquire =
                (PFN_vkAcquireNextImageKHR)win_wsi->vkAcquireNextImageKHR;
            uint32_t img_idx;
            VkResult res = pfnAcquire(win_wsi->device, win_wsi->swapchain,
                5000000, win_wsi->image_available[current_frame],
                VK_NULL_HANDLE, &img_idx);
            if (res == VK_TIMEOUT || res == VK_NOT_READY) {
                goto frame_done;
            }
            if (res == VK_ERROR_OUT_OF_DATE_KHR) {
                S(g_engine.mailbox.tenants[wid].window_resized, 1);
                SLEEP_MS(10);
                goto frame_done;
            }
            PFN_vkResetFences pfnReset =
                (PFN_vkResetFences)win_wsi->vkResetFences;
            pfnReset(win_wsi->device, 1,
                     &win_wsi->in_flight[current_frame]);
            p->swapchain_image = win_wsi->swapchain_images[img_idx];
            p->swapchain_view  = win_wsi->swapchain_views[img_idx];
            vkResetCommandBuffer(cmd_buf, 0);
            vx_record_commands(cmd_buf, p, p->draw_queue,
                               p->draw_count, win_wsi);
            VkPipelineStageFlags waitStage =
                VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
            VkSubmitInfo submitInfo = {
                .sType                = VK_STRUCTURE_TYPE_SUBMIT_INFO,
                .waitSemaphoreCount   = 1,
                .pWaitSemaphores      = &win_wsi->image_available[current_frame],
                .pWaitDstStageMask    = &waitStage,
                .commandBufferCount   = 1,
                .pCommandBuffers      = &cmd_buf,
                .signalSemaphoreCount = 1,
                .pSignalSemaphores    = &win_wsi->render_finished[img_idx]
            };
            PFN_vkQueueSubmit pfnSubmit =
                (PFN_vkQueueSubmit)win_wsi->vkQueueSubmit;
            pfnSubmit(win_wsi->queue, 1, &submitInfo,
                      win_wsi->in_flight[current_frame]);
            VkPresentInfoKHR presentInfo = {
                .sType              = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
                .waitSemaphoreCount = 1,
                .pWaitSemaphores    = &win_wsi->render_finished[img_idx],
                .swapchainCount     = 1,
                .pSwapchains        = &win_wsi->swapchain,
                .pImageIndices      = &img_idx
            };
            PFN_vkQueuePresentKHR pfnPresent =
                (PFN_vkQueuePresentKHR)win_wsi->vkQueuePresentKHR;
            pfnPresent(win_wsi->queue, &presentInfo);
        frame_done:
            S(g_render_busy[wid], 0);
            t_frame[wid] = (current_frame + 1) % frame_slots;
        }
        SLEEP_MS(1);
    }

    return NULL;
}
