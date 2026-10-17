local path = (...):gsub("[^%.]*$", "")
local Class = require(path .. 'class')
local Matrix = Class({
  __init = function(self, num_rows, num_cols, default_value)
    self.num_rows, self.num_cols, self.default_value = num_rows, num_cols, default_value
    self.matrix = { }
  end,
  get = function(self, i, j)
    assert(i >= 1 and i <= self.num_rows and j >= 1 and j <= self.num_cols, "indices out of range")
    local idx = i * self.num_cols + j
    return self.matrix[idx] or self.default_value
  end,
  set = function(self, i, j, value)
    assert(i >= 1 and i <= self.num_rows and j >= 1 and j <= self.num_cols, "indices out of range")
    local idx = i * self.num_cols + j
    self.matrix[idx] = value
  end
})
local SymmetricMatrix = Class({
  __init = function(self, num_rows, default_value)
    return Matrix.__init(self, num_rows, num_rows, default_value)
  end,
  get = function(self, i, j)
    if j < i then
      j, i = i, j
    end
    return Matrix.get(self, i, j)
  end,
  set = function(self, i, j, value)
    if j < i then
      j, i = i, j
    end
    return Matrix.set(self, i, j, value)
  end
})
return {
  Matrix = Matrix,
  SymmetricMatrix = SymmetricMatrix
}
