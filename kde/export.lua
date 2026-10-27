-- ============================================================================
-- kde/export.lua
--
-- Exports every palette the KDE themes are built from, straight from
-- lua/hearthglass/themes.lua (via hearthglass.colors), so the desktop themes
-- cannot drift from the editor family.
--
-- Run it with Neovim, from the root of the repository:
--
--   nvim --headless -l kde/export.lua
--
-- Writes kde/palettes.json. `kde/build.py` consumes that file.
-- ============================================================================

local script = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(script, ':p:h:h')

vim.opt.runtimepath:prepend(root)
package.path = root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path

local themes = require('hearthglass.themes')
local colors = require('hearthglass.colors')
local json = require('hearthglass.json')

local out = {}

for _, key in ipairs(themes.keys()) do
  local theme = themes.get(key)
  out[key] = {
    name = theme.name,
    tagline = theme.tagline,
    dark = colors.get_colors(key),
    light = colors.get_colors(key .. '-light'),
  }
end

local handle = assert(io.open(root .. '/kde/palettes.json', 'w'))
handle:write(json.encode(out) .. '\n')
handle:close()

print('wrote kde/palettes.json')
