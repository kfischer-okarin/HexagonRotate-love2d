HexCoord = require('hexcoord')
HashTable = require('hashtable')

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
  HEX_IMAGE = love.graphics.newImage("hex.png")
  SELECTED_HEX_IMAGE = love.graphics.newImage("hex-selected.png")
  HEX_SIZE = 50
  RISE_HEIGHT = HEX_SIZE / 2
  HEX_DIMENSIONS = {
    90 / HEX_IMAGE:getHeight(), -- sx
    90 / HEX_IMAGE:getHeight(), -- sy
    HEX_IMAGE:getWidth() / 2, -- ox
    HEX_IMAGE:getHeight() / 2 -- oy
  }

  local screen_w = 450
  local screen_h = 800
  love.window.setMode(screen_w, screen_h, {["centered"] = true, ["resizable"] = false})

  mode = "UNSELECTED"
  FIELD = buildField()
  FIELD.transform = love.math.newTransform(screen_w / 2, screen_h / 2)
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
    return SELECTED_HEX_IMAGE
  end

  return HEX_IMAGE
end

function Hex:draw(hexCoord)
  local x, y = hexCoord:pixelCoordinates(HEX_SIZE)
  love.graphics.setColor(self.color)
  love.graphics.draw(self:image(), x, y, 0, unpack(HEX_DIMENSIONS))
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
  x, y = FIELD.transform:transformPoint(x, y)
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
  if diffToTargetRotation < DEG_1 and math.abs(self.rotationVelocity) < 0.01 then
    self:setRotation(self.targetRotation)
    self.rotationVelocity = 0
  end
end

DEG_360 = 2 * math.pi
DEG_60 = math.pi / 3
DEG_90 = math.pi / 2
DEG_180 = math.pi
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
  if mode == "NOT_DRAGGING" then
    local fieldX, fieldY = selection.transform:inverseTransformPoint(x, y)
    fieldX, fieldY = FIELD.transform:inverseTransformPoint(fieldX, fieldY)
    local hexCoord = HexCoord:fromPixelCoordinate(fieldX, fieldY, HEX_SIZE)
    local clickedHex = FIELD:get(hexCoord)
    if clickedHex ~= nil and clickedHex.selected then
      selection:calcMouseAngle(x, y)
      selection.dragStartAngle = selection.mouseAngle
      selection.dragStartRotation = snapRotation(selection.rotation)
      mode = "DRAGGING"
    end
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  if mode == "DRAGGING" then
    selection:calcMouseAngle(x, y)
  end
end

function love.mousereleased(x, y, button, istouch, presses)
  if mode == "UNSELECTED" then
    local fieldX, fieldY = FIELD.transform:inverseTransformPoint(x, y)
    local hexCoord = HexCoord:fromPixelCoordinate(fieldX, fieldY, HEX_SIZE)
    local neighbors = hexCoord:neighbors()

    if FIELD:contains(hexCoord, unpack(neighbors)) then
      selection = Selection:new(hexCoord, neighbors)
      for i, selected in ipairs(neighbors) do
        FIELD:get(selected).selected = true
      end
      mode = "RISING_ANIMATION"
      animation_progress = 0
    end
  elseif mode == "NOT_DRAGGING" then
    mode = "SINKING_ANIMATION"
    animation_progress = 0
  elseif mode == "DRAGGING" then
    mode = "NOT_DRAGGING"
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
      selection:calcCenterCoords()
      mode = "NOT_DRAGGING"
    end
  elseif mode == "SINKING_ANIMATION" then
    animation_progress = animation_progress + dt / RISE_DURATION
    selection:setZ(lerp(RISE_HEIGHT, 0, animation_progress))
    if selection.z <= 0 then
      selection:setZ(0)
      mode = "UNSELECTED"

      for i, selected in ipairs(selection.selected) do
        FIELD:get(selected).selected = false
      end
      selection = nil
    end
  elseif mode == "DRAGGING" then
    selection:calcTargetRotation()
    selection:calcRotationVelocity(dt)
    selection:setRotation(selection.rotation + selection.rotationVelocity)
    selection:handleSnap()
  end
end

function drawField()
  love.graphics.push()
  love.graphics.applyTransform(FIELD.transform)

  for coord, hex in FIELD:each() do
    if not hex.selected then
      hex:draw(coord)
    end
  end

  if selection ~= nil then
    love.graphics.translate(selection.offsetX, selection.offsetY)
    love.graphics.applyTransform(selection.transform)

    for coord, hex in FIELD:each() do
      if hex.selected then
        hex:draw(coord - selection.center)
      end
    end
  end

  love.graphics.pop()
end

function love.draw()
  drawField()
end
