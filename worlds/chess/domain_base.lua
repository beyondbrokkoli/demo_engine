-- worlds/chess/domain_base.lua
require("worlds.luachess.global")

local ChessDomain = {}

local loc_cache = {}
for y = 1, 8 do
    loc_cache[y] = {}
    for x = 1, 8 do loc_cache[y][x] = loc:new(x, y) end
end

local CHUNK_SCALE = 3

-- Export localized state so submodules can maintain exact variable names
ChessDomain._loc_cache = loc_cache
ChessDomain._CHUNK_SCALE = CHUNK_SCALE

return ChessDomain
