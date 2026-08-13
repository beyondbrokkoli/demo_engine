-- worlds/chess/domain_contract_logic.lua

local ContractBase = require("worlds.chess.domain_contract_base")

-- Only pull the requires we actually need for the worker logic
local ffi = require("ffi")
local bit = require("bit")
require("worlds.luachess.game.turn")

local Base = require("worlds.chess.domain_base")
local Terrain = require("worlds.chess.domain_terrain")
local Lifecycle = require("worlds.chess.domain_lifecycle")

-- Maintain exact variable names internally
local loc_cache = Base._loc_cache
local pop_isometric_chunk = Terrain.pop_isometric_chunk
local reset_to_standard = Lifecycle.reset_to_standard

local Logic = {}

local function ApplyContract(state, ext_state, cmd, player_id, app_ctx)
    -- 0. COMMAND UNPACKING
    -- In rollback netcode, MTU footprint is everything. The network doesn't
    -- send huge JSON strings like "e2e4". It sends a single integer (target_pos).
    -- Here we slice that integer in half using bitwise shifts to extract the
    -- 'from' index (high 8 bits) and 'to' index (low 8 bits).
    local packed = cmd.target_pos
    local from_idx = bit.rshift(packed, 8)
    local to_idx = bit.band(packed, 0xFF)

    -- If there's no command this tick, exit immediately to save CPU cycles.
    if from_idx == 0 and to_idx == 0 then return end

    -- 1. THE BLANK SLATE (Zero-Allocation Maps)
    -- We grab clean maps from your ring buffers.
    -- temp_map: Will hold the actual piece IDs (1 for Pawn, 8 for King, etc.)
    -- freshmap: Will track which pieces have NEVER moved (needed for castling)
    local temp_map = Map:new(0)
    local freshmap = Map:new(false)
    local lua_grid_index = 1

    -- The 'flags' byte is our magic metadata container.
    -- 0x80 (1000 0000 in binary) represents the Turn.
    -- If the top bit is 1, it's White's turn. If 0, Black's turn.
    local flags = state.chess.flags
    local is_white_turn = bit.band(flags, 0x80) == 0x80
    local current_turn = is_white_turn and 1 or 2

    -- 2. DECODE FFI STATE TO LUACHESS
    -- We loop through the 64-byte C struct and inflate it into your luachess Map.
    for y = 0, 7 do
        for x = 0, 7 do
            -- Fetch the cached coordinate object (prevents GC spam)
            local current_loc = loc_cache[y + 1][x + 1]
            -- Read the byte from FFI memory
            local piece = state.chess.grid[lua_grid_index - 1]
            temp_map[current_loc] = piece

            -- RECONSTRUCTING CASTLING RIGHTS (The "Freshmap" illusion)
            -- Your love2d code needs to know if pieces have moved. Since we don't
            -- save history per-piece, we deduce it dynamically:

            -- Pawns and Kings on their starting rows are assumed fresh.
            if piece == 1 and (y + 1) == 2 then freshmap[current_loc] = true end
            if piece == -1 and (y + 1) == 7 then freshmap[current_loc] = true end
            if piece == 8 and (y + 1) == 1 then freshmap[current_loc] = true end
            if piece == -8 and (y + 1) == 8 then freshmap[current_loc] = true end

            -- Rooks are trickier. They are only "fresh" if their specific
            -- castling bit is still alive in our flags byte.
            if piece == 4 and (y + 1) == 1 then
                if x == 7 and bit.band(flags, 0x08) ~= 0 then freshmap[current_loc] = true end -- White King-Side
                if x == 0 and bit.band(flags, 0x04) ~= 0 then freshmap[current_loc] = true end -- White Queen-Side
            end
            if piece == -4 and (y + 1) == 8 then
                if x == 7 and bit.band(flags, 0x02) ~= 0 then freshmap[current_loc] = true end -- Black King-Side
                if x == 0 and bit.band(flags, 0x01) ~= 0 then freshmap[current_loc] = true end -- Black Queen-Side
            end

            lua_grid_index = lua_grid_index + 1
        end
    end

    -- 3. DECODE EN PASSANT
    -- If a pawn double-jumped last turn, the FFI struct holds the index of the
    -- vulnerable square. We convert that 1D index (0-63) back into 2D (x, y)
    -- and assign it the proper target ID for your love2d logic to consume.
    local eptoken = nil
    if state.chess.en_passant ~= 255 then
        local ep_x = (state.chess.en_passant % 8) + 1
        local ep_y = math.floor(state.chess.en_passant / 8) + 1
        -- If it's White's turn, the target belongs to Black (-7), and vice versa.
        eptoken = { x = ep_x, y = ep_y, id = is_white_turn and -7 or 7 }
    end

    -- 4. THE ORACLE INVOCATION
    -- This is where your luachess codebase takes over. We spin up a Turn object
    -- strictly for this exact rollback frame, calculate all possible moves,
    -- and attempt to apply the network command.
    local T = Turn:new(temp_map, current_turn, freshmap, eptoken, false, false, state.chess.halfmove)

    -- Convert the raw command indices back to 1-8 coordinates
    local f_x, f_y = (from_idx % 8) + 1, math.floor(from_idx / 8) + 1
    local t_x, t_y = (to_idx % 8) + 1, math.floor(to_idx / 8) + 1

    local new_T = false
    -- Sanity check: Ensure coordinates are strictly on the board
    if f_x > 0 and f_x <= 8 and f_y > 0 and f_y <= 8 and t_x > 0 and t_x <= 8 and t_y > 0 and t_y <= 8 then
        -- Execute your love2d logic!
        new_T = T:make_move(loc_cache[f_y][f_x], loc_cache[t_y][t_x])
    end

    -- 5. STRICT STATE DIFFING (Reconciliation)
    -- If the move was legal, 'new_T' contains the future board state.
    -- We compare the OLD map to the NEW map square-by-square.
    if new_T then
        lua_grid_index = 1
        for y = 1, 8 do
            for x = 1, 8 do
                local loc = loc_cache[y][x]
                local old_piece = temp_map[loc] or 0
                local new_piece = new_T.pos[loc] or 0

                -- If a square changed (piece arrived, left, or died)...
                if old_piece ~= new_piece then
                    -- 1. Update the authoritative FFI struct
                    state.chess.grid[lua_grid_index - 1] = new_piece

                    -- 2. Update the visual 3D terrain grid using fixed-point math
                    if new_piece == 0 then
                        pop_isometric_chunk(ext_state, app_ctx, x, y, 0, 0)
                    else
                        pop_isometric_chunk(ext_state, app_ctx, x, y, 15, 15)
                    end
                end
                lua_grid_index = lua_grid_index + 1
            end
        end

        -- 6. ENCODE LUA STATE BACK TO FFI
        -- We must pack the metadata back down so it survives the next rollback.

        -- Start by flipping the turn bit. If it was White (0x80), make it Black (0x00).
        local out_flags = is_white_turn and 0x00 or 0x80

        -- Query the Turn's new freshmap. If a King or Rook moved this turn,
        -- their specific square will be 'false'. We only activate the castling
        -- bits if the pieces are still 'fresh'.
        if new_T.freshmap[loc_cache[1][5]] then
            if new_T.freshmap[loc_cache[1][8]] then out_flags = bit.bor(out_flags, 0x08) end
            if new_T.freshmap[loc_cache[1][1]] then out_flags = bit.bor(out_flags, 0x04) end
        end
        if new_T.freshmap[loc_cache[8][5]] then
            if new_T.freshmap[loc_cache[8][8]] then out_flags = bit.bor(out_flags, 0x02) end
            if new_T.freshmap[loc_cache[8][1]] then out_flags = bit.bor(out_flags, 0x01) end
        end
        -- Commit the packed byte to memory
        state.chess.flags = out_flags

        -- Detect if this move created an En Passant vulnerability (pawn double push).
        local next_ep = 255 -- 255 means "no en passant"
        local moved_pc = temp_map[loc_cache[f_y][f_x]]

        if math.abs(moved_pc) == 1 and math.abs(f_y - t_y) == 2 then
            -- Calculate the "skipped" square behind the pawn
            local ep_y = t_y - moved_pc
            -- Convert 2D coordinate to a 1D index (0-63)
            next_ep = (ep_y - 1) * 8 + (t_x - 1)
        end
        -- Commit the index to memory
        state.chess.en_passant = next_ep

        -- 7. TERMINAL STATE HARNESS (Draws & Mates)

        -- Commit the new halfmove clock to FFI memory FIRST
        state.chess.halfmove = new_T.drawCount

        local is_terminal = false
        local terminal_reason = ""

        if new_T.checkmate then
            is_terminal = true
            terminal_reason = "Checkmate"
        elseif new_T.stalemate then
            is_terminal = true
            terminal_reason = "Stalemate"
        elseif state.chess.halfmove >= 100 then
            -- 50 full moves = 100 half-moves without a pawn push or capture
            is_terminal = true
            terminal_reason = "50-Move Rule"
        else
            -- ROLLBACK-SAFE THREEFOLD REPETITION
            -- 1. Generate a fast 32-bit hash using FFI types (ignores Lua floating point weirdness)
            local hash_val = ffi.new("uint32_t", 5381)
            for i = 0, 63 do
                hash_val = hash_val * 33 + ffi.cast("uint8_t", state.chess.grid[i])
            end
            hash_val = hash_val * 33 + state.chess.flags
            hash_val = hash_val * 33 + state.chess.en_passant

            -- 2. Store it in our C-struct history array at the current ply
            local ply = state.chess.halfmove
            state.chess.history[ply] = hash_val

            -- 3. Scan backwards to see if this hash occurred 2 other times
            local repetitions = 0
            for i = 0, ply do
                if state.chess.history[i] == hash_val then
                    repetitions = repetitions + 1
                end
            end

            if repetitions >= 3 then
                is_terminal = true
                terminal_reason = "Threefold Repetition"
            end
        end

        -- THE TRIGGER
        if is_terminal then
            print(string.format("[CHESS MATCH END] Trigger: %s. Resetting board...", terminal_reason))
            reset_to_standard(state, ext_state, app_ctx)
        end
    end
end

Logic.ApplyContract = ApplyContract

return Logic
