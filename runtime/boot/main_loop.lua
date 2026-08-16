-- runtime/boot/main_loop.lua
local ffi = require("ffi")
local math = require("math")
local sys_time = require("network.session.sys_time")
local Raycast = require("runtime.simulation.raycast")
local Lifecycle = require("runtime.services.tenants.tenant_lifecycle")
local camera_mod = require("runtime.simulation.camera")

local M = {}

function M.run(deps)
    -- Map injected instances and state
    local EngineAPI = deps.EngineAPI
    local WindowAPI = deps.WindowAPI
    local net_driver = deps.net_driver
    local TenantRegistry = deps.TenantRegistry
    local render_queue = deps.render_queue

    local ctx = deps.ctx
    local net_engine = deps.net_engine
    local visual_canvas = deps.visual_canvas
    local visual_canvas_size = deps.visual_canvas_size
    local vram_template = deps.vram_template
    local memory = deps.memory

    local total_time = 0.0
    local master_ptr = ffi.cast("float*", memory.Mapped["MASTER_GPU_BLOCK"])
    local active_render_mode = deps.cfg_gfx.mode.dual
    local prev_mouse_left = { [0] = false, [1] = false, [2] = false, [3] = false }
    local last_time = sys_time.get_time_hires()

    while EngineAPI.is_running() do
        local current_time = sys_time.get_time_hires()
        local frame_time = math.max(0.001, math.min(current_time - last_time, 0.25))
        last_time = current_time

        local sim_state = net_driver.pump_network(net_engine, frame_time)

        -- [THE TRANSLATION BRIDGE]
        -- 1. Wipe the visual canvas clean (Takes ~0.1ms via FFI memset)
        ffi.fill(visual_canvas, visual_canvas_size, 0)

        -- 2. Paint the 24KB sparse simulation state onto the 3MB visual canvas
        local state = ctx.ssot_render_ptr
        local count = state.modification_count

        -- If the buffer wrapped, the oldest entry is at head_idx. Otherwise, it's at 0.
        local start_idx = (count < 2048) and 0 or state.head_idx

        for i = 0, count - 1 do
            local actual_idx = (start_idx + i) % 2048
            local mod = state.tiles[actual_idx]

            -- We paint everything to Layer 0. The renderer and raycaster don't care about network player layers.
            visual_canvas.terrain[0][mod.tile_idx] = mod.terrain_type
            visual_canvas.elevation[0][mod.tile_idx] = mod.elevation
        end

        local active_win_id = ffi.C.vx_input_get_active_window()

        for win_id in pairs(TenantRegistry.active) do
            if win_id ~= active_win_id then prev_mouse_left[win_id] = false end
        end

        if active_win_id >= 0 and TenantRegistry.active[active_win_id] then
            local tenant = TenantRegistry.active[active_win_id]
            local is_down = WindowAPI.is_mouse_down(active_win_id, 0)

            if is_down and not prev_mouse_left[active_win_id] then
                local click_x, click_y = WindowAPI.get_click_pos(active_win_id)

                -- [POINTER SWAP] Pass visual_canvas instead of ssot_render_ptr
                local clicked_idx = Raycast.matrix_raycast_terrain(
                    click_x, click_y, tenant.width, tenant.height,
                    tenant.inv_vp, visual_canvas, 0
                )
                if clicked_idx ~= 65535 then
                    net_driver.inject_local_command(net_engine, 1, clicked_idx)
                end
            end
            prev_mouse_left[active_win_id] = is_down
        end

        total_time = total_time + frame_time

        for win_id, tenant in pairs(TenantRegistry.active) do
            local skip_render = Lifecycle.process_state_machine(
                win_id, tenant, WindowAPI, EngineAPI, deps.vk_rt, deps.desc, deps.manifest, deps.cfg_gfx, TenantRegistry
            )

            if skip_render then goto continue_tenant end

            if win_id == active_win_id then
                local mouse_x, mouse_y = WindowAPI.get_mouse_pos(win_id)
                camera_mod.update(tenant.cam, frame_time, mouse_x, mouse_y, tenant.width, tenant.height, win_id)
            end

            camera_mod.get_matrices(tenant.cam, tenant.width, tenant.height, tenant.pc.viewProj, tenant.inv_vp)

            local write_idx = EngineAPI.acquire_render_packet(win_id)
            if write_idx == -1 then goto continue_tenant end

            tenant.pc.total_time = total_time
            tenant.pc.dt = frame_time

            -- [POINTER SWAP] Pass visual_canvas instead of ssot_render_ptr
            render_queue.PackFrame(
                tenant, write_idx, tenant.pc, visual_canvas, vram_template,
                ctx.render_queues, active_render_mode, master_ptr, memory,
                tenant.gfx, deps.desc, tenant.sc, ctx.total_tiles, 0
            )

            EngineAPI.commit_render_packet(win_id, write_idx)

            ::continue_tenant::
        end
        sys_time.sleep(1)
    end
end

return M
