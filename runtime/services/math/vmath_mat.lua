-- runtime/services/math/vmath_mat.lua
local vmath_mat = {}

function vmath_mat.multiply_mat4(a, b, out)
    local am, bm, o = a.m, b.m, out.m
    local a00, a10, a20, a30 = am[0], am[4], am[8], am[12]
    local a01, a11, a21, a31 = am[1], am[5], am[9], am[13]
    local a02, a12, a22, a32 = am[2], am[6], am[10], am[14]
    local a03, a13, a23, a33 = am[3], am[7], am[11], am[15]

    local b00, b10, b20, b30 = bm[0], bm[4], bm[8], bm[12]
    local b01, b11, b21, b31 = bm[1], bm[5], bm[9], bm[13]
    local b02, b12, b22, b32 = bm[2], bm[6], bm[10], bm[14]
    local b03, b13, b23, b33 = bm[3], bm[7], bm[11], bm[15]

    o[0], o[1], o[2], o[3] = a00*b00+a10*b01+a20*b02+a30*b03, a01*b00+a11*b01+a21*b02+a31*b03, a02*b00+a12*b01+a22*b02+a32*b03, a03*b00+a13*b01+a23*b02+a33*b03
    o[4], o[5], o[6], o[7] = a00*b10+a10*b11+a20*b12+a30*b13, a01*b10+a11*b11+a21*b12+a31*b13, a02*b10+a12*b11+a22*b12+a32*b13, a03*b10+a13*b11+a23*b12+a33*b13
    o[8], o[9], o[10], o[11] = a00*b20+a10*b21+a20*b22+a30*b23, a01*b20+a11*b21+a21*b22+a31*b23, a02*b20+a12*b21+a22*b22+a32*b23, a03*b20+a13*b21+a23*b22+a33*b23
    o[12], o[13], o[14], o[15] = a00*b30+a10*b31+a20*b32+a30*b33, a01*b30+a11*b31+a21*b32+a31*b33, a02*b30+a12*b31+a22*b32+a32*b33, a03*b30+a13*b31+a23*b32+a33*b33
end

function vmath_mat.multiply_mat4_vec4(m, x, y, z, w, out)
    local mm = m.m
    out.x, out.y = mm[0]*x + mm[4]*y + mm[8]*z + mm[12]*w, mm[1]*x + mm[5]*y + mm[9]*z + mm[13]*w
    out.z, out.w = mm[2]*x + mm[6]*y + mm[10]*z + mm[14]*w, mm[3]*x + mm[7]*y + mm[11]*z + mm[15]*w
end

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
