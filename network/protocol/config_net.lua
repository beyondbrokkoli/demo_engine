-- network/config_net.lua
local ffi = require("ffi")
require("network.protocol.structs")

local ConfigNet = {}

ConfigNet.MAX_PLAYERS = ffi.C.CFG_MAX_PLAYERS
ConfigNet.RING_SIZE   = ffi.C.CFG_RING_SIZE
ConfigNet.RING_MASK   = ConfigNet.RING_SIZE - 1
ConfigNet.HISTORY_LEN = ffi.C.CFG_HISTORY_LEN

-- Temporal Logic & Rollback
ConfigNet.TICK_RATE = 60
ConfigNet.LOOKAHEAD_CAP = 60
ConfigNet.HISTORY_HORIZON = ConfigNet.HISTORY_LEN - 1     -- Wire limit (59)
ConfigNet.LOCAL_HORIZON   = ConfigNet.RING_SIZE - 2       -- [NEW] Memory limit (510)
ConfigNet.DESYNC_SWEEP    = ConfigNet.LOCAL_HORIZON       -- [CHANGED] Audit the entire time machine

ConfigNet.MAX_BURST_PACKETS = 256

-- Infrastructure Routing
ConfigNet.MATCHMAKER_URL = "https://api.beyondbrokkoli.com"
ConfigNet.STUN_SERVER = "138.199.152.240"
ConfigNet.STUN_PORT = 3478
ConfigNet.RELAY_IP = "138.199.152.240"
ConfigNet.RELAY_PORT = 49152

return ConfigNet
