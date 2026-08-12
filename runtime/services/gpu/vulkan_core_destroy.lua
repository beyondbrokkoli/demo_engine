local EngineAPI = require("runtime.boot.engine_api")

local Destroy = {}

function Destroy.Destroy(vk_state, gfx_cfg)
    print("[TEARDOWN] Shutting down Vulkan Core...")
    local vk = vk_state.vk
    if vk_state.device ~= nil then vk.vkDestroyDevice(vk_state.device, nil) end
    -- [DELETED]: The legacy surface destroy is gone.
    if vk_state.instance ~= nil then
        if gfx_cfg.use_validation == 1 then EngineAPI.eject_validation(vk_state.instance) end
        vk.vkDestroyInstance(vk_state.instance, nil)
    end
end

return Destroy
