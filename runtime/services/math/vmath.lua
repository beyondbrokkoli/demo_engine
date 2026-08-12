-- runtime/services/math/vmath.lua
-- Wrapper module to expose the split math library as a single API.

local vmath = {}

-- Update these require paths if your engine's package.path resolves them differently
local mat = require("runtime.services.math.vmath_mat")
local cam = require("runtime.services.math.vmath_cam")

-- Map Mat math
vmath.multiply_mat4 = mat.multiply_mat4
vmath.multiply_mat4_vec4 = mat.multiply_mat4_vec4
vmath.inverse_mat4 = mat.inverse_mat4

-- Map Camera math
vmath.lookAt = cam.lookAt
vmath.ortho_vk = cam.ortho_vk

return vmath
