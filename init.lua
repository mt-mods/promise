local MP = minetest.get_modpath("promise")

dofile(MP.."/promise.lua")
dofile(MP.."/util.lua")
dofile(MP.."/formspec.lua")

if minetest.get_modpath("mtt") and mtt.enabled then
	dofile(MP .. "/promise.spec.lua")
	dofile(MP .. "/util.spec.lua")
end