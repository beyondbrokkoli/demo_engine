local ffi = require("ffi")
local reg = require("runtime.services.gpu.registry_vk")
local EngineAPI = require("runtime.boot.engine_api")
local vk_struct = reg.vk_struct
local vk = require("runtime.services.gpu.vulkan_core_loader")

local Instance = {}

function Instance.create_instance(req_extensions, gfx_cfg)
    print("[LUA] Initializing Vulkan Core (Instance Generation)...")
    local pCount = ffi.new("uint32_t[1]")
    local glfwExtensions = EngineAPI.get_glfw_extensions(pCount)
    local exts_count = pCount[0]
    local total_exts = exts_count + #req_extensions

    if gfx_cfg.use_validation == 1 then total_exts = total_exts + 1 end

    local instanceExtensions = ffi.new("const char*[?]", total_exts)
    for i = 0, exts_count - 1 do instanceExtensions[i] = glfwExtensions[i] end

    local ext_idx = exts_count
    for _, ext in ipairs(req_extensions) do
        instanceExtensions[ext_idx] = ext
        ext_idx = ext_idx + 1
    end

    local validationLayers = nil
    local layerCount = 0
    if gfx_cfg.use_validation == 1 then
        instanceExtensions[ext_idx] = "VK_EXT_debug_utils"
        validationLayers = ffi.new("const char*[1]", {"VK_LAYER_KHRONOS_validation"})
        layerCount = 1
        print("[LUA] Validation Layers ENABLED.")
    else
        print("[LUA] Validation Layers DISABLED. Running raw.")
    end

    local appInfo = ffi.new("VkApplicationInfo", {
        sType = vk_struct.app_info,
        pApplicationName = "VX Engine Runtime",
        apiVersion = gfx_cfg.vk_api_version
    })

    local createInfo = ffi.new("VkInstanceCreateInfo", {
        sType = vk_struct.instance_create,
        pApplicationInfo = appInfo,
        enabledExtensionCount = total_exts,
        ppEnabledExtensionNames = instanceExtensions,
        enabledLayerCount = layerCount,
        ppEnabledLayerNames = validationLayers
    })

    local pInstance = ffi.new("VkInstance[1]")
    assert(vk.vkCreateInstance(createInfo, nil, pInstance) == 0, "FATAL: vkCreateInstance failed!")

    local instance = pInstance[0]
    if gfx_cfg.use_validation == 1 then EngineAPI.inject_validation(instance) end

    return { vk = vk, instance = instance }
end

return Instance
