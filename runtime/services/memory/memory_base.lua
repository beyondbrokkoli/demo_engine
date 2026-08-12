-- [File: runtime/services/memory/memory_base.lua]
local Memory = {
    Buffers = {},
    DeviceMemory = {},
    Mapped = {},
    AVX_Arrays = {},
    TransferSemaphore = nil,
    TimelineValue = 0
}

return Memory
