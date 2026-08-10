-- ============================================================================
-- hearthglass/init.lua
-- Loader for the hearthglass colorscheme.
--
--   :colorscheme hearthglass        -> dark variant (ember dark palette)
--   :colorscheme hearthglass-light  -> light variant (ember light palette)
--   :colorscheme hearthglass-auto   -> resolves from vim.o.background
--   :HearthglassToggle              -> toggle dark <-> light
--
-- API mirrors deepwhite.nvim: setup(opts) + load().
-- ============================================================================

local config = require('hearthglass.config')

local M = {}

-- Map a variant name to its concrete form. Unknown names fall back to dark.
local function resolve(variant)
  if variant == 'hearthglass-light' then
    return 'hearthglass-light'
  end
  if variant == 'hearthglass-auto' then
    return vim.o.background == 'light' and 'hearthglass-light' or 'hearthglass'
  end
  return 'hearthglass'
end

function M.setup(opts)
  config.setup(opts)
end

--- Load the colorscheme for a variant.
---@param variant string  'hearthglass' | 'hearthglass-light' | 'hearthglass-auto'
function M.load(variant)
  variant = resolve(variant)

  vim.cmd 'hi clear'
  vim.g.colors_name = variant
  vim.o.background = variant == 'hearthglass-light' and 'light' or 'dark'
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
end

--- Toggle between the dark and light variants.
--- When another colorscheme is active, only flips vim.o.background.
function M.toggle()
  -- Changing 'background' can clear colors_name through an OptionSet
  -- autocmd or another colorscheme integration, so capture ownership first.
  local is_hearthglass = vim.g.colors_name and vim.g.colors_name:match('^hearthglass')
  vim.o.background = vim.o.background == 'dark' and 'light' or 'dark'
  if is_hearthglass then
    -- Use :colorscheme rather than calling M.load directly so lualine and
    -- other ColorScheme listeners refresh along with the highlights.
    vim.cmd.colorscheme(vim.o.background == 'dark' and 'hearthglass' or 'hearthglass-light')
  end
end

return M
