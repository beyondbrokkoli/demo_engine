-- [File: runtime/services/memory/memory.lua]
local Memory = require("runtime.services.memory.memory_base")
local Alloc = require("runtime.services.memory.memory_alloc")
local Transfer = require("runtime.services.memory.memory_transfer")

-- Bind Allocation Subsystem
Memory.CreateHostVisibleBuffer = Alloc.CreateHostVisibleBuffer
Memory.AllocateSoA = Alloc.AllocateSoA
Memory.CreateBufferHaven = Alloc.CreateBufferHaven
Memory.FreeSoA = Alloc.FreeSoA
Memory.DestroyBuffer = Alloc.DestroyBuffer

-- Bind Transfer Subsystem
Memory.InitTransferSubsystem = Transfer.InitTransferSubsystem
Memory.TransferAsync = Transfer.TransferAsync
Memory.IsTransferComplete = Transfer.IsTransferComplete
Memory.DestroyTransferSubsystem = Transfer.DestroyTransferSubsystem

return Memory
