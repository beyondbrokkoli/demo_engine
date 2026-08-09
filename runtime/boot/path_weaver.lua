-- runtime/boot/path_weaver.lua
-- Maps the engine's architectural DAG into Lua's flat module resolver
local roots = {
    "ssot",
    "runtime/boot",
    "runtime/presentation/graphics",
    "runtime/presentation/translation",
    "runtime/services/gpu",
    "runtime/services/math",    -- Ensures fixed_math.lua resolves natively for deterministic state
    "runtime/services/memory",
    "runtime/services/tenants",
    "runtime/shutdown",
    "runtime/simulation",
    "network/lockstep",
    "network/protocol",
    "network/session",
    "network/transport",

    -- The new OOP Chess Domain
    "worlds/luachess",

    "tools"
}

-- Ensure root is checked first (This handles "worlds.isometric.domain")
package.path = "./?.lua;" .. package.path

-- Inject our new DAG into the search path
for i = #roots, 1, -1 do
    package.path = "./" .. roots[i] .. "/?.lua;" .. package.path
end
