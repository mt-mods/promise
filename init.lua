local MP = minetest.get_modpath("promise")

dofile(MP.."/promise.lua")

if minetest.get_modpath("mtt") and mtt.enabled then
	dofile(MP .. "/promise.spec.lua")
end