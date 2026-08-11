-- network/session/http_client.lua
local M = {}

function M.post(url, json_payload, local_port)
    local tmp_dir = (jit.os == "Windows") and (os.getenv("TEMP") or ".") or "/tmp"
    local tmp_file = string.format("%s/mm_payload_%d.json", tmp_dir, local_port)

    local f = assert(io.open(tmp_file, "w"), string.format("Failed to open temp file at: %s", tmp_file))
    f:write(json_payload)
    f:close()

    local cmd = string.format('curl -s -X POST -H "Content-Type: application/json" -d "@%s" %s', tmp_file, url)
    local handle = io.popen(cmd)
    local response = handle:read("*a")
    handle:close()

    os.remove(tmp_file)
    return response
end

function M.get(url)
    local cmd = string.format('curl -s "%s"', url)
    local f = io.popen(cmd)
    if not f then return "" end
    local res = f:read("*a")
    f:close()
    return res
end

function M.get_local_ip()
    local cmd = ""
    if jit.os == "Windows" then
        cmd = 'powershell -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike \'127.*\' -and $_.IPAddress -notlike \'169.254.*\' } | Select-Object -First 1).IPAddress"'
    else
        cmd = "ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i==\"src\") print $(i+1)}'"
    end
    local f = io.popen(cmd)
    if not f then return "127.0.0.1" end
    local res = f:read("*a")
    f:close()
    res = res:gsub("%s+", "")
    if not res:match("^%d+%.%d+%.%d+%.%d+$") then return "127.0.0.1" end
    return res
end

return M
