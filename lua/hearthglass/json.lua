-- ============================================================================
-- hearthglass/json.lua
--
-- Small canonical JSON encoder for generated palette snapshots. Object keys
-- are sorted and arrays stay on one line, so exporting the same palette twice
-- produces identical bytes. The kitty and KDE exporters share it; the drift
-- check uses it to compare generated snapshots byte for byte.
-- ============================================================================

local M = {}

local function is_array(value)
  local count = 0
  for key in pairs(value) do
    if type(key) ~= 'number' then
      return false
    end
    count = count + 1
  end
  for i = 1, count do
    if value[i] == nil then
      return false
    end
  end
  return true
end

local ESCAPES = {
  ['"'] = '\\"',
  ['\\'] = '\\\\',
  ['\b'] = '\\b',
  ['\f'] = '\\f',
  ['\n'] = '\\n',
  ['\r'] = '\\r',
  ['\t'] = '\\t',
}

local function escape(str)
  return (str:gsub('[%c"\\]', function(ch)
    return ESCAPES[ch] or string.format('\\u%04x', ch:byte())
  end))
end

local function encode(value, level)
  level = level or 0
  local indent = string.rep('  ', level)
  local inner = string.rep('  ', level + 1)

  local value_type = type(value)
  if value_type == 'string' then
    return '"' .. escape(value) .. '"'
  elseif value_type == 'number' then
    return tostring(value)
  elseif value_type == 'boolean' then
    return tostring(value)
  elseif value_type == 'nil' then
    return 'null'
  end

  if is_array(value) then
    local items = {}
    for _, item in ipairs(value) do
      table.insert(items, encode(item, level + 1))
    end
    return '[' .. table.concat(items, ', ') .. ']'
  end

  local keys = {}
  for key in pairs(value) do
    table.insert(keys, key)
  end
  table.sort(keys)
  if #keys == 0 then
    return '{}'
  end
  local lines = {}
  for _, key in ipairs(keys) do
    local item = value[key]
    if item ~= nil then
      table.insert(lines, inner .. '"' .. escape(key) .. '": ' .. encode(item, level + 1))
    end
  end
  return '{\n' .. table.concat(lines, ',\n') .. '\n' .. indent .. '}'
end

--- Canonical JSON text. Callers append the trailing newline they want.
---@param value any
---@return string
function M.encode(value)
  return encode(value)
end

return M
