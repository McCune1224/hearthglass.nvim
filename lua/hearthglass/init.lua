-- ============================================================================
-- hearthglass/init.lua
-- Loader for the hearthglass colorscheme family.
--
--   :colorscheme hearthglass             -> original, dark
--   :colorscheme hearthglass-light       -> original, light
--   :colorscheme hearthglass-auto        -> original, follows the desktop
--   :colorscheme seaglass                -> Seaglass, dark
--   :colorscheme seaglass-light          -> Seaglass, light
--   :colorscheme flambe                  -> Flambe, dark
--   :HearthglassTheme cranberry          -> switch theme, keep the current face
--   :HearthglassTheme                    -> list the family
--   :HearthglassToggle                   -> flip dark <-> light, keep the theme
--   :HearthglassSync                     -> re-read the desktop preference
--
-- API mirrors deepwhite.nvim: setup(opts) + load().
-- ============================================================================

local config = require('hearthglass.config')
local themes = require('hearthglass.themes')

local M = {}

-- Read a desktop color-scheme preference without making the colorscheme
-- depend on a desktop-specific Lua plugin. KDE is checked first because it
-- exposes its preference directly through kdeglobals; GNOME-compatible
-- desktops are handled through gsettings.
local function system_background()
  if vim.fn.executable('kreadconfig6') == 1 then
    local result = vim.fn.systemlist {
      'kreadconfig6',
      '--file',
      'kdeglobals',
      '--group',
      'General',
      '--key',
      'ColorScheme',
    }
    local scheme = table.concat(result, ' '):lower()
    if scheme:find('light', 1, true) then
      return 'light'
    end
    if scheme:find('dark', 1, true) then
      return 'dark'
    end
  end

  if vim.fn.executable('gsettings') == 1 then
    local result = vim.fn.systemlist {
      'gsettings',
      'get',
      'org.gnome.desktop.interface',
      'color-scheme',
    }
    local scheme = table.concat(result, ' '):lower()
    if scheme:find('prefer%-light') or scheme:find('light', 1, true) then
      return 'light'
    end
    if scheme:find('prefer%-dark') or scheme:find('dark', 1, true) then
      return 'dark'
    end
  end

  return vim.o.background == 'light' and 'light' or 'dark'
end

M.system_background = system_background

--- The theme currently in use, based on g:colors_name.
---@return string key, string face
local function active()
  local name = vim.g.colors_name
  if type(name) == 'string' and name ~= '' then
    local base = name:gsub('%-light$', '')
    if themes.themes[base] then
      return base, name:match('%-light$') and 'light' or 'dark'
    end
  end
  return 'hearthglass', vim.o.background == 'light' and 'light' or 'dark'
end

-- Map a variant name to its concrete form. Unknown names fall back to dark.
local function resolve(variant)
  local key, face = themes.split(variant)
  if face == 'auto' then
    face = system_background()
  end
  return themes.variant(key, face), key, face
end

function M.setup(opts)
  config.setup(opts)
end

--- Load the colorscheme for a variant.
---@param variant string  any theme key, optionally suffixed with '-light',
---                      plus 'hearthglass-auto'
function M.load(variant)
  variant = resolve(variant)

  vim.cmd 'hi clear'
  vim.g.colors_name = variant
  vim.o.background = variant:match('%-light$') and 'light' or 'dark'
  vim.o.termguicolors = true

  local colors = require('hearthglass.colors').get_colors(variant, config.options)
  local groups = require('hearthglass.scheme').get_groups(colors)

  for name, val in pairs(groups) do
    vim.api.nvim_set_hl(0, name, val)
  end

  -- Toggle command (recreated on every load; force keeps it idempotent)
  vim.api.nvim_create_user_command('HearthglassToggle', function()
    M.toggle()
  end, { force = true, desc = 'Toggle hearthglass dark/light' })

  vim.api.nvim_create_user_command('HearthglassSync', function()
    M.sync_system()
  end, { force = true, desc = 'Sync hearthglass with the system theme' })

  vim.api.nvim_create_user_command('HearthglassTheme', function(opts)
    if opts.args == '' then
      M.list()
      return
    end
    M.set_theme(opts.args)
  end, {
    force = true,
    nargs = '?',
    desc = 'List or switch hearthglass themes',
    complete = function()
      return themes.keys()
    end,
  })
end

--- Switch to another theme in the family, keeping the current face.
---@param key string
function M.set_theme(key)
  key = vim.trim(key or '')
  if not themes.themes[key] then
    vim.notify(('hearthglass: unknown theme %q (try :HearthglassTheme)'):format(key), vim.log.levels.WARN)
    return
  end
  local _, face = active()
  vim.cmd.colorscheme(themes.variant(key, face))
end

--- Print the family to the message area.
function M.list()
  local lines = { 'hearthglass themes (:HearthglassTheme <name>):' }
  local active_key = active()
  for _, item in ipairs(require('hearthglass.colors').list()) do
    local marker = item.key == active_key and ' *' or ''
    table.insert(lines, ('  %-22s %s%s'):format(item.key, item.name, marker))
  end
  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'None' } }, true, {})
end

--- Toggle between the dark and light faces of the current theme.
--- When another colorscheme is active, only flips vim.o.background.
function M.toggle()
  -- Changing 'background' can clear colors_name through an OptionSet
  -- autocmd or another colorscheme integration, so capture ownership first.
  local name = vim.g.colors_name
  local base = name and name:gsub('%-light$', '')
  local is_hearthglass = base ~= nil and themes.themes[base] ~= nil
  local key, face = active()
  vim.o.background = face == 'dark' and 'light' or 'dark'
  if is_hearthglass then
    -- Use :colorscheme rather than calling M.load directly so lualine and
    -- other ColorScheme listeners refresh along with the highlights.
    vim.cmd.colorscheme(themes.variant(key, vim.o.background))
  end
end

--- Re-read the desktop theme preference and apply the current theme's face.
function M.sync_system()
  local key = active()
  vim.cmd.colorscheme(themes.variant(key, system_background()))
end

return M
