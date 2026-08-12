-- [File: runtime/services/memory/memory_platform.lua]
local ffi = require("ffi")

local is_windows = (ffi.os == "Windows")
if is_windows then
    ffi.cdef[[
        void* _aligned_malloc(size_t size, size_t alignment);
        void _aligned_free(void* ptr);
    ]]
else
    ffi.cdef[[
        void* aligned_alloc(size_t alignment, size_t size);
        void free(void* ptr);
    ]]
end

ffi.cdef[[
    typedef struct {
        uint32_t sType;
        void* pNext;
        uint32_t semaphoreType;
        uint64_t initialValue;
    } VkSemaphoreTypeCreateInfo;

    int vkGetSemaphoreCounterValue(VkDevice device, VkSemaphore semaphore, uint64_t* pValue);
]]

local Platform = {}

function Platform.aligned_alloc(alignment, size)
    if is_windows then return ffi.C._aligned_malloc(size, alignment)
    else return ffi.C.aligned_alloc(alignment, size) end
end

function Platform.aligned_free(ptr)
    if is_windows then ffi.C._aligned_free(ptr)
    else ffi.C.free(ptr) end
end

return Platform
