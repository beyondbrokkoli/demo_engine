return function(ctx)
    local specs = {
        {
            name = "vec4_t",
            targets = { c = true, glsl = true, wire = false },
            layout = { mode = "std430", align = 16 },
            members = {
                { type = "float", name = "x" },
                { type = "float", name = "y" },
                { type = "float", name = "z" },
                { type = "float", name = "w" }
            }
        },
        {
            name = "mat4_t",
            targets = { c = true, glsl = true, wire = false },
            layout = { mode = "std430", align = 16 },
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
