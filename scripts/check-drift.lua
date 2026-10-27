-- ============================================================================
-- scripts/check-drift.lua
--
-- Proves the shipped integrations still carry the palettes from
-- lua/hearthglass/themes.lua (expanded by lua/hearthglass/colors.lua):
--
--   * kitty/palettes.json matches every exported slot exactly, and every
--     shipped kitty/<key>.conf uses those slots;
--   * every zed/<key>.json is byte-for-byte what hearthglass.zed generates;
--   * kde/palettes.json matches every exported theme and face exactly, and
--     kde/themes.json covers the same family in the same order.
--
-- Run from the repo root with Neovim:
--
--   nvim --headless -l scripts/check-drift.lua
--
-- Exits 1 on the first mismatch (it keeps checking and reports every one).
-- ============================================================================

local script = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(script, ':p:h:h')

vim.opt.runtimepath:prepend(root)
package.path = root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path

local themes = require('hearthglass.themes')
local colors = require('hearthglass.colors')
local json = require('hearthglass.json')

local failures = 0

local function fail(message)
  failures = failures + 1
  print('FAIL ' .. message)
end

local function read_file(path)
  local handle = io.open(path, 'r')
  if not handle then
    return nil
  end
  local contents = handle:read('*a')
  handle:close()
  return contents
end

local function decode_json(path)
  local contents = read_file(path)
  if not contents then
    fail('missing ' .. path)
    return nil
  end
  local ok, value = pcall(vim.json.decode, contents)
  if not ok then
    fail('invalid JSON in ' .. path)
    return nil
  end
  return value
end

local function same_keys(actual, expected)
  for key in pairs(expected) do
    if actual[key] == nil then
      return false
    end
  end
  for key in pairs(actual) do
    if expected[key] == nil then
      return false
    end
  end
  return true
end

local function deep_equal(actual, expected, path)
  if type(actual) ~= type(expected) then
    fail(('%s type differs (%s vs %s)'):format(path, type(actual), type(expected)))
    return false
  end
  if type(actual) ~= 'table' then
    if actual ~= expected then
      fail(('%s differs (%s vs %s)'):format(path, tostring(actual), tostring(expected)))
      return false
    end
    return true
  end
  if not same_keys(actual, expected) then
    fail(path .. ' keys differ')
    return false
  end
  local ok = true
  for key, value in pairs(expected) do
    if not deep_equal(actual[key], value, path .. '.' .. tostring(key)) then
      ok = false
    end
  end
  return ok
end

local function brighten(hex, amount)
  return colors.blend(hex, '#ffffff', amount)
end

local function kitty_face(key, face, options)
  local c = colors.get_colors(themes.variant(key, face), options)
  local dark = face == 'dark'
  for _, name in ipairs({ 'red', 'green', 'yellow', 'blue', 'purple', 'cyan' }) do
    c['bright_' .. name] = brighten(c[name], 0.22)
  end
  c.bright_base0 = brighten(dark and c.base0 or c.base7, dark and 0.2 or 0.3)
  return c
end

local variants = {
  { name = 'plain', options = { colorblind = false, low_blue_light = false }, light_only = false },
  { name = 'deutan', options = { colorblind = 'deutan', low_blue_light = false }, light_only = false },
  { name = 'tritan', options = { colorblind = 'tritan', low_blue_light = false }, light_only = false },
  { name = 'plain_low', options = { colorblind = false, low_blue_light = true }, light_only = true },
  { name = 'deutan_low', options = { colorblind = 'deutan', low_blue_light = true }, light_only = true },
  { name = 'tritan_low', options = { colorblind = 'tritan', low_blue_light = true }, light_only = true },
}

-- ---------------------------------------------------------------------------
-- kitty
-- ---------------------------------------------------------------------------

print('kitty')
local kitty_failures = failures
local kitty = decode_json(root .. '/kitty/palettes.json')
if kitty then
  if not deep_equal(kitty.order, themes.keys(), 'kitty.order') then
    -- deep_equal reports the mismatch
  end
  for _, key in ipairs(themes.keys()) do
    local theme = kitty.themes[key]
    if not theme then
      fail('kitty.palettes.json is missing ' .. key)
    else
      local meta = themes.get(key)
      if theme.name ~= meta.name or theme.tagline ~= meta.tagline then
        fail('kitty metadata differs for ' .. key)
      end
      for _, face in ipairs({ 'dark', 'light' }) do
        for _, variant in ipairs(variants) do
          if face == 'light' or not variant.light_only then
            local expected = kitty_face(key, face, variant.options)
            deep_equal(theme.faces[face][variant.name], expected,
              ('kitty.%s.%s.%s'):format(key, face, variant.name))
          end
        end
      end
    end
  end
  if failures == kitty_failures then
    print('  kitty/palettes.json matches themes.lua')
  end
end

-- The shipped confs are the plain (no option) face. Parse the colour keys and
-- compare them to the same exported slots the generator uses.
local conf_keys = {
  background = 'base7', foreground = 'base0', cursor = 'orange',
  cursor_text_color = 'base7', selection_background = 'base5',
  selection_foreground = 'base0', url_color = 'blue',
  color0 = 'color0', color1 = 'red', color2 = 'green', color3 = 'yellow',
  color4 = 'blue', color5 = 'purple', color6 = 'cyan', color7 = 'color7',
  color8 = 'base4', color9 = 'bright_red', color10 = 'bright_green',
  color11 = 'bright_yellow', color12 = 'bright_blue', color13 = 'bright_purple',
  color14 = 'bright_cyan', color15 = 'bright_base0',
}

