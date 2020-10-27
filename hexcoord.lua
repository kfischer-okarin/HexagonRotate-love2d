local HexCoord = {}

HexCoord.__index = HexCoord

HexCoord.__eq = function(a, b)
  return a.x == b.x and a.y == b.y and a.z == b.z
end

HexCoord.__tostring = function(self)
  return "HexCoord(" .. self.x .. ", " .. self.y .. ", " .. self.z .. ")"
end

HexCoord.SQRT_3 = math.sqrt(3)

function HexCoord:hash()
  return tostring(self)
end

function HexCoord:pixelCoordinates(size)
  local x = size * 1.5 * self.x
  local y = size * (HexCoord.SQRT_3 / 2 * self.x + HexCoord.SQRT_3 * self.z)
  return {["x"] = x, ["y"] = y}
end

function HexCoord:new(x, y, z)
  local coord = {["x"] = x, ["y"] = y, ["z"] = z}
  setmetatable(coord, self)
  return coord
end

return HexCoord
