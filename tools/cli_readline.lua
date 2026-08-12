-- tools/cli_readline.lua
local sys = require("tools.cli_sys")
local lobby = require("tools.cli_lobby")

local Readline = {
    history = {},
    prompt_str = "weaver> ",
    cmds = {"swarm", "lab", "host", "host_headless", "client", "attach", "clean", "orphans", "exit", "quit", "status"}
}

function Readline.read()
    local buf = ""
    local cursor = 0
    local hist_idx = #Readline.history + 1
    local prompt_len = #Readline.prompt_str

    local function redraw()
        io.write("\r\27[K" .. Readline.prompt_str .. buf)
        if cursor < #buf then
            io.write("\r\27[" .. (prompt_len + cursor) .. "C")
        end
        io.flush()
    end

    io.write(Readline.prompt_str)
    io.flush()

    while true do
        local c = ""

        if sys.target == "win" then
            local code = sys.getch()
            if code == 224 or code == 0 then
                local ext = sys.getch()
                c = (ext == 72) and "UP" or (ext == 80) and "DOWN"
                 or (ext == 75) and "LEFT" or (ext == 77) and "RIGHT" or "IGNORE"
            elseif code == 27 then c = "IGNORE"
            elseif code == 13 then c = "ENTER"
            elseif code == 8 or code == 127 then c = "BACKSPACE"
            elseif code == 9 then c = "TAB"
            elseif code == 3 then c = "CTRLC"
            else c = string.char(code) end
        else
            local char = io.read(1)
            if not char then c = "EOF"
            elseif char == "\n" or char == "\r" then c = "ENTER"
            elseif char == "\127" or char == "\8" then c = "BACKSPACE"
            elseif char == "\t" then c = "TAB"
            elseif char == "\3" then c = "CTRLC"
            elseif char == "\27" then
                local b = io.read(1)
                if b == "[" then
                    local d = io.read(1)
                    c = (d == "A") and "UP" or (d == "B") and "DOWN"
                     or (d == "C") and "RIGHT" or (d == "D") and "LEFT" or "IGNORE"
                else c = "IGNORE" end
            else c = char end
        end

        if c == "EOF" or c == "CTRLC" then
            return nil
        elseif c == "ENTER" then
            io.write("\n")
            buf = buf:gsub("\r", "")
            if buf ~= "" and Readline.history[#Readline.history] ~= buf then
                table.insert(Readline.history, buf)
            end
            return buf
        elseif c == "BACKSPACE" then
            if cursor > 0 then
                buf = buf:sub(1, cursor - 1) .. buf:sub(cursor + 1)
                cursor = cursor - 1
                redraw()
            end
        elseif c == "LEFT" then
            if cursor > 0 then
                cursor = cursor - 1
                redraw()
            end
        elseif c == "RIGHT" then
            if cursor < #buf then
                cursor = cursor + 1
                redraw()
            end
        elseif c == "UP" or c == "DOWN" then
            if c == "UP" and hist_idx > 1 then hist_idx = hist_idx - 1
            elseif c == "DOWN" and hist_idx < #Readline.history then hist_idx = hist_idx + 1
            elseif c == "DOWN" and hist_idx == #Readline.history then hist_idx = #Readline.history + 1 end

            buf = Readline.history[hist_idx] or ""
            cursor = #buf
            redraw()
        elseif c == "TAB" then
            local is_second_word = buf:find(" ")

            if not is_second_word then
                local matches = {}
                for _, cmd in ipairs(Readline.cmds) do
                    if cmd:sub(1, #buf) == buf then table.insert(matches, cmd) end
                end
                if #matches == 1 then buf = matches[1] .. " " end
            else
                local cmd_str, args_str = buf:match("^(%S+)%s+(.*)$")
                local latest_id = lobby.get_latest_id()
                local partial = args_str:match("(%S*)$")

                if partial then
                    if #partial == 4 and partial:match("^[0-9a-fA-F]+$") then
                        buf = buf:sub(1, -(#partial + 1)) .. partial:upper() .. " "
                    elseif latest_id and latest_id:sub(1, #partial) == partial:upper() then
                        buf = buf:sub(1, -(#partial + 1)) .. latest_id .. " "
                    end
                end
            end
            cursor = #buf
            redraw()
        elseif c ~= "IGNORE" then
            buf = buf:sub(1, cursor) .. c .. buf:sub(cursor + 1)
            cursor = cursor + 1
            redraw()
        end
    end
end

return Readline
