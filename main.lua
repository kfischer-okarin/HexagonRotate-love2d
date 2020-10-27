HexCoord = {}

HexCoord.__index = HexCoord

HexCoord.__eq = function(a, b)
  return a.x == b.x and a.y == b.y and a.z == b.z
end

HexCoord.__tostring = function(self)
  return "HexCoord(" .. self.x .. ", " .. self.y .. ", " .. self.z .. ")"
end

HexCoord.SQRT_3 = math.sqrt(3)

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


Hex = {}

Hex.__index = Hex

function Hex:new()
  local obj = {
    ["selected"] = false,
    ["ox"] = hex:getWidth() / 2,
    ["oy"] = hex:getHeight() / 2,
    ["sx"] = 90 / hex:getHeight(),
    ["sy"] = 90 / hex:getHeight()
  }
  setmetatable(obj, self)
  return obj
end

function Hex:image()
  if self.selected then
    return selectedHex
  end

  return hex
end

function Hex:draw(x, y)
  love.graphics.draw(self:image(), x, y, 0, self.sx, self.sy, self.ox, self.oy)
end


HexField = {}

HexField.__index = HexField

function HexField:hash(coord)
  local hash = tostring(coord)
  self.keys[hash] = self.keys[hash] or coord
  return hash
end

function HexField:set(coord, hex)
  self[self:hash(coord)] = hex
end

function HexField:get(coord)
  return self[self:hash(coord)]
end

function HexField:each()
  local lastKey = nil
  return function()
    local nextKey = next(self.keys, lastKey)
    lastKey = nextKey
    return self.keys[nextKey], self:get(nextKey)
  end
end


function buildField()
  result = {["keys"] = {}}
  setmetatable(result, HexField)
  for x=-2, 2 do
    for y=-2, 3 do
      for z=-3, 2 do
        if (x + y + z) == 0 then
          result:set(HexCoord:new(x, y, z), Hex:new())
        end
      end
    end
  end

  return result
end

function love.load()
  hex = love.graphics.newImage("hex.png")
  selectedHex = love.graphics.newImage("hex-selected.png")
  love.window.setMode(450, 800, {["centered"] = true, ["resizable"] = false})

  field = buildField()
end

function drawField()
  love.graphics.push()
  love.graphics.translate(225, 400)

  for coord, hex in field:each() do
    local position = coord:pixelCoordinates(50)
    hex:draw(position.x, position.y)
  end

  love.graphics.pop()
end

function love.draw()
  drawField()
end
