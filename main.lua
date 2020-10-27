HexCoord = require('hexcoord')
HashTable = require('hashtable')

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
