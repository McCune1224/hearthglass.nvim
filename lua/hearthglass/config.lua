-- ============================================================================
-- hearthglass/config.lua
-- Configuration for the hearthglass colorscheme.
--
-- hearthglass is a clone of deepwhite.nvim (Verf/deepwhite.nvim) recolored
-- with the ember palette (ember-theme/nvim). It ships a family of themes, each
-- with a dark and a light face:
--   hearthglass, stained, sanguine, vinifera, daisy, smoked, frosted, cathedral, leaded
-- See lua/hearthglass/themes.lua for the palette definitions.
-- ============================================================================

local M = {}

M.options = {
  -- Light variant only: lift the parchment background toward white for a
  -- brighter "paper" feel. No effect on the dark variant.
  low_blue_light = false,

  -- Colorblind-safe accent remap. Accepts false (default), true (alias for
  -- 'deutan'), 'deutan', 'protan', or 'tritan'. Applies to both variants.
  --   deutan/protan: red/green meaning pair -> rose/teal
  --   tritan:        blue -> purple-leaning, cyan -> steel
  colorblind = false,
}

function M.setup(options)
  M.options = vim.tbl_deep_extend('force', M.options, options or {})
end

return M
