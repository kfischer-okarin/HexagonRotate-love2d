g = {}

HexCoord = require('hexcoord')
HashTable = require('hashtable')

function love.load()
  g.hexImage = love.graphics.newImage("hex.png")
  g.selectedHexImage = love.graphics.newImage("hex-selected.png")
  HEX_SIZE = 50
  RISE_HEIGHT = HEX_SIZE / 2
  g.hexDimensions = {
    90 / g.hexImage:getHeight(), -- sx
    90 / g.hexImage:getHeight(), -- sy
    g.hexImage:getWidth() / 2, -- ox
    g.hexImage:getHeight() / 2 -- oy
  }

  local screen_w = 450
  local screen_h = 800
  love.window.setMode(screen_w, screen_h, {["centered"] = true, ["resizable"] = false})

  g.mode = "UNSELECTED"
  g.field = HashTable:new()
  for x=-2, 2 do
    for y=-2, 3 do
      for z=-3, 2 do
        if (x + y + z) == 0 then
          g.field:set(HexCoord:new(x, y, z), Hex:new())
        end
      end
    end
  end
  g.field.transform = love.math.newTransform(screen_w / 2, screen_h / 2)
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
    return g.selectedHexImage
  end

  return g.hexImage
end

function Hex:draw(hexCoord)
  local x, y = hexCoord:pixelCoordinates(HEX_SIZE)
  love.graphics.setColor(self.color)
  love.graphics.draw(self:image(), x, y, 0, unpack(g.hexDimensions))
  love.graphics.setColor(1, 1, 1)
end

Selection = {}

function Selection:new(center, selected)
  local obj = {
    ["center"] = center,
    ["selected"] = selected,
    ["z"] = 0,
    ["rotation"] = 0,
    ["rotationVelocity"] = 0,
    ["transform"] = love.math.newTransform()
  }
  setmetatable(obj, self)
  self.__index = self
  obj.offsetX, obj.offsetY = obj.center:pixelCoordinates(HEX_SIZE)
  return obj
end

function Selection:calcTransform()
  self.transform = love.math.newTransform(0, -self.z, self.rotation)
end

function Selection:setZ(value)
  self.z = value
  self:calcTransform()
end

function Selection:setRotation(value)
  self.rotation = value
  self:calcTransform()
end

function Selection:calcCenterCoords()
  local x, y = self.center:pixelCoordinates(HEX_SIZE)
  x, y = g.field.transform:transformPoint(x, y)
  self.x, self.y = self.transform:transformPoint(x, y)
end

function Selection:calcMouseAngle(x, y)
  local offsetX = x - self.x
  local offsetY = y - self.y
  local result = math.acos(- offsetY / math.sqrt(offsetX * offsetX + offsetY * offsetY))
  if offsetX < 0 then
    result = 2 * math.pi - result
  end
  self.mouseAngle = result
end

function Selection:calcTargetRotation()
  local dragRotation = angleDiff(self.dragStartAngle, self.mouseAngle)
  local snappedDragRotation = snapRotation(dragRotation)
  self.targetRotation = self.dragStartRotation + snappedDragRotation
end

function Selection:calcRotationVelocity(dt)
  local force = angleDiff(self.rotation, self.targetRotation)
  local damping = - self.rotationVelocity * 10
  self.rotationVelocity = self.rotationVelocity + dt * (force + damping)
end

function Selection:handleSnap()
  local diffToTargetRotation = math.abs(angleDiff(self.rotation, self.targetRotation))
  if diffToTargetRotation < DEG_1 and math.abs(self.rotationVelocity) < DEG_1 then
    self:setRotation(self.targetRotation)
    self.rotationVelocity = 0
  end
end

DEG_360 = 2 * math.pi
DEG_180 = math.pi
DEG_90 = math.pi / 2
DEG_60 = math.pi / 3
DEG_1 = math.pi / 180

function snapRotation(radians)
  return math.floor((radians % DEG_360) / DEG_60 + 0.5) * DEG_60
end

