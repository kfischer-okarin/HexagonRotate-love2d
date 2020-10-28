HexCoord = require('hexcoord')
HashTable = require('hashtable')

HexField = HashTable:new()

function HexField:containsCoordinates(...)
  local arg = {...}
  for i, coord in ipairs(arg) do
    if self:get(coord) == nil then
      return false
    end
  end

  return true
end

function buildField()
  result = HexField:new()
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
  HEX_SIZE = 50
  RISE_HEIGHT = HEX_SIZE / 2
  HEX_DIMENSIONS = {
    90 / hex:getHeight(), -- sx
    90 / hex:getHeight(), -- sy
    hex:getWidth() / 2, -- ox
    hex:getHeight() / 2 -- oy
  }

  local screen_w = 450
  local screen_h = 800
  love.window.setMode(screen_w, screen_h, {["centered"] = true, ["resizable"] = false})

  mode = "UNSELECTED"
  field = buildField()
  field.transform = love.math.newTransform(screen_w / 2, screen_h / 2)
end


Hex = {}

function Hex:new()
  local obj = {
    ["color"] = { math.random(0.5, 1), math.random(0.5, 1), math.random(0.5, 1) },
    ["selected"] = false
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function Hex:image()
  if self.selected then
    return selectedHex
  end

  return hex
end

function Hex:draw(hexCoord)
  local position = hexCoord:pixelCoordinates(HEX_SIZE)
  love.graphics.setColor(self.color)
  love.graphics.draw(self:image(), position.x, position.y, 0, unpack(HEX_DIMENSIONS))
  love.graphics.setColor(1, 1, 1)
end

Selection = {}

function Selection:new(center, selected)
  local obj = {
    ["center"] = center,
    ["selected"] = selected,
    ["z"] = 0,
    ["transform"] = love.math.newTransform()
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function Selection:setZ(value)
  self.z = value
  self.transform = love.math.newTransform(0, -value)
end


function love.mousereleased(x, y, button, istouch, presses)
  if mode == "UNSELECTED" then
    local fieldX, fieldY = field.transform:inverseTransformPoint(x, y)
    local hexCoord = HexCoord:fromPixelCoordinate(fieldX, fieldY, HEX_SIZE)
    local neighbors = hexCoord:neighbors()

    if field:containsCoordinates(hexCoord, unpack(neighbors)) then
      selection = Selection:new(hexCoord, neighbors)
      for i, selected in ipairs(neighbors) do
        field:get(selected).selected = true
      end
      mode = "RISING_ANIMATION"
      animation_progress = 0
    end
  elseif mode == "NOT_DRAGGING" then
    mode = "SINKING_ANIMATION"
    animation_progress = 0
  end
end

RISE_DURATION = 0.2

function lerp(a, b, t)
  local clampedT = math.min(math.max(0, t), 1)
  return a * (1 - clampedT) + b * clampedT
end

function love.update(dt)
  if mode == "RISING_ANIMATION" then
    animation_progress = animation_progress + dt / RISE_DURATION
    selection:setZ(lerp(0, RISE_HEIGHT, animation_progress))
    if selection.z >= RISE_HEIGHT then
      selection:setZ(RISE_HEIGHT)
      mode = "NOT_DRAGGING"
    end
  elseif mode == "SINKING_ANIMATION" then
    animation_progress = animation_progress + dt / RISE_DURATION
    selection:setZ(lerp(RISE_HEIGHT, 0, animation_progress))
    if selection.z <= 0 then
      selection:setZ(0)
      mode = "UNSELECTED"

      for i, selected in ipairs(selection.selected) do
        field:get(selected).selected = false
      end
      selection = nil
    end
  end
end

function drawField()
  love.graphics.push()
  love.graphics.applyTransform(field.transform)

  for coord, hex in field:each() do
    if not hex.selected then
      hex:draw(coord)
    end
  end

  if selection ~= nil then
    love.graphics.applyTransform(selection.transform)

    for coord, hex in field:each() do
      if hex.selected then
        hex:draw(coord)
      end
    end
  end

  love.graphics.pop()
end

function love.draw()
  drawField()
end
