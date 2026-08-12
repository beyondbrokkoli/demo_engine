local ffi = require("ffi")
require("runtime.services.gpu.vulkan_headers")

local success, lib = pcall(ffi.load, "vulkan-1")
if not success then success, lib = pcall(ffi.load, "vulkan") end
if not success then success, lib = pcall(ffi.load, "libvulkan.so.1") end
assert(success, "FATAL: Could not load Vulkan!")

return lib
