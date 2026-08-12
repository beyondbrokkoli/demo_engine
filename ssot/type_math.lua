return function(ctx)
    local specs = {
        {
            name = "vec4_t", align = 16,
            c_only = false, vk_shield = false, wire_format = false, force_align = true, glsl_std430 = true,
            members = {
                { type = "float", name = "x" },
                { type = "float", name = "y" },
                { type = "float", name = "z" },
                { type = "float", name = "w" }
            }
        },
        {
            name = "mat4_t", align = 16,
            c_only = false, vk_shield = false, wire_format = false, force_align = true, glsl_std430 = true,
            members = {
                { type = "float", name = "m", count = 16 }
            }
        }
    }

    for _, s in ipairs(specs) do
        s.domain = "sim"
        table.insert(ctx.specs, s)
    end
end
