local path = (...):gsub("[^%.]*$", "")
local Vec2 = require(path .. 'vectors')
local status, mod = pcall(require, "love")
local love = status and mod or nil
local min, max, floor, ceil, huge, abs
do
  local _obj_0 = math
  min, max, floor, ceil, huge, abs = _obj_0.min, _obj_0.max, _obj_0.floor, _obj_0.ceil, _obj_0.huge, _obj_0.abs
end
local xtype, xmath, round, clamp, simplify_path, random_choice
xtype = function(x)
  local t = type(x)
  if t == "table" then
    do
      local cls = x.__class
      if cls then
        return cls
      end
    end
  end
  return t
end
xmath = { }
xmath.sgn = function(x)
  return x > 0 and 1 or x < 0 and -1 or 0
end
xmath.floor = function(a)
  if xtype(a) == Vec2 then
    return Vec2(floor(a.x), floor(a.y))
  else
    return floor(a)
  end
end
xmath.ceil = function(a)
  if xtype(a) == Vec2 then
    return Vec2(ceil(a.x), ceil(a.y))
  else
    return ceil(a)
  end
end
round = function(a)
  if xtype(a) == Vec2 then
    return Vec2(round(a.x), round(a.y))
  else
    return floor(a + 0.5)
  end
end
xmath.round = round
clamp = function(a, min, max)
  if xtype(a) == Vec2 then
    return Vec2(clamp(a.x, min, max), clamp(a.y, min, max))
  else
    return (a < min and min) or (a > max and max) or a
  end
end
xmath.clamp = clamp
xmath.max = function(a, ...)
  local M, idx = -huge, nil
  if type(a) == 'table' then
    for i, v in pairs(a) do
      if v > M then
        M = v
        idx = i
      end
    end
    if M > -huge then
      return M, idx
    end
  else
    return max(a, ...)
  end
end
xmath.min = function(a, ...)
  local m, idx = huge, nil
  if type(a) == 'table' then
    for i, v in pairs(a) do
      if v < m then
        m = v
        idx = i
      end
    end
    if m < huge then
      return m, idx
    end
  else
    return min(a, ...)
  end
end
simplify_path = function(path)
  local t = {
    path:sub(1, 1) == "/" and "/" or nil
  }
  for x in path:gmatch("([^/]+)") do
    if x ~= ".." then
      t[#t + 1] = x
    else
      t[#t] = nil
    end
  end
  return table.concat(t, "/")
end
random_choice = function(t)
  local i = love.math.random(#t)
  return t[i]
end
return {
  math = xmath,
  type = xtype,
  simplify_path = simplify_path,
  random_choice = random_choice
}
