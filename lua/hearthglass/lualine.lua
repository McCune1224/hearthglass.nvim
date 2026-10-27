-- ============================================================================
-- hearthglass/lualine.lua
--
-- Builds the lualine theme for any palette in the family. The lualine theme
-- files under lua/lualine/themes/ are one-line shims that call this module,
-- so every theme (and its -light face) automatically follows the palette and
-- the colorblind/low-blue-light options.
--
-- The active section is the deepwhite signature inverted block: bg-colored
-- text on an fg-colored background.
-- ============================================================================

local M = {}

---@param variant string  any theme key, optionally suffixed with '-light'
---@return table
function M.get(variant)
  local options = require('hearthglass.config').options
  local colors = require('hearthglass.colors').get_colors(variant, options)

  local inactive = {
    a = { fg = colors.base7, bg = colors.base0, gui = 'bold' },
    b = { fg = colors.base0, bg = colors.base7 },
    c = { fg = colors.base0, bg = colors.base7 },
  }

  return {
    visual = inactive,
    replace = inactive,
    inactive = inactive,
    normal = inactive,
    insert = inactive,
  }
end

return M
