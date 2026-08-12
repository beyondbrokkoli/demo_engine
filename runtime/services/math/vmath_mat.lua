-- runtime/services/math/vmath_mat.lua
local vmath_mat = {}

local mult = require("runtime.services.math.vmath_mat_mult")
local inv = require("runtime.services.math.vmath_mat_inv")

vmath_mat.multiply_mat4 = mult.multiply_mat4
vmath_mat.multiply_mat4_vec4 = mult.multiply_mat4_vec4
vmath_mat.inverse_mat4 = inv.inverse_mat4

return vmath_mat
