-- runtime/services/math/vmath_mat_inv.lua
local vmath_mat = {}

function vmath_mat.inverse_mat4(m, invOut)
    local inv, am = invOut.m, m.m
    local m00, m01, m02, m03 = am[0], am[1], am[2], am[3]
    local m10, m11, m12, m13 = am[4], am[5], am[6], am[7]
    local m20, m21, m22, m23 = am[8], am[9], am[10], am[11]
    local m30, m31, m32, m33 = am[12], am[13], am[14], am[15]

    inv[0] = m11*(m22*m33-m23*m32) - m12*(m21*m33-m23*m31) + m13*(m21*m32-m22*m31)
    inv[4] = -m10*(m22*m33-m23*m32) + m12*(m20*m33-m23*m30) - m13*(m20*m32-m22*m30)
    inv[8] = m10*(m21*m33-m23*m31) - m11*(m20*m33-m23*m30) + m13*(m20*m31-m21*m30)
    inv[12] = -m10*(m21*m32-m22*m31) + m11*(m20*m32-m22*m30) - m12*(m20*m31-m21*m30)

    inv[1] = -m01*(m22*m33-m23*m32) + m02*(m21*m33-m23*m31) - m03*(m21*m32-m22*m31)
    inv[5] = m00*(m22*m33-m23*m32) - m02*(m20*m33-m23*m30) + m03*(m20*m32-m22*m30)
    inv[9] = -m00*(m21*m33-m23*m31) + m01*(m20*m33-m23*m30) - m03*(m20*m31-m21*m30)
    inv[13] = m00*(m21*m32-m22*m31) - m01*(m20*m32-m22*m30) + m02*(m20*m31-m21*m30)

    inv[2] = m01*(m12*m33-m13*m32) - m02*(m11*m33-m13*m31) + m03*(m11*m32-m12*m31)
    inv[6] = -m00*(m12*m33-m13*m32) + m02*(m10*m33-m13*m30) - m03*(m10*m32-m12*m30)
    inv[10] = m00*(m11*m33-m13*m31) - m01*(m10*m33-m13*m30) + m03*(m10*m31-m11*m30)
    inv[14] = -m00*(m11*m32-m12*m31) + m01*(m10*m32-m12*m30) - m02*(m10*m31-m11*m30)

    inv[3] = -m01*(m12*m23-m13*m22) + m02*(m11*m23-m13*m21) - m03*(m11*m22-m12*m21)
    inv[7] = m00*(m12*m23-m13*m22) - m02*(m10*m23-m13*m20) + m03*(m10*m22-m12*m20)
    inv[11] = -m00*(m11*m23-m13*m21) + m01*(m10*m23-m13*m20) - m03*(m10*m21-m11*m20)
    inv[15] = m00*(m11*m22-m12*m21) - m01*(m10*m22-m12*m20) + m02*(m10*m21-m11*m20)

    local det = m00*inv[0] + m01*inv[4] + m02*inv[8] + m03*inv[12]
    if det == 0 then return false end

    det = 1.0 / det
    for i = 0, 15 do inv[i] = inv[i] * det end
    return true
end

return vmath_mat
