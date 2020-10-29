g = {}

util = require('util')
HexCoord = require('hexcoord')
HashTable = require('hashtable')

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
  love.graphics.draw(self:image(), x, y, 0, unpack(self.dimensions))
  love.graphics.setColor(1, 1, 1)
end

HexField = HashTable:new()

function HexField:new()
  local field = HashTable:new()
  field.transform = love.math.newTransform(SCREEN_W / 2, SCREEN_H / 2)

  setmetatable(field, self)
  self.__index = self
  return field
end

function HexField:hexCoordAtPixelCoordinates(pixelX, pixelY)
  local x, y =  self.transform:inverseTransformPoint(pixelX, pixelY)
  return HexCoord:fromPixelCoordinate(x, y, HEX_SIZE)
end

function HexField:hexAtPixelCoordinates(pixelX, pixelY)
  local hexCoord = self:hexCoordAtPixelCoordinates(pixelX, pixelY)
  local clickedHex = self:get(hexCoord)
  return clickedHex, hexCoord
end

function loadImages()
  g.hexImage = love.graphics.newImage("hex.png")
  g.selectedHexImage = love.graphics.newImage("hex-selected.png")
  HEX_SIZE = 50
  RISE_HEIGHT = HEX_SIZE / 2
  Hex.dimensions = {
    90 / g.hexImage:getHeight(), -- sx
    90 / g.hexImage:getHeight(), -- sy
    g.hexImage:getWidth() / 2, -- ox
    g.hexImage:getHeight() / 2 -- oy
  }
end

function setWindowSize()
  SCREEN_W = 450
  SCREEN_H = 800
  love.window.setMode(SCREEN_W, SCREEN_H, {["centered"] = true, ["resizable"] = false})
end

function initializeState()
  g.mode = "UNSELECTED"
  g.field = HexField:new()
  for x=-2, 2 do
    for y=-2, 3 do
      for z=-3, 2 do
        if (x + y + z) == 0 then
          g.field:set(HexCoord:new(x, y, z), Hex:new())
        end
      end
    end
  end

end

function love.load()
  loadImages()
  setWindowSize()
  initializeState()
end

Selection = {}

function Selection:new(center, selected)
  local obj = {
    ["center"] = center,
    ["selected"] = selected,
    ["z"] = 0,
    ["rotation"] = 0,
    ["rotationVelocity"] = 0,
    ["dragStartRotation"] = 0,
    ["targetRotation"] = 0,
    ["transform"] = love.math.newTransform()
  }
  setmetatable(obj, self)
  self.__index = self
  obj.offsetX, obj.offsetY = obj.center:pixelCoordinates(HEX_SIZE)

  for i, selected in ipairs(selected) do
    g.field:get(selected).selected = true
  end

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

function Selection:calcCenterPixelCoords()
  local x, y = self.center:pixelCoordinates(HEX_SIZE)
  x, y = g.field.transform:transformPoint(x, y)
  self.x, self.y = self.transform:transformPoint(x, y)
end

-- Mouse angle on the selection circle: up 0 deg, right 90 deg, left 270 deg
function Selection:calcMouseAngle(x, y)
  local offsetX = x - self.x
  local offsetY = y - self.y
  local result = math.acos(- offsetY / math.sqrt(offsetX * offsetX + offsetY * offsetY))
  if offsetX < 0 then
    result = 2 * math.pi - result
  end
  self.mouseAngle = result
end

function Selection:startRotation(x, y)
  self:calcMouseAngle(x, y)
  self.dragStartAngle = self.mouseAngle
  self.dragStartRotation = util.snapRotation(self.rotation)
  self.targetRotation = self.dragStartRotation
end

function Selection:updateTargetRotation()
  local dragRotation = util.angleDiff(self.dragStartAngle, self.mouseAngle)
  local snappedDragRotation = util.snapRotation(dragRotation)
  self.targetRotation = self.dragStartRotation + snappedDragRotation
end

function Selection:updateRotationVelocity(dt)
  local force = util.angleDiff(self.rotation, self.targetRotation)
  local damping = - self.rotationVelocity * 10
  self.rotationVelocity = self.rotationVelocity + dt * (force + damping)
end

function Selection:handleSnap()
  local diffToTargetRotation = math.abs(util.angleDiff(self.rotation, self.targetRotation))
  if diffToTargetRotation < util.DEG_1 and math.abs(self.rotationVelocity) < util.DEG_1 then
    self:setRotation(self.targetRotation)
    self.rotationVelocity = 0
  end
end

function Selection:handleRotation(dt)
  self:updateRotationVelocity(dt)
  self:setRotation(self.rotation + self.rotationVelocity)
  self:handleSnap()
end

function Selection:insideSelection(x, y)
  local clickedHex = g.field:hexAtPixelCoordinates(x, y)
  return clickedHex ~= nil and clickedHex.selected
end

function Selection:applyRotationAndUnselectHexes()
  local hexesToUpdate = HashTable:new()
  for i, selected in ipairs(self.selected) do
    hexesToUpdate:set(selected, g.field:get(selected))
  end

  for i, selected in ipairs(self.selected) do
    local hex = hexesToUpdate:get(selected)

    local rotatedCoord = selected:rotate(self.rotation, self.center)
    g.field:set(rotatedCoord, hex)
    hex.selected = false
  end
end

function love.mousepressed(x, y, button, istouch, presses)
  if g.mode == "NOT_DRAGGING" then
    if g.selection:insideSelection(x, y) then
      g.selection:startRotation(x, y)
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
    local hexCoord = g.field:hexCoordAtPixelCoordinates(x, y)
    local neighbors = hexCoord:neighbors()

    if g.field:contains(hexCoord, unpack(neighbors)) then
      g.selection = Selection:new(hexCoord, neighbors)
      g.mode = "RISING_ANIMATION"
      g.animation_progress = 0
    end
  elseif g.mode == "NOT_DRAGGING" then
    if g.selection.rotationVelocity == 0 then
      g.mode = "SINKING_ANIMATION"
      g.animation_progress = 0
    end
  elseif g.mode == "DRAGGING" then
    g.mode = "NOT_DRAGGING"
  end
end

RISE_DURATION = 0.2

function love.update(dt)
  if g.mode == "RISING_ANIMATION" then
    g.animation_progress = g.animation_progress + dt / RISE_DURATION
    g.selection:setZ(util.lerp(0, RISE_HEIGHT, g.animation_progress))
    if g.selection.z >= RISE_HEIGHT then
      g.selection:setZ(RISE_HEIGHT)
      g.selection:calcCenterPixelCoords()
      g.mode = "NOT_DRAGGING"
    end
  elseif g.mode == "SINKING_ANIMATION" then
    g.animation_progress = g.animation_progress + dt / RISE_DURATION
    g.selection:setZ(util.lerp(RISE_HEIGHT, 0, g.animation_progress))
    if g.selection.z <= 0 then
      g.selection:setZ(0)
      g.selection:applyRotationAndUnselectHexes()
      selection = nil

      g.mode = "UNSELECTED"
    end
  elseif g.mode == "DRAGGING" then
    g.selection:updateTargetRotation()
    g.selection:handleRotation(dt)
  elseif g.mode == "NOT_DRAGGING" then
    g.selection:handleRotation(dt)
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
