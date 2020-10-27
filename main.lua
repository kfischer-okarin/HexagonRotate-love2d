function buildField()
  result = HashTable:new()
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
  HexCoord = require('hexcoord')
  HashTable = require('hashtable')
  hex = love.graphics.newImage("hex.png")
  HEX_DIMENSIONS = {
    90 / hex:getHeight(), -- sx
    90 / hex:getHeight(), -- sy
    hex:getWidth() / 2, -- ox
    hex:getHeight() / 2 -- oy
  }

  selectedHex = love.graphics.newImage("hex-selected.png")
  love.window.setMode(450, 800, {["centered"] = true, ["resizable"] = false})

  field = buildField()
end


Hex = {}

Hex.__index = Hex

function Hex:new()
  local obj = {
    ["color"] = { math.random(0.5, 1), math.random(0.5, 1), math.random(0.5, 1) },
    ["selected"] = false
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
  love.graphics.setColor(self.color)
  love.graphics.draw(self:image(), x, y, 0, unpack(HEX_DIMENSIONS))
  love.graphics.setColor(1, 1, 1)
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
