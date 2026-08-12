-- worlds/luachess/game/logic_gen.lua
local Base = require("worlds.luachess.game.logic_base")
local Pools = require("worlds.luachess.game.logic_pools")
local Core = require("worlds.luachess.game.logic_core")

local directions = Base._directions
local get_list = Pools.get_list
local get_piece_node = Pools.get_piece_node
local get_atk_node = Pools.get_atk_node
local get_special_move = Pools.get_special_move

local findKing = Core.findKing
local castles_free = Core.castles_free
local castles_safe = Core.castles_safe
local pinned = Core.pinned
local filterPin = Core.filterPin

local function attackgen(position,turn)
    local atk = get_list()
    local pos = Map:copy(position)
    local kingPos = findKing(pos,turn+1)
    pos[kingPos] = 0

    local atk_idx = 1
    scrollTurn(pos,turn,function(s,l)
        local abs_s = abs(s)
        if abs_s == 1 then
            local moves = pawnAT(pos,l)
            for _,m in ipairs(moves) do
                atk[atk_idx] = get_atk_node(m, s, l, m.dir)
                atk_idx = atk_idx + 1
            end
        elseif abs_s == 2 then
            local moves = knightAT(pos,l)
            for _,m in ipairs(moves) do
                atk[atk_idx] = get_atk_node(m, s, l, m.dir)
                atk_idx = atk_idx + 1
            end
        elseif abs_s >= 3 and abs_s <= 5 then
            for _,d in ipairs(directions[abs_s]) do
                local mlist = visionAT(pos,l,d)
                for _,m in ipairs(mlist) do
                    atk[atk_idx] = get_atk_node(m, s, l, d)
                    atk_idx = atk_idx + 1
                end
            end
        elseif abs_s == 8 then
            local moves = kingAT(pos,l)
            for _,m in ipairs(moves) do
                atk[atk_idx] = get_atk_node(m, s, l, m.dir)
                atk_idx = atk_idx + 1
            end
        end
    end)
    return atk
end

local function possible(pos,turn,freshmap,eptoken)
    local enpasMap
    if eptoken then
        enpasMap = Map:new(0)
        do8x8(pos,function(s,l) enpasMap[l] = s end)
        enpasMap[eptoken] = eptoken.id
    end
    local p = Map:new(false)
    scrollTurn(pos,turn,function(s,l,x,y)
        local abs_s = abs(s)
        local node = get_piece_node(s)

        if abs_s == 1 then
            node.moves = pawnM(enpasMap or pos,l,freshmap[l])
        elseif abs_s == 2 then
            node.moves = knightM(pos,l)
        elseif abs_s >= 3 and abs_s <= 5 then
            local moves = get_list()
            local m_idx = 1
            for _,d in ipairs(directions[abs_s]) do
                local mlist = visionM(pos,l,d)
                for _,m in ipairs(mlist) do
                    moves[m_idx] = m
                    m_idx = m_idx + 1
                end
            end
            node.moves = moves
        elseif abs_s == 8 then
            local atk = attackgen(pos,turn+1)
            node.moves = kingM(pos,l,atk)
            local ks, qs = castles_free(pos,l,x,y,freshmap,s)

            if ks and castles_safe(atk,ks) then
                local c_info = get_list()
                c_info[1] = loc:new(8,y); c_info[2] = ks[2]
                node.moves[#node.moves+1] = get_special_move(loc:new(7,y), c_info)
            end
            if qs and castles_safe(atk,qs) then
                local c_info = get_list()
                c_info[1] = loc:new(1,y); c_info[2] = qs[2]
                node.moves[#node.moves+1] = get_special_move(loc:new(3,y), c_info)
            end
        end
        p[l] = node
    end)

    local kingPos = findKing(pos,turn)
    scrollTurn(pos,turn,function(s,l)
        local pin = pinned(pos,l,kingPos)
        if pin then
            p[l].moves = filterPin(p[l].moves,pin)
        end
    end)
    return p
end

local function inCheck(pos,turn,freshmap,eptoken)
    local check = false
    local available = Map:new(false)
    local oppAT = attackgen(pos,turn+1)
    local kingPos = findKing(pos,turn)

    for i,move in ipairs(oppAT) do
        if move == kingPos then
            if check then
                local escape = kingM(pos,kingPos,oppAT)
                if #escape==0 then
                    return true,false,true
                else
                    available = Map:new(false)
                    local knode = get_piece_node(pos[kingPos])
                    knode.moves = escape
                    available[kingPos] = knode
                    return true, available, true
                end
            end
            check = true
            local P = possible(pos,turn,freshmap,eptoken)
            local kill, blocks = false, false

            do8x8(P,function(pc,l,x,y)
                if pc and not (abs(pc.id)==8) then
                    if contains(pc.moves, move.loc) then
                        kill = true
                        if not available[l] then
                            available[l] = get_piece_node(pc.id)
                            available[l].moves = get_list()
                        end
                        local mlist = available[l].moves
                        mlist[#mlist+1] = move.loc
                    end
                end
            end)

            if abs(move.id) > 2 then
                blocks = get_list()
                local b_idx = 1
                local _r = i - 1
                while _r>0 and oppAT[_r].dir == move.dir and oppAT[_r].loc == move.loc do
                    blocks[b_idx] = oppAT[_r]
                    b_idx = b_idx + 1
                    _r = _r - 1
                end

                if b_idx == 1 then
                    blocks = false
                else
                    local block_avail = false
                    do8x8(P,function(pc,l)
                        if pc and not (abs(pc.id)==8) then
                            for _,b in ipairs(blocks) do
                                if contains(pc.moves, b) then
                                    block_avail = true
                                    if not available[l] then
                                        available[l] = get_piece_node(pos[l])
                                        available[l].moves = get_list()
                                    end
                                    local mlist = available[l].moves
                                    mlist[#mlist+1] = b
                                end
                            end
                        end
                    end)
                    if not block_avail then blocks = false end
                end
            end

            local escape = kingM(pos,kingPos,oppAT)
            if #escape == 0 then
                escape = false
            else
                if not available[kingPos] then
                    available[kingPos] = get_piece_node(pos[kingPos])
                    available[kingPos].moves = get_list()
                end
                local klist = available[kingPos].moves
                for _,e in ipairs(escape) do
                    klist[#klist+1] = e
                end
            end

            if not (escape or blocks or kill) then
                return true,false
            end
        end
    end
    return check, available
end

return {
    attackgen = attackgen,
    possible = possible,
    inCheck = inCheck
}
