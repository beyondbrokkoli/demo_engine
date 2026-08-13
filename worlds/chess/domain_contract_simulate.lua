-- worlds/chess/domain_contract_simulate.lua
require("worlds.luachess.game.turn")
local Base = require("worlds.chess.domain_base")

local loc_cache = Base._loc_cache

local function SimulatePhase(from_idx, to_idx, temp_map, freshmap, current_turn, eptoken, halfmove)
    -- 4. THE ORACLE INVOCATION
    local T = Turn:new(temp_map, current_turn, freshmap, eptoken, false, false, halfmove)

    local f_x, f_y = (from_idx % 8) + 1, math.floor(from_idx / 8) + 1
    local t_x, t_y = (to_idx % 8) + 1, math.floor(to_idx / 8) + 1

    local new_T = false
    if f_x > 0 and f_x <= 8 and f_y > 0 and f_y <= 8 and t_x > 0 and t_x <= 8 and t_y > 0 and t_y <= 8 then
        new_T = T:make_move(loc_cache[f_y][f_x], loc_cache[t_y][t_x])
    end

    return new_T
end

return SimulatePhase
