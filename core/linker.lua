-- core/linker.lua
local Linker = { registry = {}, instances = {} }

function Linker.register(name, paradigm, loader_fn)
    Linker.registry[name] = { paradigm = paradigm, loader = loader_fn }
end

function Linker.get(name, ...)
    local mod = Linker.registry[name]
    assert(mod, "[LINKER ERROR] Module not found: " .. name)

    if Linker.instances[name] and mod.paradigm ~= "FACTORY" then
        return Linker.instances[name]
    end

    local result
    if mod.paradigm == "DATA" or mod.paradigm == "LIB" then
        result = mod.loader()
    elseif mod.paradigm == "FACADE" then
        result = mod.loader(Linker)
    elseif mod.paradigm == "FACTORY" then
        result = mod.loader(...)
    end

    if mod.paradigm ~= "FACTORY" then
        Linker.instances[name] = result
    end

    return result
end

return Linker
