local InitModule = require("runtime.presentation.graphics.graphics_pipeline_init")
local RuntimeModule = require("runtime.presentation.graphics.graphics_pipeline_runtime")

local GraphicsPipeline = {}

GraphicsPipeline.Init = InitModule.Init
GraphicsPipeline.PumpDeletionQueue = RuntimeModule.PumpDeletionQueue
GraphicsPipeline.HotReloadShaders = RuntimeModule.HotReloadShaders
GraphicsPipeline.Destroy = RuntimeModule.Destroy

return GraphicsPipeline
