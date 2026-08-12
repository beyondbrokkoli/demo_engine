-- runtime/services/math/vmath_cam.lua
local math = require("math")
local vmath_cam = {}

function vmath_cam.lookAt(ex, ey, ez, cx, cy, cz, out)
    local fx, fy, fz = cx - ex, cy - ey, cz - ez
    local fi = 1.0 / math.sqrt(fx^2 + fy^2 + fz^2)
    fx, fy, fz = fx * fi, fy * fi, fz * fi

    local ux, uy, uz = 0.0, 1.0, 0.0
    if math.abs(fx) < 0.001 and math.abs(fz) < 0.001 then
        uz, uy = (fy > 0 and -1.0 or 1.0), 0.0
    end

    local rx, ry, rz = uy * fz - uz * fy, uz * fx - ux * fz, ux * fy - uy * fx
    local ri = 1.0 / math.sqrt(rx^2 + ry^2 + rz^2)
    rx, ry, rz = rx * ri, ry * ri, rz * ri
    ux, uy, uz = fy * rz - fz * ry, fz * rx - fx * rz, fx * ry - fy * rx

    local o = out.m
    o[0], o[1], o[2], o[3] = rx, ux, -fx, 0.0
    o[4], o[5], o[6], o[7] = ry, uy, -fy, 0.0
    o[8], o[9], o[10], o[11] = rz, uz, -fz, 0.0
    o[12], o[13], o[14], o[15] = -(rx*ex + ry*ey + rz*ez), -(ux*ex + uy*ey + uz*ez), (fx*ex + fy*ey + fz*ez), 1.0
end

function vmath_cam.ortho_vk(l, r, b, t, n, f, out)
    local o = out.m
    o[0], o[4], o[8], o[12] = 2.0/(r-l), 0.0, 0.0, -(r+l)/(r-l)
    o[1], o[5], o[9], o[13] = 0.0, 2.0/(b-t), 0.0, -(b+t)/(b-t)
    o[2], o[6], o[10], o[14] = 0.0, 0.0, -1.0/(f-n), -n/(f-n)
    o[3], o[7], o[11], o[15] = 0.0, 0.0, 0.0, 1.0
end

return vmath_cam
