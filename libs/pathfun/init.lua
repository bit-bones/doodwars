local path = (...):gsub(".init$", "") .. '.'
local M = require(path .. 'main')
local steelpan = {
  ["class"] = "Class",
  ["vectors"] = "Vec2",
  ["geometry"] = "geometry",
  ["cyclic"] = "CyclicList",
  ["sets"] = "Set",
  ["matrices"] = "matrices",
  ["utils"] = "utils"
}
do
  local _tbl_0 = { }
  for m, k in pairs(steelpan) do
    _tbl_0[k] = require(path .. "steelpan." .. m)
  end
  M.steelpan = _tbl_0
end
require(path .. "navigation")
return {
  Navigation = M.Navigation
}
