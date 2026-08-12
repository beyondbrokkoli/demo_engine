-- [File: runtime/services/memory/memory_transfer.lua]
local ffi = require("ffi")
local reg = require("runtime.services.gpu.registry_vk")
local Memory = require("runtime.services.memory.memory_base")

local Transfer = {}

function Transfer.InitTransferSubsystem(core_state)
    local typeInfo = ffi.new("VkSemaphoreTypeCreateInfo", {
        sType = 1000207002, -- VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO
        semaphoreType = 1,  -- VK_SEMAPHORE_TYPE_TIMELINE [FIXED] This MUST be 1
        initialValue = 0
    })
    local semInfo = ffi.new("VkSemaphoreCreateInfo")
    semInfo.sType = reg.vk_struct.semaphore_create
    semInfo.pNext = typeInfo

    local pSem = ffi.new("VkSemaphore[1]")
    assert(core_state.vk.vkCreateSemaphore(core_state.device, semInfo, nil, pSem) == 0)
    Memory.TransferSemaphore = pSem[0]
    print("[MEMORY] Timeline Semaphore forged for Async Transfers.")
end

function Transfer.TransferAsync(win_id, src_name, dst_name, byte_size)
    local src = Memory.Buffers[src_name]
    local dst = Memory.Buffers[dst_name]
    assert(src and dst, "FATAL: Invalid transfer buffers")

    Memory.TimelineValue = Memory.TimelineValue + 1

    local success = ffi.C.vx_transfer_request(
        win_id, -- [TRIFORCE PATCH] Explicitly route to a tenant's command pool
        ffi.cast("uint64_t", src),
        ffi.cast("uint64_t", dst),
        byte_size,
        ffi.cast("uint64_t", Memory.TransferSemaphore),
        Memory.TimelineValue
    )

    if success == 1 then
        print(string.format("[TRANSFER] Job dispatched: %s -> %s (Target Timeline: %d)", src_name, dst_name, Memory.TimelineValue))
        return Memory.TimelineValue
    else
        print("[TRANSFER] WARNING: Mailbox full! Transfer dropped.")
        Memory.TimelineValue = Memory.TimelineValue - 1
        return -1
    end
end

function Transfer.IsTransferComplete(core_state, target_value)
    local pValue = ffi.new("uint64_t[1]")
    core_state.vk.vkGetSemaphoreCounterValue(core_state.device, Memory.TransferSemaphore, pValue)
    return tonumber(pValue[0]) >= target_value
end

function Transfer.DestroyTransferSubsystem(core_state)
    if Memory.TransferSemaphore ~= nil then
        core_state.vk.vkDestroySemaphore(core_state.device, Memory.TransferSemaphore, nil)
        Memory.TransferSemaphore = nil
        print("[TEARDOWN] Timeline Semaphore destroyed.")
    end
end

return Transfer
