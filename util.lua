local util = {}

function util.round(a)
  return math.floor(a + 0.5)
end

function util.lerp(a, b, t)
  local clampedT = math.min(math.max(0, t), 1)
  return a * (1 - clampedT) + b * clampedT
end

util.DEG_360 = 2 * math.pi
util.DEG_180 = math.pi
util.DEG_90 = math.pi / 2
util.DEG_60 = math.pi / 3
util.DEG_1 = math.pi / 180

function util.angleDiff(startAngle, endAngle)
  local normalizedStart = startAngle
  local normalizedEnd = endAngle
  while math.abs(normalizedEnd - normalizedStart) > util.DEG_180 do
    normalizedStart = (normalizedStart + util.DEG_90) % util.DEG_360
    normalizedEnd = (normalizedEnd + util.DEG_90) % util.DEG_360
  end
  return normalizedEnd - normalizedStart
end

return util
