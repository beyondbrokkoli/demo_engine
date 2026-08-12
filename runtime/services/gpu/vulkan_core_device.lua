local ffi = require("ffi")
local bit = require("bit")
local reg = require("runtime.services.gpu.registry_vk")
local vk_struct = reg.vk_struct
local vk_queue = reg.vk_queue

local Device = {}

function Device.finalize_device_and_swapchain(vk_state, surface_ptr, req_extensions)
    print("[LUA] Resuming Vulkan Setup. Finalizing Logical Device...")
    local vk = vk_state.vk
    local instance = vk_state.instance

    local pDeviceCount = ffi.new("uint32_t[1]")
    vk.vkEnumeratePhysicalDevices(instance, pDeviceCount, nil)
    local pDevices = ffi.new("VkPhysicalDevice[?]", pDeviceCount[0])
    vk.vkEnumeratePhysicalDevices(instance, pDeviceCount, pDevices)
    local physicalDevice = pDevices[0]
    vk_state.physicalDevice = physicalDevice

    local pQueueFamilyCount = ffi.new("uint32_t[1]")
    vk.vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, pQueueFamilyCount, nil)
    local queueFamilies = ffi.new("VkQueueFamilyProperties[?]", pQueueFamilyCount[0])
    vk.vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, pQueueFamilyCount, queueFamilies)

    local qIndex = -1
    local tIndex = -1

    for i = 0, pQueueFamilyCount[0] - 1 do
        local flags = queueFamilies[i].queueFlags
        if bit.band(flags, vk_queue.graphics) ~= 0 and qIndex == -1 then
            qIndex = i
        end
        if bit.band(flags, vk_queue.transfer) ~= 0 and bit.band(flags, vk_queue.graphics) == 0 then
            tIndex = i
        end
    end

    if tIndex == -1 then
        print("[LUA] No dedicated Transfer queue found. Sharing Graphics queue.")
        tIndex = qIndex
    else
        print("[LUA] Dedicated Transfer queue located at index: " .. tIndex)
    end

    vk_state.qIndex = qIndex
    vk_state.tIndex = tIndex

    local queuePriority = ffi.new("float[1]", 1.0)
    local queueCount = (qIndex == tIndex) and 1 or 2
    local queueCreateInfos = ffi.new("VkDeviceQueueCreateInfo[2]")

    queueCreateInfos[0].sType = vk_struct.device_queue_create
    queueCreateInfos[0].queueFamilyIndex = qIndex
    queueCreateInfos[0].queueCount = 1
    queueCreateInfos[0].pQueuePriorities = queuePriority

    if queueCount == 2 then
        queueCreateInfos[1].sType = vk_struct.device_queue_create
        queueCreateInfos[1].queueFamilyIndex = tIndex
        queueCreateInfos[1].queueCount = 1
        queueCreateInfos[1].pQueuePriorities = queuePriority
    end

    local ext_count = #req_extensions
    local deviceExtensions = ffi.new("const char*[?]", ext_count)
    for i, ext in ipairs(req_extensions) do deviceExtensions[i-1] = ext end

    local dynamicRendering = ffi.new("VkPhysicalDeviceDynamicRenderingFeatures")
    ffi.fill(dynamicRendering, ffi.sizeof(dynamicRendering))
    dynamicRendering.sType = vk_struct.dynamic_rendering_features
    dynamicRendering.dynamicRendering = 1

    local extDynamicState = ffi.new("VkPhysicalDeviceExtendedDynamicStateFeaturesEXT")
    ffi.fill(extDynamicState, ffi.sizeof(extDynamicState))
    extDynamicState.sType = vk_struct.extended_dynamic_state_features
    extDynamicState.pNext = dynamicRendering
    extDynamicState.extendedDynamicState = 1

    local extDynamicState2 = ffi.new("VkPhysicalDeviceExtendedDynamicState2FeaturesEXT")
    ffi.fill(extDynamicState2, ffi.sizeof(extDynamicState2))
    extDynamicState2.sType = vk_struct.extended_dynamic_state2_features
    extDynamicState2.pNext = extDynamicState
    extDynamicState2.extendedDynamicState2 = 1

    local timelineFeat = ffi.new("VkPhysicalDeviceTimelineSemaphoreFeatures")
    ffi.fill(timelineFeat, ffi.sizeof(timelineFeat))
    timelineFeat.sType = 1000207000
    timelineFeat.timelineSemaphore = 1
    timelineFeat.pNext = extDynamicState2

    local deviceFeatures = ffi.new("VkPhysicalDeviceFeatures")
    ffi.fill(deviceFeatures, ffi.sizeof(deviceFeatures))
    deviceFeatures.largePoints = 1
    deviceFeatures.independentBlend = 1

    local deviceCreateInfo = ffi.new("VkDeviceCreateInfo")
    ffi.fill(deviceCreateInfo, ffi.sizeof(deviceCreateInfo))
    deviceCreateInfo.sType = vk_struct.device_create
    deviceCreateInfo.pNext = timelineFeat

    deviceCreateInfo.queueCreateInfoCount = queueCount;
    deviceCreateInfo.pQueueCreateInfos = queueCreateInfos;
    deviceCreateInfo.enabledExtensionCount = ext_count;

    deviceCreateInfo.ppEnabledExtensionNames = deviceExtensions
    deviceCreateInfo.pEnabledFeatures = deviceFeatures

    local pDevice = ffi.new("VkDevice[1]")
    assert(vk.vkCreateDevice(physicalDevice, deviceCreateInfo, nil, pDevice) == 0, "FATAL: vkCreateDevice failed!")

    vk_state.device = pDevice[0]
    print("[LUA] Logical Device Created!")

    local pQueue = ffi.new("VkQueue[1]")
    vk.vkGetDeviceQueue(vk_state.device, qIndex, 0, pQueue)
    vk_state.queue = pQueue[0]

    local pTransferQueue = ffi.new("VkQueue[1]")
    vk.vkGetDeviceQueue(vk_state.device, tIndex, 0, pTransferQueue)
    vk_state.transferQueue = pTransferQueue[0]

    return vk_state
end

return Device
