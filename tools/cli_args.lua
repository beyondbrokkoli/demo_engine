local cli_args = {}

function cli_args.parse(args)
    -- 1. RELAXED FLOODGATE (1 or 2 arguments allowed)
    if not args[1] or args[3] then
        print("[FATAL] Invalid argument count. Usage: <exe> <lobby_id_or_'host'> [target_size]")
        os.exit(1)
    end

    local raw_lobby = args[1]
    local raw_size = args[2]
    local is_host = (raw_lobby:lower() == "host")

    -- 2. VALIDATE LOBBY ID (Exactly 4 uppercase hex chars, unless 'host')
    if not is_host then
        if #raw_lobby ~= 4 or not raw_lobby:match("^[0-9A-F]+$") then
            print(string.format("[FATAL] Invalid Lobby ID '%s'. Must be exactly 4 uppercase hex characters (e.g., B31F) or 'host'.", raw_lobby))
            os.exit(1)
        end
    end

    -- 3. VALIDATE TARGET SIZE
    local target_lobby_size = nil
    if raw_size then
        target_lobby_size = tonumber(raw_size)
        if not target_lobby_size then
            print(string.format("[FATAL] Invalid target size '%s'. Must be a numeric value.", raw_size))
            os.exit(1)
        end
    elseif is_host then
        -- Host must dictate the lobby size; clients get it from the matchmaker.
        print("[FATAL] Host must specify target size. Usage: <exe> host <size>")
        os.exit(1)
    end

    local target_lobby_id = is_host and nil or raw_lobby

    -- Return a clean, structured table
    return {
        is_host = is_host,
        lobby_id = target_lobby_id,
        size = target_lobby_size
    }
end

return cli_args
