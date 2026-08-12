-- runtime/boot/path_weaver.lua
-- Only allow fully qualified paths from the project root!
package.path = "./?.lua;" .. package.path
