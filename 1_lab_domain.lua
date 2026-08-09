-- lab_domain replaces hardcoded constants to protect C-FFI memory alignment boundaries
local lab_domain = {
    tiers = { [1] = "v", [2] = "b" },
    bounds = { min_tier = 1, max_tier = 2, min_slot = 0, max_slot = 99 }
}

local function out_of_bounds(t)
    if t.tier < lab_domain.bounds.min_tier or t.tier > lab_domain.bounds.max_tier or 
       t.slot < lab_domain.bounds.min_slot or t.slot > lab_domain.bounds.max_slot then
        return true
    end
    return false
end

-- Replaces 'loc': A generic coordinate vector for network traversal
local Address = {}
function Address:new(tier, slot)
    local l = {}
    l.tier = tier
    l.slot = slot
    setmetatable(l, self)
    self.__index = self

    self.__eq = function(one, two)
        return (one.tier == two.tier) and (one.slot == two.slot)
    end

    self.__add = function(one, two)
        return self:new(one.tier + two.tier, one.slot + two.slot)
    end

    -- Replaces move/v directions: route between nodes seamlessly
    function l:route(t_offset, s_offset)
        local new = self + {tier = t_offset, slot = s_offset}
        return not out_of_bounds(new) and new or false
    end

    -- Translates Address(1, 0) into "v_00_vps" or Address(2, 0) into "b_00_matchmaker"
    function l:format_name(role)
        return string.format("%s_%02d_%s", lab_domain.tiers[self.tier], self.slot, role)
    end

    return l
end

-- Replaces 'Map': Handles the topological state routing
local TopologyMap = {}
function TopologyMap:new(insert)
    local m = {}
    m.storage = {}

    self.__index = function(self, k)
        if type(k) == "table" then
            return self.storage[k.tier][k.slot]
        else
            return self.storage[k]
        end
    end

    self.__newindex = function(self, k, v)
        if type(k) == "table" then
            self.storage[k.tier][k.slot] = v
        else
            self.storage[k] = v
        end
    end

    setmetatable(m, self)

    -- Initialize the grid flexibly based on lab_domain boundaries
    for t = lab_domain.bounds.min_tier, lab_domain.bounds.max_tier do
        m.storage[t] = {}
        for s = lab_domain.bounds.min_slot, lab_domain.bounds.max_slot do
            if type(insert) == "table" then
                -- Deep copy logic with standard debugging defaults
                m.storage[t][s] = {
                    role = insert.role or "empty",
                    ip = insert.ip,
                    highlight_mode = insert.highlight_mode or "subtle"
                }
            else
                m.storage[t][s] = insert
            end
        end
    end

    return m
end

-- Replaces do8x8 / scrollTurn: Traverses the entire active infrastructure
function traverse_topology(pos, filter_role, f)
    for t = lab_domain.bounds.min_tier, lab_domain.bounds.max_tier do
        for s = lab_domain.bounds.min_slot, lab_domain.bounds.max_slot do
            local node_data = pos[t][s]
            if not filter_role or node_data.role == filter_role then
                f(node_data, Address:new(t, s), t, s)
            end
        end
    end
end
