-- runtime/boot/window_api.lua
local ffi = require("ffi")

local WindowAPI = {}

local curr_keys = {}
local prev_keys = {}
local curr_mouse = {}
local prev_mouse = {}

for i = 0, 3 do
    curr_keys[i] = ffi.new("uint8_t[512]")
    prev_keys[i] = ffi.new("uint8_t[512]")

    curr_mouse[i] = ffi.new("uint8_t[8]")
    prev_mouse[i] = ffi.new("uint8_t[8]")
end

-- [UNIFIED PUMP]
function WindowAPI.pump_input_states(active_tenants)
    for win_id in pairs(active_tenants) do
        -- 1. Snapshot Keyboard
        ffi.copy(prev_keys[win_id], curr_keys[win_id], 512)
        ffi.C.vx_input_poll_keys(win_id, curr_keys[win_id])

        -- 2. Snapshot Mouse (Using the C-Core block-read)
        ffi.copy(prev_mouse[win_id], curr_mouse[win_id], 8)
        ffi.C.vx_input_poll_mouse(win_id, curr_mouse[win_id])
    end
end

-- [KEYBOARD STATES]
function WindowAPI.get_key_state(win_id, keycode)
    if keycode < 0 or keycode >= 512 or not curr_keys[win_id] then return 0 end
    return curr_keys[win_id][keycode]
end

function WindowAPI.is_key_down(win_id, keycode)
    local state = WindowAPI.get_key_state(win_id, keycode)
    return state == 1 or state == 2
end

function WindowAPI.is_key_just_pressed(win_id, keycode)
    if keycode < 0 or keycode >= 512 or not curr_keys[win_id] then return false end
    local curr = curr_keys[win_id][keycode]
    local prev = prev_keys[win_id][keycode]
    return (curr == 1 or curr == 2) and not (prev == 1 or prev == 2)
end

-- [MOUSE STATES]
function WindowAPI.is_mouse_down(win_id, button)
    if button < 0 or button > 7 or not curr_mouse[win_id] then return false end
    return curr_mouse[win_id][button] == 1
end

function WindowAPI.is_mouse_just_pressed(win_id, button)
    if button < 0 or button > 7 or not curr_mouse[win_id] then return false end
    return curr_mouse[win_id][button] == 1 and prev_mouse[win_id][button] == 0
end

function WindowAPI.get_mouse_pos(win_id)
    return ffi.C.vx_input_mouse_x(win_id), ffi.C.vx_input_mouse_y(win_id)
end

function WindowAPI.boot(win_id, w, h)
    ffi.C.vx_sys_set_glfw_cmd(win_id, 1, w, h) -- 1 = OS_CMD_BOOT_WINDOW
end

function WindowAPI.get_surface(win_id)
    return ffi.C.vx_sys_get_surface(win_id)
end

function WindowAPI.destroy(win_id)
    ffi.C.vx_sys_set_glfw_cmd(win_id, 2, 0, 0) -- 2 = OS_CMD_KILL_WINDOW
end

function WindowAPI.get_resize_state(win_id)
    return ffi.C.vx_sys_get_resize_state(win_id) == 1
end

function WindowAPI.trigger_wsi_rebuild(win_id)
    ffi.C.vx_sys_set_render_cmd(win_id, 1) -- 1 = RND_CMD_REBUILD_WSI
end

function WindowAPI.halt_render(win_id)
    ffi.C.vx_sys_set_render_cmd(win_id, 2) -- 2 = RND_CMD_HALT
end

function WindowAPI.inject_tenant(win_id)
    ffi.C.vx_sys_set_render_cmd(win_id, 3) -- 3 = RND_CMD_INJECT_TENANT
end

function WindowAPI.is_tenant_idle(win_id)
    return ffi.C.vx_sys_is_tenant_idle(win_id)
end

function WindowAPI.get_window_size(win_id)
    local _w_ptr = ffi.new("int[1]")
    local _h_ptr = ffi.new("int[1]")
    ffi.C.vx_sys_window_size(win_id, _w_ptr, _h_ptr)
    return _w_ptr[0], _h_ptr[0]
end

function WindowAPI.get_click_pos(win_id)
    return ffi.C.vx_input_click_x(win_id), ffi.C.vx_input_click_y(win_id)
end

function WindowAPI.get_mouse_delta(win_id)
    return ffi.C.vx_input_mouse_dx(win_id), ffi.C.vx_input_mouse_dy(win_id)
end

function WindowAPI.is_captured(win_id)
    return ffi.C.vx_input_is_captured(win_id) == 1
end

return WindowAPI
