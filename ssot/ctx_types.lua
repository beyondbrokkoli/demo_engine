-- ssot/ctx_types.lua
local compile_layouts = require("ssot.compile_layouts")

local function get_compiled_registry()
    local specs = {}
    local type_sizes = {
        float = 4, uint32_t = 4, int32_t = 4,
        uint64_t = 8, int64_t = 8,
        uint16_t = 2, int16_t = 2,
        uint8_t = 1, int8_t = 1
    }

    for _, s in ipairs(require("ssot.type_math")) do table.insert(specs, s) end
    for _, s in ipairs(require("ssot.type_render")) do table.insert(specs, s) end

    -- compile_layouts mutates 'specs' with padding/alignment
    -- and returns the raw C string for FFI.
    local cdef_str = compile_layouts(specs, type_sizes)

    return specs, cdef_str
end

return get_compiled_registry
