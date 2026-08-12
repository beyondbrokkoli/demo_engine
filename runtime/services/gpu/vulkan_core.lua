-- runtime/services/gpu/vulkan_core.lua
local InstanceModule = require("runtime.services.gpu.vulkan_core_instance")
local DeviceModule = require("runtime.services.gpu.vulkan_core_device")
local DestroyModule = require("runtime.services.gpu.vulkan_core_destroy")

local core = {}

core.create_instance = InstanceModule.create_instance
core.finalize_device_and_swapchain = DeviceModule.finalize_device_and_swapchain
core.Destroy = DestroyModule.Destroy

return core
