local DELETION_QUEUE_SIZE = 16
local Utils = require("runtime.presentation.graphics.graphics_pipeline_utils")

local GraphicsPipelineRuntime = {}

function GraphicsPipelineRuntime.PumpDeletionQueue(vk, core_state, gfx_state, current_frame)
    local device = type(core_state) == "table" and core_state.device or core_state

    while gfx_state.d_tail ~= gfx_state.d_head do
        local item = gfx_state.deletion_queue[gfx_state.d_tail]
        if current_frame < item.frame_target then break end

        for _, pipe in pairs(item.pipelines) do vk.vkDestroyPipeline(device, pipe, nil) end
        for _, mod in pairs(item.modules) do vk.vkDestroyShaderModule(device, mod, nil) end

        item.pipelines = {}
        item.modules = {}
        item.active = false
        gfx_state.d_tail = (gfx_state.d_tail + 1) % DELETION_QUEUE_SIZE
    end
end

function GraphicsPipelineRuntime.HotReloadShaders(vk, core_state, gfx_state, current_frame)
    local device = core_state.device
    local item = gfx_state.deletion_queue[gfx_state.d_head]

    item.active = true
    item.frame_target = current_frame + 4
    for k, v in pairs(gfx_state.pipelines) do item.pipelines[k] = v end
    for k, v in pairs(gfx_state.modules) do item.modules[k] = v end

    gfx_state.d_head = (gfx_state.d_head + 1) % DELETION_QUEUE_SIZE

    gfx_state.pipelines = {}
    gfx_state.modules = {}

    for name, cfg in pairs(gfx_state.configs) do
        if not gfx_state.modules[cfg.vert] then gfx_state.modules[cfg.vert] = Utils.createShaderModule(vk, device, cfg.vert) end
        if not gfx_state.modules[cfg.frag] then gfx_state.modules[cfg.frag] = Utils.createShaderModule(vk, device, cfg.frag) end

        gfx_state.pipelines[name] = Utils.BuildSinglePipeline(vk, device, gfx_state.pipelineLayout, gfx_state.colorFormat, gfx_state.modules[cfg.vert], gfx_state.modules[cfg.frag], cfg)
    end
end

function GraphicsPipelineRuntime.Destroy(vk, core_state, gfx_state)
    print("[TEARDOWN] Destroying Graphics Pipelines, Depth Buffer & ID Buffer...")
    if not gfx_state then return end
    local device = type(core_state) == "table" and core_state.device or core_state

    -- [UPDATED] Flush local tenant queue instead of global
    while gfx_state.d_tail ~= gfx_state.d_head do
        local item = gfx_state.deletion_queue[gfx_state.d_tail]
        for _, pipe in pairs(item.pipelines) do vk.vkDestroyPipeline(device, pipe, nil) end
        for _, mod in pairs(item.modules) do vk.vkDestroyShaderModule(device, mod, nil) end
        gfx_state.d_tail = (gfx_state.d_tail + 1) % DELETION_QUEUE_SIZE
    end

    for _, pipe in pairs(gfx_state.pipelines) do vk.vkDestroyPipeline(device, pipe, nil) end
    for _, mod in pairs(gfx_state.modules) do vk.vkDestroyShaderModule(device, mod, nil) end

    if gfx_state.depthImageView then vk.vkDestroyImageView(device, gfx_state.depthImageView, nil) end
    if gfx_state.depthImage then vk.vkDestroyImage(device, gfx_state.depthImage, nil) end
    if gfx_state.depthMemory then vk.vkFreeMemory(device, gfx_state.depthMemory, nil) end
end

return GraphicsPipelineRuntime
