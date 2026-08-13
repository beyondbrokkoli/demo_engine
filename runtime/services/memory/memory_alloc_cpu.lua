-- [File: runtime/services/memory/memory_alloc_cpu.lua]
local ffi = require("ffi")

local Memory = require("runtime.services.memory.memory_base")
local Platform = require("runtime.services.memory.memory_platform")

local AllocCPU = {}

function AllocCPU.AllocateSoA(type_str, count, names)
    local base_type = string.gsub(type_str, "%[.-%]", "")
    local byte_size = ffi.sizeof(base_type) * count
    local align_bytes = 32

    for i = 1, #names do
        local raw_ptr = Platform.aligned_alloc(align_bytes, byte_size)
        assert(raw_ptr ~= nil, "FATAL: C-Allocator failed to provide aligned memory!")
        Memory.AVX_Arrays[names[i]] = ffi.cast(base_type .. "*", raw_ptr)
        print(string.format("[MEMORY] Allocated Fast CPU RAM: %s (%.2f MB)", names[i], byte_size / (1024*1024)))
    end
end

function AllocCPU.FreeSoA(names)
    for i = 1, #names do
        local ptr = Memory.AVX_Arrays[names[i]]
        if ptr then
            Platform.aligned_free(ptr)
            Memory.AVX_Arrays[names[i]] = nil
        end
    end
end

return AllocCPU
