-- tools/helpers.lua
local helpers = {}

function helpers.get_sorted_keys(t)
    local keys = {}
    for k in pairs(t or {}) do table.insert(keys, k) end
    table.sort(keys)
    return keys
end

function helpers.run_cmd(cmd, strict)
    if strict == nil then strict = true end -- Default to failing fast

    local res = os.execute(cmd)
    local success = (res == true or res == 0)

    if not success and strict then
        print("\n[FATAL] Command failed: " .. cmd)
        os.exit(1)
    end

    return success
end

return helpers
