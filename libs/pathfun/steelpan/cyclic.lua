local path = (...):gsub("[^%.]*$", "")
local Class = require(path .. 'class')
local CyclicList = Class({
  __init = function(self, t)
    self.n = #t
    self.items = t
  end,
  __index = function(self, key)
    return self.items[((key - 1) % self.n) + 1]
  end,
  insert = function(self, i, x)
    self.n = self.n + 1
    if x == nil then
      x = i
      i = self.n
    else
      i = ((i - 1) % self.n) + 1
    end
    return table.insert(self.items, i, x)
  end,
  remove = function(self, i)
    if self.n == 0 then
      return 
    end
    i = i and ((i - 1) % self.n) + 1 or self.n
    self.n = self.n - 1
    return table.remove(self.items, i)
  end,
  len = function(self)
    return self.n
  end,
  ipairs = function(self)
    return ipairs(self.items)
  end,
  totable = function(self)
    return self.items
  end
})
return CyclicList
