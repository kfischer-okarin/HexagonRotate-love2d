-- Extended Lua Table which hashes keys before inserting/getting them
local HashTable = {}

function HashTable:new()
  result = {["__keysByHash"] = {}}
  setmetatable(result, self)
  self.__index = self
  return result
end

function HashTable:set(key, value)
  local hash = key:hash()
  self.__keysByHash[hash] = key
  self[hash] = value
end

function HashTable:get(key)
  local hash = key:hash()
  return self[hash]
end

function HashTable:each()
  local lastHash = nil

  return function()
    local nextHash = next(self.__keysByHash, lastHash)
    lastHash = nextHash
    return self.__keysByHash[nextHash], self[nextHash]
  end
end

function HashTable:contains(...)
  local arg = {...}
  for i, value in ipairs(arg) do
    if self:get(value) == nil then
      return false
    end
  end

  return true
end

return HashTable
