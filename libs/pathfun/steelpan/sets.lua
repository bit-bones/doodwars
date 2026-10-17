local path = (...):gsub("[^%.]*$", "")
local Class = require(path .. 'class')
local __next
__next = function(t, key)
  local k = next(t, key)
  return k
end
local Set
Set = Class({
  __init = function(self, t)
    local n, items = 0, { }
    if type(t) == "table" then
      for _index_0 = 1, #t do
        local value = t[_index_0]
        n = n + 1
        items[value] = true
      end
    end
    self.n = n
    self.items = items
  end,
  add = function(self, value)
    if not (self.items[value]) then
      self.n = self.n + 1
      self.items[value] = true
    end
  end,
  remove = function(self, value)
    if self.items[value] then
      self.n = self.n - 1
      self.items[value] = nil
    end
  end,
  size = function(self)
    return self.n
  end,
  iterator = function(self)
    return __next, self.items, nil
  end,
  contains = function(self, value)
    return self.items[value] or false
  end,
  union = function(s1, s2)
    local union = Set()
    for v in pairs(s1) do
      union:add(v)
    end
    for v in pairs(s2) do
      union:add(v)
    end
    return union
  end,
  intersection = function(s1, s2)
    local intersection = Set()
    for v in pairs(s1) do
      if s2.items[v] then
        intersection:add(v)
      end
    end
  end,
  totable = function(self)
    local _accum_0 = { }
    local _len_0 = 1
    for k in pairs(self.items) do
      _accum_0[_len_0] = k
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end
})
Set.range = function(n)
  local t
  do
    local _accum_0 = { }
    local _len_0 = 1
    for i = 1, n do
      _accum_0[_len_0] = i
      _len_0 = _len_0 + 1
    end
    t = _accum_0
  end
  return Set(t)
end
return Set
