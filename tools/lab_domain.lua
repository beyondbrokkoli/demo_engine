local libJson = require("dkjson")
local function deep_copy(obj)
    if type(obj) ~= "table" then return obj end
    local res = {}
    for k, v in pairs(obj) do res[deep_copy(k)] = deep_copy(v) end
    return res
end
local function deep_compare(t1, t2)
    if type(t1) ~= type(t2) then return false end
    if type(t1) ~= "table" then return t1 == t2 end
    for k, v in pairs(t1) do
        if not deep_compare(v, t2[k]) then return false end
    end
    for k in pairs(t2) do
        if t1[k] == nil then return false end
    end
    return true
end
local function deep_merge(base, overlay)
    if not overlay then return deep_copy(base) end
    local res = deep_copy(base)
    for k, v in pairs(overlay) do
        if type(v) == "table" and type(res[k]) == "table" then
            res[k] = deep_merge(res[k], v)
        else
            if res[k] ~= nil then
                print(string.format("[AUDIT]: Key '%s' override: %s -> %s", k, tostring(res[k]), tostring(v)))
            end
            res[k] = deep_copy(v)
        end
    end
    return res
end
local function walkJson(data, f, depth)
    depth = depth or 0
    local isArray = next(data) == 1
    for k, v in (isArray and ipairs or pairs)(data) do
        if type(v) == "table" then
            f(k, nil, depth, true, isArray)
            walkJson(v, f, depth + 1)
        else f(k, v, depth, false, isArray) end
    end
end
local TopologyMap = {}
function TopologyMap:new(insert)
    local m = {}
    -- internal, protected state
    local _storage = {}

    self.__index = function(self, k)
        -- Return a deep copy so fuzzers/external scripts can't mutate the internal state by reference
        local target = type(k) == "table" and _storage[k.tier][k.slot] or _storage[k]
        return deep_copy(target)
    end

    self.__newindex = function(self, k, v)
        error("[FATAL] Direct mutation forbidden. Use :apply_patch() for state transitions.")
    end

    setmetatable(m, self)

    -- Initialize the grid safely
    for t = lab_domain.bounds.min_tier, lab_domain.bounds.max_tier do
        _storage[t] = {}
        for s = lab_domain.bounds.min_slot, lab_domain.bounds.max_slot do
            _storage[t][s] = type(insert) == "table" and deep_copy(insert) or insert
        end
    end

    -- Expose the raw storage ONLY to authorized internal methods
    rawset(m, "_storage", _storage)
    return m
end
function TopologyMap:apply_patch(tier, slot, overlay_data)
    local current_state = self._storage[tier][slot]

    -- Formal check: Are we actually changing anything?
    if deep_compare(current_state, overlay_data) then
        return false -- No-op, state is identical
    end

    -- deep_merge automatically prints your [AUDIT] logs for delta changes
    local new_state = deep_merge(current_state, overlay_data)
    self._storage[tier][slot] = new_state

    return true
end
function TopologyMap:ingest_json_config(json_string)
    local parsed, pos, err = libJson.decode(json_string)
    if err then
        error(string.format("[FUZZ BLOCK] Malformed JSON at %d: %s", pos, err))
    end

    -- Formal Method Validation: walk the payload and assert invariants
    walkJson(parsed, function(k, v, depth, is_table, is_array)
        -- 1. Defend the boundaries: Catch integer shifts before they disrupt memory
        if type(k) == "number" then
            if k < lab_domain.bounds.min_slot or k > lab_domain.bounds.max_slot then
                error(string.format("[FUZZ BLOCK] Spatial constraint violation. Slot %d is out of bounds.", k))
            end
        end

        -- 2. Enforce strict typing on known keys
        if k == "highlight_mode" and type(v) ~= "string" then
            error(string.format("[FUZZ BLOCK] Type violation on %s. Expected string, got %s", k, type(v)))
        end
    end)

    -- If walkJson completes without throwing an error, the payload is verified safe.
    -- Apply it across the topology.
    for tier_key, tier_data in pairs(parsed) do
        for slot_key, slot_data in pairs(tier_data) do
            self:apply_patch(tier_key, slot_key, slot_data)
        end
    end
end
function TopologyMap:verify_integrity(expected_state_table)
    local is_valid = deep_compare(self._storage, expected_state_table)
    if not is_valid then
        -- Dump state for debugging
        print("[PANIC] Topology state drift detected.")
    end
    return is_valid
end

-- [ADD THIS TO THE VERY BOTTOM]
return {
    deep_copy = deep_copy,
    deep_compare = deep_compare,
    deep_merge = deep_merge,
    walkJson = walkJson,
    TopologyMap = TopologyMap
}
