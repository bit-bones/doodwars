local path = (...):gsub("[^%.]*$", "")
local M = require(path .. 'main')
local Class, CyclicList, Set, Vec2
do
  local _obj_0 = M.steelpan
  Class, CyclicList, Set, Vec2 = _obj_0.Class, _obj_0.CyclicList, _obj_0.Set, _obj_0.Vec2
end
local SymmetricMatrix
SymmetricMatrix = M.steelpan.matrices.SymmetricMatrix
local bounding_box, centroid, closest_edge_point, is_point_in_triangle
do
  local _obj_0 = M.steelpan.geometry
  bounding_box, centroid, closest_edge_point, is_point_in_triangle = _obj_0.bounding_box, _obj_0.centroid, _obj_0.closest_edge_point, _obj_0.is_point_in_triangle
end
local round, clamp, sgn
do
  local _obj_0 = M.steelpan.utils.math
  round, clamp, sgn = _obj_0.round, _obj_0.clamp, _obj_0.sgn
end
local dot, wedge
dot, wedge = Vec2.dot, Vec2.wedge
local huge
huge = math.huge
local unpack = unpack or table.unpack
local ConvexPolygon, Navigation, string_pull, orientation
ConvexPolygon = Class({
  __init = function(self, vertices, name, hidden)
    self.name, self.hidden = name, hidden
    assert(#vertices > 2, "A polygon must have a least 3 points.")
    self.vertices = CyclicList(vertices)
    self.n = #vertices
    self.min, self.max = bounding_box(vertices)
    self.centroid = centroid(vertices)
    self.connections = { }
  end,
  ipairs = function(self)
    return ipairs(self.vertices.items)
  end,
  __index = function(self, key)
    return type(key) == "number" and self.vertices[key] or nil
  end,
  get_edge = function(self, i)
    return self.vertices[i], self.vertices[i + 1]
  end,
  get_connection = function(self, i)
    do
      local c = self.connections[i]
      if c then
        for _index_0 = 1, #c do
          local t = c[_index_0]
          if not t.polygon.hidden then
            return t
          end
        end
      end
    end
  end,
  is_point_inside = function(self, P)
    if not (P.x < self.min.x or P.y < self.min.y or P.x > self.max.x or P.y > self.max.y) then
      for i = 2, self.n - 1 do
        if is_point_in_triangle(P, self.vertices[1], self.vertices[i], self.vertices[i + 1]) then
          return true
        end
      end
    end
    return false
  end,
  is_point_inside_connected = function(self, P, visited)
    if visited == nil then
      visited = { }
    end
    visited[self] = true
    if self:is_point_inside(P) then
      return self
    end
    for i = 1, self.n do
      do
        local c = self:get_connection(i)
        if c then
          local p = c.polygon
          if not visited[p] then
            do
              local poly = p:is_point_inside_connected(P, visited)
              if poly then
                return poly
              end
            end
          end
        end
      end
    end
  end,
  closest_edge_point = function(self, P, edge_idx)
    local A, B = self:get_edge(edge_idx)
    return closest_edge_point(P, A, B)
  end,
  closest_boundary_point_connected = function(self, P, visited)
    if visited == nil then
      visited = { }
    end
    visited[self] = true
    local C, poly
    local d = huge
    for i = 1, self.n do
      local tmp_C, tmp_poly
      local tmp_d = huge
      do
        local neighbour = self:get_connection(i)
        if neighbour then
          neighbour = neighbour.polygon
          if not visited[neighbour] then
            tmp_C, tmp_poly, tmp_d = neighbour:closest_boundary_point_connected(P, visited)
          end
        else
          tmp_poly = self
          tmp_C = self:closest_edge_point(P, i)
          tmp_d = (P - tmp_C):lenS()
        end
      end
      if tmp_d < d then
        C, poly, d = tmp_C, tmp_poly, tmp_d
      end
    end
    return C, poly, d
  end
})
Navigation = Class({
  __init = function(self, pmaps)
    if pmaps == nil then
      pmaps = { }
    end
    local vertices, vertex_idxs, polygons, name_groups = { }, {
      n = 0
    }, { }, { }
    for _index_0 = 1, #pmaps do
      local pmap = pmaps[_index_0]
      local name_group = pmap.name and { }
      if pmap.name then
        name_groups[pmap.name] = name_group
      end
      for _index_1 = 1, #pmap do
        local poly = pmap[_index_1]
        local tmp = { }
        for _index_2 = 1, #poly do
          local v = poly[_index_2]
          local x, y = unpack(v)
          local label = tostring(x) .. ';' .. tostring(y)
          if not vertices[label] then
            v = Vec2(x, y)
            vertices[label] = v
            vertex_idxs.n = vertex_idxs.n + 1
            vertex_idxs[v] = vertex_idxs.n
          end
          tmp[#tmp + 1] = vertices[label]
        end
        local cp = ConvexPolygon(tmp, pmap.name, pmap.hidden)
        polygons[#polygons + 1] = cp
        if name_group then
          name_group[#name_group + 1] = cp
        end
      end
    end
    self.polygons = polygons
    self.vertex_idxs = vertex_idxs
    self.name_groups = name_groups
  end,
  set_visibility = function(self, name, bool)
    do
      local t = self.name_groups[name]
      if t then
        for _index_0 = 1, #t do
          local p = t[_index_0]
          p.hidden = not bool
        end
      end
    end
  end,
  toggle_visibility = function(self, name)
    do
      local t = self.name_groups[name]
      if t then
        for _index_0 = 1, #t do
          local p = t[_index_0]
          p.hidden = not p.hidden
        end
      end
    end
  end,
  initialize = function(self)
    self.initialized = true
    local edges_matrix = SymmetricMatrix(self.vertex_idxs.n)
    local _list_0 = self.polygons
    for _index_0 = 1, #_list_0 do
      local p = _list_0[_index_0]
      for i = 1, p.n do
        local A, B = p:get_edge(i)
        local A_idx, B_idx = self.vertex_idxs[A], self.vertex_idxs[B]
        local t = edges_matrix:get(A_idx, B_idx)
        if not t then
          t = { }
          edges_matrix:set(A_idx, B_idx, t)
        end
        t[#t + 1] = {
          edge = i,
          polygon = p
        }
      end
    end
    for i = 1, self.vertex_idxs.n do
      for j = i + 1, self.vertex_idxs.n do
        do
          local t = edges_matrix:get(i, j)
          if t then
            if #t > 1 then
              for k, c in ipairs(t) do
                do
                  local _accum_0 = { }
                  local _len_0 = 1
                  for x = 1, #t do
                    if x ~= k then
                      _accum_0[_len_0] = t[x]
                      _len_0 = _len_0 + 1
                    end
                  end
                  c.polygon.connections[c.edge] = _accum_0
                end
              end
            end
          end
        end
      end
    end
  end,
  _is_point_inside = function(self, P)
    if not self.initialized then
      self:initialize()
    end
    local _list_0 = self.polygons
    for _index_0 = 1, #_list_0 do
      local poly = _list_0[_index_0]
      if not poly.hidden and poly:is_point_inside(P) then
        return poly
      end
    end
  end,
  _closest_boundary_point = function(self, P)
    if not self.initialized then
      self:initialize()
    end
    local d = huge
    local C, poly
    local _list_0 = self.polygons
    for _index_0 = 1, #_list_0 do
      local p = _list_0[_index_0]
      if not (p.hidden) then
        for i = 1, p.n do
          if not p:get_connection(i) then
            local tmp_C = p:closest_edge_point(P, i)
            local tmp_d = (P - tmp_C):lenS()
            if tmp_d < d then
              d, C, poly = tmp_d, tmp_C, p
            end
          end
        end
      end
    end
    return C, poly
  end,
  _shortest_path = function(self, A, B)
    if not self.initialized then
      self:initialize()
    end
    if self.n == 0 then
      return { }
    end
    A, B = round(A), round(B)
    local node_A, node_B
    node_A = self:_is_point_inside(A)
    if not node_A then
      A, node_A = self:_closest_boundary_point(A)
      A = round(A)
    end
    node_B = node_A:is_point_inside_connected(B)
    if not node_B then
      B, node_B = node_A:closest_boundary_point_connected(B)
      B = round(B)
    end
    if A == B then
      return {
        A
      }
    elseif node_A == node_B then
      return {
        A,
        B
      }
    end
    local found_path = false
    local _list_0 = self.polygons
    for _index_0 = 1, #_list_0 do
      local p = _list_0[_index_0]
      p.prev_edge = nil
    end
    local polylist = Set()
    node_B.entry = B
    node_B.distance = 0
    polylist:add(node_B)
    while not found_path do
      if polylist:size() == 0 then
        break
      end
      local least_cost_poly
      local least_cost = huge
      for p in polylist:iterator() do
        local cost = p ~= node_B and p.distance + (p.centroid - A):len() or 0
        if cost < least_cost then
          least_cost_poly = p
          least_cost = cost
        end
      end
      local p = least_cost_poly
      for i = 1, p.n do
        do
          local t = p:get_connection(i)
          if t then
            local q, c_edge = t.polygon, t.edge
            local entry = p:closest_edge_point(p.entry, i)
            local distance = p.distance + (p.entry - entry):len()
            if q.prev_edge then
              if q.distance > distance then
                q.prev_edge = c_edge
                q.distance = distance
                q.entry = entry
              end
            else
              q.prev_edge = c_edge
              q.distance = distance
              q.entry = entry
              polylist:add(q)
              if q == node_A then
                local found = true
                break
              end
            end
          end
        end
      end
      if found_path then
        break
      end
      polylist:remove(p)
    end
    local portals = {
      {
        A,
        A
      }
    }
    local p = node_A
    while p ~= node_B and p.prev_edge do
      local C, D = p:get_edge(p.prev_edge)
      local L, R = unpack(portals[#portals])
      local sign = orientation(C, L, D)
      sign = sign == 0 and orientation(C, R, D) or sign
      portals[#portals + 1] = sign > 0 and {
        C,
        D
      } or {
        D,
        C
      }
      do
        local c = p:get_connection(p.prev_edge)
        if c then
          p = c.polygon
        end
      end
    end
    portals[#portals + 1] = {
      B,
      B
    }
    return string_pull(portals)
  end,
  is_point_inside = function(self, x, y)
    return not not self:_is_point_inside(Vec2(x, y))
  end,
  closest_boundary_point = function(self, x, y)
    local P = self:_closest_boundary_point(Vec2(x, y))
    return P.x, P.y
  end,
  shortest_path = function(self, x1, y1, x2, y2)
    path = self:_shortest_path(Vec2(x1, y1), Vec2(x2, y2))
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #path do
        local v = path[_index_0]
        _accum_0[_len_0] = {
          v.x,
          v.y
        }
        _len_0 = _len_0 + 1
      end
      path = _accum_0
    end
    return path
  end
})
M.Navigation = Navigation
string_pull = function(portals)
  local portal_left, portal_right = unpack(portals[1])
  local l_idx, r_idx = 1, 1
  local apex = portal_left
  path = {
    apex
  }
  local i = 1
  while i < #portals do
    i = i + 1
    local left, right = unpack(portals[i])
    local skip = false
    if orientation(portal_right, apex, right) <= 0 then
      if apex == portal_right or orientation(portal_left, apex, right) > 0 then
        portal_right = right
        r_idx = i
      else
        if path[#path] ~= portal_left then
          path[#path + 1] = portal_left
        end
        apex = portal_left
        portal_right = apex
        r_idx = l_idx
        i = l_idx
        skip = true
      end
    end
    if not skip and orientation(portal_left, apex, left) >= 0 then
      if apex == portal_left or orientation(portal_right, apex, left) < 0 then
        portal_left = left
        l_idx = i
      else
        if path[#path] ~= portal_right then
          path[#path + 1] = portal_right
        end
        apex = portal_right
        portal_left = apex
        l_idx = r_idx
        i = r_idx
      end
    end
  end
  local A = portals[#portals][1]
  if path[#path] ~= A or #path == 1 then
    path[#path + 1] = A
  end
  return path
end
orientation = function(L, P, R)
  return wedge(R - P, L - P)
end
