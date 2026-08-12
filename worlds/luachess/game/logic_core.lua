-- worlds/luachess/game/logic_core.lua
local Base = require("worlds.luachess.game.logic_base")
local Pools = require("worlds.luachess.game.logic_pools")

local get_list = Pools.get_list

local function findKing(pos,turn)
    local id = hasTurn(8,turn) and 8 or -8
    local kingPos
    do8x8break(pos,function(s,l)
        if s==id then
             kingPos = l
             return true
        end
    end)
    return kingPos
end

local function opponents(a,b)
    if not (a/abs(a)==b/abs(b)) then return true else return false end
end

-- Replaced recursion and table.insert with pooled lists and while loops
local function superVision(l,dir)
    local v = get_list()
    local s = l:move(dir)
    local count = 1
    while s do
        v[count] = s
        count = count + 1
        s = s:move(dir)
    end
    return v
end

local function aligned(a,b)
    for i=1,8 do
        local vision = superVision(a,i)
        for _,square in ipairs(vision) do
            if square==b then return i end
        end
    end
    return false
end

local function castles_free(pos,l,x,y,freshmap,id)
    local ks,qs = false,false
    local kingSpawnY
    if id==8 then kingSpawnY = 1
    elseif id == -8 then kingSpawnY = 8
    else print("ERROR CASTLES ID") end

    if freshmap[5][kingSpawnY] and freshmap[8][kingSpawnY] and pos[7][kingSpawnY]==0 and pos[6][kingSpawnY]==0 then
        ks = get_list()
        ks[1] = loc:new(5,kingSpawnY); ks[2] = loc:new(6,kingSpawnY); ks[3] = loc:new(7,kingSpawnY)
    end
    if freshmap[5][kingSpawnY] and freshmap[1][kingSpawnY] and pos[4][kingSpawnY]==0 and pos[3][kingSpawnY]==0 and pos[2][kingSpawnY]==0 then
        qs = get_list()
        qs[1] = loc:new(5,kingSpawnY); qs[2] = loc:new(4,kingSpawnY); qs[3] = loc:new(3,kingSpawnY)
    end
    return ks,qs
end

local function castles_safe(atk,cs)
    for _,a in pairs(atk) do
        if contains(cs,a) then return false end
    end
    return true
end

local function nextPiece(pos,l,dir)
    local s = l:move(dir)
    while s do
        if pos[s]==0 then s = s:move(dir)
        else return s end
    end
    return false
end

local function reverse(dir)
    local r = dir - 4
    if r <= 0 then return 8 - abs(r) else return r end
end

local function pinned(pos,pc,king)
    local toKing = aligned(pc,king)
    if not toKing then
        return false
    elseif nextPiece(pos,pc,toKing) == king then
        local away = reverse(toKing)
        local otherSide = nextPiece(pos,pc,away)
        if not otherSide then return false end
        local kingID = pos[king]
        if opponents(pos[otherSide],kingID) then
            local enemy = abs(pos[otherSide])
            if (enemy==3 or enemy==4 or enemy==5) and contains(Base._directions[enemy],toKing) then
                local avail = get_list()
                local a_idx = 1
                local s = pc:move(away)
                while not (s==otherSide) do
                    avail[a_idx] = s; a_idx = a_idx + 1
                    s = s:move(away)
                end
                avail[a_idx] = otherSide; a_idx = a_idx + 1
                s = pc:move(toKing)
                while not (s==king) do
                    avail[a_idx] = s; a_idx = a_idx + 1
                    s = s:move(toKing)
                end
                return avail
            end
        end
    end
    return false
end

local function filterPin(mlist,insidePin)
    local filtered = get_list()
    local f_idx = 1
    for i,move in ipairs(mlist) do
        if contains(insidePin,move) then
            filtered[f_idx] = move
            f_idx = f_idx + 1
        end
    end
    return filtered
end

return {
    findKing = findKing,
    opponents = opponents,
    superVision = superVision,
    aligned = aligned,
    castles_free = castles_free,
    castles_safe = castles_safe,
    nextPiece = nextPiece,
    reverse = reverse,
    pinned = pinned,
    filterPin = filterPin
}
