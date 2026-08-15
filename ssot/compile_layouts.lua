-- ssot/compile_layouts.lua
local function get_base_size(type_str, type_sizes)
    -- 1. Check known structs first
    if type_sizes[type_str] then return type_sizes[type_str] end

    -- 2. Explicit patterns to avoid substring collisions (e.g. Hash32Data)
    if string.find(type_str, "*", 1, true) then return 8 end -- Pointers
    if string.match(type_str, "64_t$") then return 8 end
    if string.match(type_str, "32_t$") or type_str == "float" then return 4 end
    if string.match(type_str, "16_t$") then return 2 end
    if string.match(type_str, "8_t$") then return 1 end

    -- 3. Engine/API specific prefixes
    if string.match(type_str, "^Vk") or string.match(type_str, "^PFN_") then return 8 end

    error("[FATAL INVARIANT] Unknown type size requested in SSoT Compiler: " .. tostring(type_str))
end

local function resolve_padding(struct, offset, member_align)
    local effective_align = member_align
    if struct.layout.mode == "std430" then
        local max_align = struct.layout.max_member_align or 16
        effective_align = math.min(effective_align, max_align)
    end

    local rem = offset % effective_align
    if rem ~= 0 then
        local pad_bytes = effective_align - rem
        return pad_bytes, offset + pad_bytes
    end
    return 0, offset
end

local function resolve_tail_padding(struct, offset, safe_align)
    local rem = offset % safe_align
    if rem ~= 0 then
        local tail_pad = safe_align - rem
        return tail_pad, offset + tail_pad
    end
    return 0, offset
end

return function(specs, type_sizes)
    local cdef_builder = ""

    for _, struct in ipairs(specs) do
        assert(struct.targets ~= nil, "[FATAL] " .. struct.name .. " MUST define 'targets'")
        assert(struct.layout ~= nil, "[FATAL] " .. struct.name .. " MUST define 'layout'")
        assert(struct.layout.mode ~= nil, "[FATAL] " .. struct.name .. " MUST define 'layout.mode'")

        local safe_align = struct.layout.align or struct.align or 8
        if struct.layout.mode == "std430" then
            safe_align = math.max(safe_align, 16)
        end

        struct.computed_align = safe_align

        local attr = ""
        if struct.layout.mode == "aligned" or struct.layout.mode == "std430" then
            attr = string.format("__attribute__((aligned(%d)))", safe_align)
        end
        cdef_builder = cdef_builder .. string.format("typedef struct %s {\n", attr)

        local offset = 0
        local pad_id = 0
        local compiled_members = {}

        for _, m in ipairs(struct.members) do
            local m_size = get_base_size(m.type, type_sizes)
            local m_align = m_size

            if struct.layout.mode == "std430" then
                if m.type == "mat4_t" then m_align = 16 end
                if m_align > 16 then m_align = 16 end
            end

            local pad_bytes, new_offset = resolve_padding(struct, offset, m_align)
            if pad_bytes > 0 then
                table.insert(compiled_members, { type = "uint8_t", name = "_pad_auto_" .. pad_id, count = pad_bytes, is_pad = true })
                cdef_builder = cdef_builder .. string.format("    uint8_t _pad_auto_%d[%d];\n", pad_id, pad_bytes)
                offset = new_offset
                pad_id = pad_id + 1
            end

            table.insert(compiled_members, m)

            local element_count = 1
            local arr_str = ""
            if type(m.count) == "table" then
                for _, dim in ipairs(m.count) do
                    arr_str = arr_str .. string.format("[%d]", dim)
                    element_count = element_count * dim
                end
            elseif m.count then
                arr_str = string.format("[%d]", m.count)
                element_count = m.count
            end

            local ffi_type = m.type
            if string.sub(ffi_type, 1, 2) == "Vk" or string.sub(ffi_type, 1, 4) == "PFN_" then ffi_type = "void*" end
            cdef_builder = cdef_builder .. string.format("    %s %s%s;\n", ffi_type, m.name, arr_str)

            offset = offset + (type_sizes[m.type] and type_sizes[m.type] * element_count or m_size * element_count)
        end

        local tail_pad, final_offset = resolve_tail_padding(struct, offset, safe_align)
        if tail_pad > 0 then
            table.insert(compiled_members, { type = "uint8_t", name = "_pad_tail", count = tail_pad, is_pad = true })
            cdef_builder = cdef_builder .. string.format("    uint8_t _pad_tail[%d];\n", tail_pad)
            offset = final_offset
        end

        struct.members = compiled_members
        cdef_builder = cdef_builder .. "} " .. struct.name .. ";\n\n"
        type_sizes[struct.name] = offset
    end

    return cdef_builder
end
