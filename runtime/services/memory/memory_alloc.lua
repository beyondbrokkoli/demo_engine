-- [File: runtime/services/memory/memory_alloc.lua]
local Alloc = {}

local gpu = require("runtime.services.memory.memory_alloc_gpu")
local cpu = require("runtime.services.memory.memory_alloc_cpu")

-- Bind Vulkan / GPU Memory Functions
Alloc.CreateHostVisibleBuffer = gpu.CreateHostVisibleBuffer
Alloc.CreateBufferHaven       = gpu.CreateBufferHaven
Alloc.DestroyBuffer           = gpu.DestroyBuffer

-- Bind CPU / SoA Memory Functions
Alloc.AllocateSoA             = cpu.AllocateSoA
Alloc.FreeSoA                 = cpu.FreeSoA

return Alloc
