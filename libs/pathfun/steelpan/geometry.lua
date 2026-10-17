local path = (...):gsub("[^%.]*$", "")
local CyclicList = require(path .. 'cyclic')
local Vec2 = require(path .. 'vectors')
local utils = require(path .. 'utils')
local dot, wedge
dot, wedge = Vec2.dot, Vec2.wedge
local clamp, sgn
do
  local _obj_0 = utils.math
  clamp, sgn = _obj_0.clamp, _obj_0.sgn
end
local min, max, abs, huge
do
  local _obj_0 = math
  min, max, abs, huge = _obj_0.min, _obj_0.max, _obj_0.abs, _obj_0.huge
end
local geometry = { }
geometry.closest_edge_point = function(P, A, B)
  local u = B - A
  local t = clamp(dot(P - A, u) / u:lenS(), 0, 1)
  return A + t * u
end
geometry.bounding_box = function(points)
  local minx, miny, maxx, maxy = huge, huge, -huge, -huge
  for _index_0 = 1, #points do
    local v = points[_index_0]
    minx = min(minx, v.x)
    miny = min(miny, v.y)
    maxx = max(maxx, v.x)
    maxy = max(maxy, v.y)
  end
  return {
    x = minx,
    y = miny
  }, {
    x = maxx,
    y = maxy
  }
end
geometry.is_point_in_triangle = function(P, A, B, C)
  local sda = wedge(A - C, B - C)
  local s = sgn(sda)
  local a = wedge(P - C, B - C)
  local b = wedge(P - C, C - A)
  return s * a >= 0 and s * b >= 0 and s * (a + b) <= abs(sda)
end
geometry.centroid = function(points)
  local P = CyclicList(points)
  local W = 0
  local C = Vec2()
  for i = 1, #points do
    local tmp = wedge(P[i], P[i + 1])
    W = W + tmp
    C = C + ((P[i] + P[i + 1]) * tmp)
  end
  return C / (3 * W)
end
return geometry
