-- ============================================================================
-- kitty/export.lua
--
-- Exports every kitty color slot for every palette in lua/hearthglass/themes.lua,
-- already expanded by lua/hearthglass/colors.lua. The Python CLI reads this
-- file and never keeps a second copy of the palette: the compact tables and
-- the ramp derivation live in exactly one place.
--
-- Run it with Neovim, from the root of the repository:
--
--   nvim --headless -l kitty/export.lua
--
-- Writes kitty/palettes.json. `kitty/hearthglass.py` consumes that file.
-- ============================================================================

local script = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(script, ':p:h:h')

vim.opt.runtimepath:prepend(root)
package.path = root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path

local themes = require('hearthglass.themes')
local colors = require('hearthglass.colors')

local json = require('hearthglass.json')

local function brighten(hex, amount)
  return colors.blend(hex, '#ffffff', amount)
end

-- The kitty-specific bright/dim slots the conf writer expects. Everything
-- else comes straight out of `colors.get_colors`.
local function kitty_face(key, face, options)
  local c = colors.get_colors(themes.variant(key, face), options)
  local dark = face == 'dark'

  for _, name in ipairs({ 'red', 'green', 'yellow', 'blue', 'purple', 'cyan' }) do
    c['bright_' .. name] = brighten(c[name], 0.22)
  end
  local light_end = dark and c.base0 or c.base7
  c.bright_base0 = brighten(light_end, dark and 0.2 or 0.3)
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

local out = { order = themes.keys(), themes = {} }

for _, key in ipairs(themes.keys()) do
  local theme = themes.get(key)
  local entry = {
    name = theme.name,
    tagline = theme.tagline,
    legacy = theme.legacy == true,
    faces = { dark = {}, light = {} },
  }
  for _, face in ipairs({ 'dark', 'light' }) do
    for _, variant in ipairs(variants) do
      if face == 'light' or not variant.light_only then
        entry.faces[face][variant.name] = kitty_face(key, face, variant.options)
      end
    end
  end
  out.themes[key] = entry
end

local handle = assert(io.open(root .. '/kitty/palettes.json', 'w'))
handle:write(json.encode(out) .. '\n')
handle:close()

print('wrote kitty/palettes.json')
