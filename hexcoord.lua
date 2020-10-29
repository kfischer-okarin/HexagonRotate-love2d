local HexCoord = {}

HexCoord.__eq = function(a, b)
  return a.x == b.x and a.y == b.y and a.z == b.z
end

HexCoord.__sub = function(a, b)
  return HexCoord:new(a.x - b.x, a.y - b.y, a.z - b.z)
end

HexCoord.__tostring = function(self)
  return "HexCoord(" .. self.x .. ", " .. self.y .. ", " .. self.z .. ")"
end

local SQRT_3 = math.sqrt(3)

function HexCoord:hash()
  return tostring(self)
end

function HexCoord:pixelCoordinates(size)
  local x = size * 1.5 * self.x
  local y = size * (SQRT_3 / 2 * self.x + SQRT_3 * self.z)
  return x, y
end

function HexCoord:new(x, y, z)
  local coord = {["x"] = x, ["y"] = y, ["z"] = z}
  if coord.x == -0 then
    coord.x = 0
  end
  if coord.y == -0 then
    coord.y = 0
  end
  if coord.z == -0 then
    coord.z = 0
  end
  setmetatable(coord, self)
  self.__index = self
  return coord
end

function HexCoord:fromPixelCoordinate(pixelX, pixelY, size)
  local x = (2.0 / 3) * pixelX / size
  local z = (-1.0 / 3 * pixelX + SQRT_3 / 3.0 * pixelY) / size
  local y = -x - z

  local rx = math.floor(x + 0.5)
  local ry = math.floor(y + 0.5)
  local rz = math.floor(z + 0.5)

  local xDiff = math.abs(rx - x)
  local yDiff = math.abs(ry - y)
  local zDiff = math.abs(rz - z)

  if (xDiff > yDiff) and (xDiff > zDiff) then
    rx = -ry - rz
  elseif (yDiff > zDiff) then
    ry = -rx - rz
  else
    rz = -rx - ry
  end

  return self:new(rx, ry, rz)
end

function HexCoord:neighbors()
  return {
    HexCoord:new(self.x + 1, self.y - 1, self.z),
    HexCoord:new(self.x + 1, self.y, self.z - 1),
    HexCoord:new(self.x - 1, self.y + 1, self.z),
    HexCoord:new(self.x, self.y + 1, self.z - 1),
    HexCoord:new(self.x - 1, self.y, self.z + 1),
    HexCoord:new(self.x, self.y - 1, self.z + 1)
  }
end

return HexCoord
