-- worlds/luachess/game/logic_pools.lua
local Base = require("worlds.luachess.game.logic_base")

-- ZERO-ALLOCATION RING BUFFERS

-- 1. The List Pool (Replaces table.insert and {})
local LIST_POOL_SIZE = 8192
local list_pool = {}
local list_cursor = 1
for i=1, LIST_POOL_SIZE do list_pool[i] = {} end

local function get_list()
    local l = list_pool[list_cursor]
    list_cursor = (list_cursor % LIST_POOL_SIZE) + 1
    -- Fast-clear the array so `#` operator and ipairs() still work perfectly
    for i=1, #l do l[i] = nil end
    return l
end

-- 2. The Piece Node Pool (Replaces p[l] = { id = s })
local NODE_POOL_SIZE = 8192
local node_pool = {}
local node_cursor = 1
for i=1, NODE_POOL_SIZE do node_pool[i] = {} end

local function get_piece_node(id)
    local n = node_pool[node_cursor]
    node_cursor = (node_cursor % NODE_POOL_SIZE) + 1
    n.id = id
    n.moves = nil
    return n
end

-- 3. The Special Node Pool (Replaces a.id = s and move.castles = ...)
-- We apply the loc metatable so that `move == kingPos` still evaluates correctly!
local SP_POOL_SIZE = 8192
local sp_pool = {}
local sp_cursor = 1
local loc_mt = getmetatable(loc:new(1,1))
for i=1, SP_POOL_SIZE do
    local sp = {}
    setmetatable(sp, loc_mt)
    sp_pool[i] = sp
end

local function get_atk_node(target_loc, id, origin_loc, dir)
    local a = sp_pool[sp_cursor]
    sp_cursor = (sp_cursor % SP_POOL_SIZE) + 1
    a.x = target_loc.x; a.y = target_loc.y
    a.id = id; a.loc = origin_loc; a.dir = dir

    a.castles = nil -- Sanitize ghost state
    a.enpas = nil
    return a
end

local function get_special_move(target_loc, castles_table)
    local sp = sp_pool[sp_cursor]
    sp_cursor = (sp_cursor % SP_POOL_SIZE) + 1
    sp.x = target_loc.x; sp.y = target_loc.y
    sp.castles = castles_table

    sp.id = nil; sp.loc = nil; sp.dir = nil; sp.enpas = nil -- Sanitize ghost state
    return sp
end

return {
    get_list = get_list,
    get_piece_node = get_piece_node,
    get_atk_node = get_atk_node,
    get_special_move = get_special_move
}
