-- worlds/luachess/game/logic_base.lua
require("worlds.luachess.global")
require("worlds.luachess.game.move")
require("worlds.luachess.game.attack")

local LogicBase = {}

local directions = {}
directions[3] = {2,4,6,8}
directions[4] = {1,3,5,7}
directions[5] = {1,2,3,4,5,6,7,8}

-- Export localized state so submodules can maintain exact variable names
LogicBase._directions = directions

return LogicBase
