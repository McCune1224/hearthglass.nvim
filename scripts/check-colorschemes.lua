-- ============================================================================
-- scripts/check-colorschemes.lua
--
-- Loads every colorscheme face under headless Neovim, with the default and
-- option combinations the plugin exposes, and verifies that the groups the
-- scheme defines resolve to non-nil colors.
--
--   nvim --headless -l scripts/check-colorschemes.lua
--
-- Exits 1 when a colorscheme fails to load or a required group has no color.
-- ============================================================================

local script = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(script, ':p:h:h')

vim.opt.runtimepath:prepend(root)
package.path = root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path

local themes = require('hearthglass.themes')
local config = require('hearthglass.config')

-- Groups that must carry a foreground or background on every face. Links are
-- resolved by nvim_get_hl(..., {link = false}).
local required = {
  'Normal', 'NormalFloat', 'Comment', 'Constant', 'String', 'Statement',
  'PreProc', 'Type', 'Function', 'Identifier', 'Special', 'Title',
  'Cursor', 'CursorLine', 'CursorLineNr', 'Visual', 'Search', 'IncSearch',
  'Pmenu', 'PmenuSel', 'StatusLine', 'StatusLineNC', 'LineNr', 'SignColumn',
  'DiffAdd', 'DiffChange', 'DiffDelete', 'DiagnosticError', 'DiagnosticWarn',
  'DiagnosticInfo', 'DiagnosticHint', 'DiagnosticOk', 'ErrorMsg', 'WarningMsg',
}

local options = {
  { label = 'plain', colorblind = false, low_blue_light = false },
  { label = 'deutan', colorblind = 'deutan', low_blue_light = false },
  { label = 'tritan', colorblind = 'tritan', low_blue_light = false },
  { label = 'low-blue', colorblind = false, low_blue_light = true },
}

local failures = 0
local loads = 0

local function fail(message)
  failures = failures + 1
  print('FAIL ' .. message)
end

for _, key in ipairs(themes.keys()) do
  for _, face in ipairs({ 'dark', 'light' }) do
    local variant = themes.variant(key, face)
    for _, option in ipairs(options) do
      config.options.colorblind = option.colorblind
      config.options.low_blue_light = option.low_blue_light

      local ok, err = pcall(vim.cmd.colorscheme, variant)
      if not ok then
        fail(('%s %s: %s'):format(variant, option.label, err))
      else
        loads = loads + 1
        if vim.g.colors_name ~= variant then
          fail(('%s %s: colors_name is %s'):format(variant, option.label, tostring(vim.g.colors_name)))
        end
        for _, group in ipairs(required) do
          local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
          if hl.fg == nil and hl.bg == nil and hl.sp == nil then
            fail(('%s %s: %s has no resolved color'):format(variant, option.label, group))
          end
        end
      end
    end
  end
end

-- The auto colorscheme resolves to one of the original faces at load time.
for _, option in ipairs(options) do
  config.options.colorblind = option.colorblind
  config.options.low_blue_light = option.low_blue_light
  local ok, err = pcall(vim.cmd.colorscheme, 'hearthglass-auto')
  if not ok then
    fail(('hearthglass-auto %s: %s'):format(option.label, err))
  else
    loads = loads + 1
    local resolved = tostring(vim.g.colors_name)
    if resolved ~= 'hearthglass' and resolved ~= 'hearthglass-light' then
      fail(('hearthglass-auto %s resolved to %s'):format(option.label, resolved))
    end
    for _, group in ipairs(required) do
      local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
      if hl.fg == nil and hl.bg == nil and hl.sp == nil then
        fail(('hearthglass-auto %s: %s has no resolved color'):format(option.label, group))
      end
    end
  end
end

config.options.colorblind = false
config.options.low_blue_light = false

print(('%d colorscheme loads checked, %d failure(s)'):format(loads, failures))
if failures > 0 then
  vim.cmd('cquit 1')
end
print('colorscheme load check passed')
