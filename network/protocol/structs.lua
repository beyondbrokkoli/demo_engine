-- lua/structs.lua
local ffi = require("ffi")

local M = {}

local function load_brutalist_structs()
    local chunk_files = {
        "network/protocol/net_01_constants.h",
        "network/protocol/net_02_wire.h",
        "network/protocol/net_03_memory.h",
        "network/protocol/net_04_state.h",
        "network/protocol/net_05_api.h"
    }

    local full_c_code = ""

    for _, filepath in ipairs(chunk_files) do
        local file = assert(io.open(filepath, "r"), "[FATAL] Missing " .. filepath)
        full_c_code = full_c_code .. "\n" .. file:read("*a")
        file:close()
    end

    -- Scrub preprocessor macros so LuaJIT doesn't choke
    full_c_code = full_c_code:gsub("#[^\n]*\n", "\n")
    -- Scrub C11 Static asserts
    full_c_code = full_c_code:gsub("_Static_assert%([^;]-%);", "")

    -- Parse the concatenated, clean C structures
    ffi.cdef(full_c_code)
end

-- Run immediately
load_brutalist_structs()

-- Tenet II: The Sterile Tick (Weaponized)
function M.zero_memory(ffi_struct_ptr, struct_name)
    local size = ffi.sizeof(struct_name)
    ffi.fill(ffi_struct_ptr, size, 0)
end

return M
