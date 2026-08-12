local ffi = require("ffi")
local bit = require("bit")
local reg = require("runtime.services.gpu.registry_vk")
local vk_struct = reg.vk_struct
local vk_format, vk_image, vk_layout = reg.vk_format, reg.vk_image, reg.vk_layout

local Utils = require("runtime.presentation.graphics.graphics_pipeline_utils")

local GraphicsPipelineInit = {}

local DELETION_QUEUE_SIZE = 16

function GraphicsPipelineInit.Init(vk, core_state, width, height, pipelineLayout, colorFormat, configs)
    print("[GRAPHICS] Building Reverse-Z Depth Buffer and Shader Modules...")
    local device = core_state.device

    -- 1. Create Depth Image (Mechanism preserved)
    local dImgInfo = ffi.new("VkImageCreateInfo")
    ffi.fill(dImgInfo, ffi.sizeof(dImgInfo))
    dImgInfo.sType = vk_struct.image_create
    dImgInfo.imageType = vk_image.type_2d; dImgInfo.extent.width = width; dImgInfo.extent.height = height; dImgInfo.extent.depth = 1
    dImgInfo.mipLevels = 1; dImgInfo.arrayLayers = 1; dImgInfo.format = vk_format.d32_sfloat; dImgInfo.tiling = vk_image.tiling_optimal
    dImgInfo.initialLayout = vk_layout.undefined; dImgInfo.usage = vk_image.usage_depth_attachment; dImgInfo.samples = vk_image.sample_count_1

    local pDepthImage = ffi.new("VkImage[1]")
    assert(vk.vkCreateImage(device, dImgInfo, nil, pDepthImage) == 0)

    local memReqs = ffi.new("VkMemoryRequirements")
    vk.vkGetImageMemoryRequirements(device, pDepthImage[0], memReqs)
    local memProperties = ffi.new("VkPhysicalDeviceMemoryProperties")
    vk.vkGetPhysicalDeviceMemoryProperties(core_state.physicalDevice, memProperties)
    local memoryTypeIndex = -1
    for i = 0, memProperties.memoryTypeCount - 1 do
        if bit.band(memReqs.memoryTypeBits, bit.lshift(1, i)) ~= 0 and bit.band(memProperties.memoryTypes[i].propertyFlags, 1) ~= 0 then
            memoryTypeIndex = i; break
        end
    end

    local dAllocInfo = ffi.new("VkMemoryAllocateInfo", { sType = vk_struct.mem_alloc, allocationSize = memReqs.size, memoryTypeIndex = memoryTypeIndex })
    local pDepthMemory = ffi.new("VkDeviceMemory[1]"); assert(vk.vkAllocateMemory(device, dAllocInfo, nil, pDepthMemory) == 0)
    assert(vk.vkBindImageMemory(device, pDepthImage[0], pDepthMemory[0], 0) == 0)

    local dViewInfo = ffi.new("VkImageViewCreateInfo", {
        sType = vk_struct.image_view_create, image = pDepthImage[0], viewType = vk_image.view_type_2d, format = vk_format.d32_sfloat,
        subresourceRange = { aspectMask = vk_image.aspect_depth, levelCount = 1, layerCount = 1 }
    })
    local pDepthView = ffi.new("VkImageView[1]"); assert(vk.vkCreateImageView(device, dViewInfo, nil, pDepthView) == 0)

    -- [FIX APPLIED] Embed the queue inside the returned instance state
    local state = {
        depthImage = pDepthImage[0], depthMemory = pDepthMemory[0], depthImageView = pDepthView[0],
        pipelineLayout = pipelineLayout, colorFormat = colorFormat,
        pipelines = {}, modules = {}, configs = configs,
        deletion_queue = {},
        d_head = 0,
        d_tail = 0
    }

    -- Initialize the isolated queue
    for i = 0, DELETION_QUEUE_SIZE - 1 do
        state.deletion_queue[i] = { active = false, frame_target = 0, pipelines = {}, modules = {} }
    end

    for name, cfg in pairs(configs) do
        if not state.modules[cfg.vert] then state.modules[cfg.vert] = Utils.createShaderModule(vk, device, cfg.vert) end
        if not state.modules[cfg.frag] then state.modules[cfg.frag] = Utils.createShaderModule(vk, device, cfg.frag) end
        state.pipelines[name] = Utils.BuildSinglePipeline(vk, device, pipelineLayout, colorFormat, state.modules[cfg.vert], state.modules[cfg.frag], cfg)
    end

    return state
end

return GraphicsPipelineInit