local conf_failures = failures
for _, key in ipairs(themes.keys()) do
  for _, face in ipairs({ 'dark', 'light' }) do
    local c = kitty_face(key, face, { colorblind = false, low_blue_light = false })
    local expected = {}
    for out_name, palette_name in pairs(conf_keys) do
      expected[out_name] = c[palette_name]
    end
    expected.color0 = face == 'dark' and c.base7 or c.base0
    expected.color7 = face == 'dark' and c.base0 or c.base7

    local conf_name = face == 'dark' and (key .. '.conf') or (key .. '-light.conf')
    if key == 'hearthglass' then
      conf_name = face == 'dark' and 'hearthglass.conf' or 'hearthglass-light.conf'
    end
    local contents = read_file(root .. '/kitty/' .. conf_name)
    if not contents then
      fail('missing kitty/' .. conf_name)
    else
      local seen = {}
      for line in contents:gmatch('[^\n]+') do
        local name, value = line:match('^([%w_]+)%s+(#%x%x%x%x%x%x)$')
        if name and expected[name] then
          seen[name] = value
          if value ~= expected[name] then
            fail(('%s %s is %s, expected %s'):format(conf_name, name, value, expected[name]))
          end
        end
      end
      for name in pairs(expected) do
        if not seen[name] then
          fail(('%s is missing %s'):format(conf_name, name))
        end
      end
    end
  end
end
if failures == conf_failures then
  print('  shipped kitty confs match the exported slots')
end

-- Also compare the snapshot byte for byte with a fresh canonical export.
local expected_kitty = { order = themes.keys(), themes = {} }
for _, key in ipairs(themes.keys()) do
  local meta = themes.get(key)
  local entry = {
    name = meta.name,
    tagline = meta.tagline,
    legacy = meta.legacy == true,
    faces = { dark = {}, light = {} },
  }
  for _, face in ipairs({ 'dark', 'light' }) do
    for _, variant in ipairs(variants) do
      if face == 'light' or not variant.light_only then
        entry.faces[face][variant.name] = kitty_face(key, face, variant.options)
      end
    end
  end
  expected_kitty.themes[key] = entry
end
local kitty_text = read_file(root .. '/kitty/palettes.json')
if kitty_text ~= json.encode(expected_kitty) .. '\n' then
  fail('kitty/palettes.json differs from the canonical export byte for byte')
end

-- ---------------------------------------------------------------------------
-- Zed
-- ---------------------------------------------------------------------------

print('zed')
local zed_failures = failures
local zed = require('hearthglass.zed')
for _, key in ipairs(themes.keys()) do
  local path = root .. '/zed/' .. key .. '.json'
  local actual = read_file(path)
  if not actual then
    fail('missing zed/' .. key .. '.json')
  else
    local expected = zed.json(nil, key)
    if actual ~= expected then
      fail('zed/' .. key .. '.json differs from the generator')
    end
  end
end
if failures == zed_failures then
  print('  zed/*.json matches the generator byte for byte')
end

-- ---------------------------------------------------------------------------
-- KDE
-- ---------------------------------------------------------------------------

print('kde')
local kde_failures = failures
local kde = decode_json(root .. '/kde/palettes.json')
if kde then
  local expected_keys = {}
  for _, key in ipairs(themes.keys()) do
    expected_keys[key] = true
    local entry = kde[key]
    if not entry then
      fail('kde/palettes.json is missing ' .. key)
    else
      local meta = themes.get(key)
      if entry.name ~= meta.name or entry.tagline ~= meta.tagline then
        fail('kde palette metadata differs for ' .. key)
      end
      deep_equal(entry.dark, colors.get_colors(key), 'kde.' .. key .. '.dark')
      deep_equal(entry.light, colors.get_colors(key .. '-light'), 'kde.' .. key .. '.light')
    end
  end
  for key in pairs(kde) do
    if not expected_keys[key] then
      fail('kde/palettes.json has a stale theme: ' .. key)
    end
  end
  if failures == kde_failures then
    print('  kde/palettes.json matches themes.lua')
  end
end

local expected_kde = {}
for _, key in ipairs(themes.keys()) do
  local meta = themes.get(key)
  expected_kde[key] = {
    name = meta.name,
    tagline = meta.tagline,
    dark = colors.get_colors(key),
    light = colors.get_colors(key .. '-light'),
  }
end
local kde_text = read_file(root .. '/kde/palettes.json')
if kde_text ~= json.encode(expected_kde) .. '\n' then
  fail('kde/palettes.json differs from the canonical export byte for byte')
end

local spec_failures = failures
local theme_spec = decode_json(root .. '/kde/themes.json')
if theme_spec then
  local seen = {}
  for _, entry in ipairs(theme_spec.themes) do
    seen[entry.key] = entry
  end
  for _, key in ipairs(themes.keys()) do
    local entry = seen[key]
    local meta = themes.get(key)
    if not entry then
      fail('kde/themes.json is missing ' .. key)
    elseif entry.name ~= meta.name or entry.tagline ~= meta.tagline then
      fail('kde/themes.json metadata differs for ' .. key)
    end
  end
  for key in pairs(seen) do
    if not themes.themes[key] then
      fail('kde/themes.json has a stale theme: ' .. key)
    end
  end
  if #theme_spec.themes ~= #themes.keys() then
    fail('kde/themes.json theme count differs from themes.lua')
  end
  if failures == spec_failures then
    print('  kde/themes.json covers the same family')
  end
end

print(('drift check: %d failure(s)'):format(failures))
if failures > 0 then
  vim.cmd('cquit 1')
end
print('drift check passed')