function angleDiff(startAngle, endAngle)
  local normalizedStart = startAngle
  local normalizedEnd = endAngle
  while math.abs(normalizedEnd - normalizedStart) > DEG_180 do
    normalizedStart = (normalizedStart + DEG_90) % DEG_360
    normalizedEnd = (normalizedEnd + DEG_90) % DEG_360
  end
  return normalizedEnd - normalizedStart
end

function love.mousepressed(x, y, button, istouch, presses)
  if g.mode == "NOT_DRAGGING" then
    local fieldX, fieldY = g.selection.transform:inverseTransformPoint(x, y)
    fieldX, fieldY = g.field.transform:inverseTransformPoint(fieldX, fieldY)
    local hexCoord = HexCoord:fromPixelCoordinate(fieldX, fieldY, HEX_SIZE)
    local clickedHex = g.field:get(hexCoord)
    if clickedHex ~= nil and clickedHex.selected then
      g.selection:calcMouseAngle(x, y)
      g.selection.dragStartAngle = g.selection.mouseAngle
      g.selection.dragStartRotation = snapRotation(g.selection.rotation)
      g.mode = "DRAGGING"
    end
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  if g.mode == "DRAGGING" then
    g.selection:calcMouseAngle(x, y)
  end
end

function love.mousereleased(x, y, button, istouch, presses)
  if g.mode == "UNSELECTED" then
    local fieldX, fieldY = g.field.transform:inverseTransformPoint(x, y)
    local hexCoord = HexCoord:fromPixelCoordinate(fieldX, fieldY, HEX_SIZE)
    local neighbors = hexCoord:neighbors()

    if g.field:contains(hexCoord, unpack(neighbors)) then
      g.selection = Selection:new(hexCoord, neighbors)
      for i, selected in ipairs(neighbors) do
        g.field:get(selected).selected = true
      end
      g.mode = "RISING_ANIMATION"
      g.animation_progress = 0
    end
  elseif g.mode == "NOT_DRAGGING" then
    g.mode = "SINKING_ANIMATION"
    g.animation_progress = 0
  elseif g.mode == "DRAGGING" then
    g.mode = "NOT_DRAGGING"
  end
end

RISE_DURATION = 0.2

function lerp(a, b, t)
  local clampedT = math.min(math.max(0, t), 1)
  return a * (1 - clampedT) + b * clampedT
end

function love.update(dt)
  if g.mode == "RISING_ANIMATION" then
    g.animation_progress = g.animation_progress + dt / RISE_DURATION
    g.selection:setZ(lerp(0, RISE_HEIGHT, g.animation_progress))
    if g.selection.z >= RISE_HEIGHT then
      g.selection:setZ(RISE_HEIGHT)
      g.selection:calcCenterCoords()
      g.mode = "NOT_DRAGGING"
    end
  elseif g.mode == "SINKING_ANIMATION" then
    g.animation_progress = g.animation_progress + dt / RISE_DURATION
    g.selection:setZ(lerp(RISE_HEIGHT, 0, g.animation_progress))
    if g.selection.z <= 0 then
      g.selection:setZ(0)
      g.mode = "UNSELECTED"

      for i, selected in ipairs(g.selection.selected) do
        g.field:get(selected).selected = false
      end
      selection = nil
    end
  elseif g.mode == "DRAGGING" then
    g.selection:calcTargetRotation()
    g.selection:calcRotationVelocity(dt)
    g.selection:setRotation(g.selection.rotation + g.selection.rotationVelocity)
    g.selection:handleSnap()
  end
end

function drawField()
  love.graphics.push()
  love.graphics.applyTransform(g.field.transform)

  for coord, hex in g.field:each() do
    if not hex.selected then
      hex:draw(coord)
    end
  end

  if g.selection ~= nil then
    love.graphics.translate(g.selection.offsetX, g.selection.offsetY)
    love.graphics.applyTransform(g.selection.transform)

    for coord, hex in g.field:each() do
      if hex.selected then
        hex:draw(coord - g.selection.center)
      end
    end
  end

  love.graphics.pop()
end

function love.draw()
  drawField()
end
