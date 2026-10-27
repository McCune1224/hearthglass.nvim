-- ============================================================================
-- zed/build.lua
--
-- Generates the Zed Editor theme families from the hearthglass palette.
--
-- Run it with Neovim, from the root of the repository:
--
--   nvim --headless -l zed/build.lua                  # write every zed/*.json
--   nvim --headless -l zed/build.lua --theme frostedglass  # one family
--   nvim --headless -l zed/build.lua /tmp/out.json    # one family, elsewhere
--   nvim --headless -l zed/build.lua --install        # also copy into ~/.config/zed/themes
--
-- The same two options as the colorscheme and the kitty theme are honored:
--
--   --low-blue-light        light variant only: lift the parchment toward white
--   --colorblind MODE       deutan | protan | tritan | true
--
-- The palette is read from lua/hearthglass/themes.lua, so this script and the
-- Neovim colorscheme can never drift apart.
-- ============================================================================

local script = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(script, ':p:h:h')

vim.opt.runtimepath:prepend(root)
package.path = root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path

local themes = require('hearthglass.themes')

local options = { low_blue_light = false, colorblind = false }
local output = nil
local install = false
local only = nil

local args = _G.arg or {}
local i = 1
while i <= #args do
  local arg = args[i]
  if arg == '--low-blue-light' then
    options.low_blue_light = true
  elseif arg == '--colorblind' then
    options.colorblind = true
    if args[i + 1] and not args[i + 1]:match('^%-') then
      options.colorblind = args[i + 1]
      i = i + 1
    end
  elseif arg == '--theme' then
    only = args[i + 1]
    i = i + 1
  elseif arg == '--install' then
    install = true
  elseif not arg:match('^%-') and not output then
    output = arg
  end
  i = i + 1
end

if only and not themes.themes[only] then
  error(('unknown theme: %s'):format(only))
end

local function write(file, contents)
  local handle = assert(io.open(file, 'w'))
  handle:write(contents)
  handle:close()
end

local function build(key, path)
  local json = require('hearthglass.zed').json(options, key)
  write(path, json)
  print('wrote ' .. path)
  return json
end

if output then
  build(only or 'hearthglass', output)
else
  local keys = only and { only } or themes.order
  for _, key in ipairs(keys) do
    build(key, root .. '/zed/' .. key .. '.json')
  end
end

if install then
  local themes_dir = vim.fn.expand('~/.config/zed/themes')
  vim.fn.mkdir(themes_dir, 'p')
  local keys = only and { only } or themes.order
  for _, key in ipairs(keys) do
    local json = require('hearthglass.zed').json(options, key)
    write(themes_dir .. '/' .. key .. '.json', json)
    print('installed ' .. themes_dir .. '/' .. key .. '.json')
  end
  print('pick a Hearthglass family in the Zed theme picker')
end
