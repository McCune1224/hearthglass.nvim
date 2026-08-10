-- ============================================================================
-- hearthglass/colors.lua
--
-- This is intentionally shaped like deepwhite.nvim's colors.lua:
-- base0..base7, light_* syntax backgrounds, and the eight accent names.
-- The scheme file consumes these names unchanged. Only the palette values are
-- different: the light variant uses Ember's light palette verbatim, while the
-- dark variant re-tunes Ember's dark graphite toward a golden/amber identity
-- with green and red reserved as context accents.
--
-- Readability tuning on top of the deepwhite contract:
--   * dark ramp slots base3/base5/base6 are lifted so comments, visual
--     selection, and the cursorline are clearly visible against the ash
--     background;
--   * the dark light_* syntax slabs are raised from near-invisible umber to
--     clearly readable warm blocks;
--   * dark syntax text (String/Constant/Statement) is nudged toward its
--     slab's hue so categories read at a glance instead of all being one
--     golden ivory;
--   * colorblind-safe remaps replace the red/green meaning pair when
--     options.colorblind is set (see apply_colorblind below).
-- ============================================================================

local M = {}

-- Ember accents, retaining deepwhite's semantic names. The dark variant is
-- tuned away from Ember's near-monochrome graphite toward a golden/amber
-- identity: orange is the hero, yellow the gold, while green and red are kept
-- vivid as context signals (diffs, diagnostics, errors/success). The quiet
-- supporting accents (cyan/blue/purple/pink) stay desaturated so only the
-- golden pair and the two context colors carry visual weight.
local accents = {
  dark = {
    orange = '#e0893d',
    yellow = '#e0bd58',
    cyan = '#6f9a8c',
    green = '#98a45c',
    blue = '#7d94ab',
    purple = '#a58e9c',
    pink = '#c98f74',
    red = '#dd5c4a',
  },
  light = {
    orange = '#946030',
    yellow = '#7a6820',
    cyan = '#386858',
    green = '#4a6830',
    blue = '#3a6080',
    purple = '#706070',
    pink = '#905050',
    red = '#b84c30',
  },
}

-- The ramp order follows deepwhite exactly: base0 is the main foreground,
-- base7 is the main background. The dark variant reverses Ember's visual
-- ramp; the light variant uses it in the same direction as deepwhite.
local palettes = {
  dark = {
    base0 = '#e6d3a3', -- golden ivory foreground
    base1 = '#c7b48c', -- warm sand
    base2 = '#a99874', -- camel
    base3 = '#94836a', -- taupe (comments, line numbers)
    base4 = '#6a5c46', -- umber
    base5 = '#54452f', -- warm charcoal (visual selection)
    base6 = '#3a322a', -- deep umber (cursorline)
    base7 = '#1b1612', -- hearth-ash background
  },
  light = {
    base0 = '#282418', -- ember fg
    base1 = '#484030', -- ember base8
    base2 = '#585040', -- ember fg_alt
    base3 = '#605848', -- ember base7
    base4 = '#787060', -- ember base6
    base5 = '#989080', -- ember base5
    base6 = '#ddd0b8', -- ember bg_alt
    base7 = '#e6dac4', -- ember bg
  },
}

-- Blend two #rrggbb colors. amount=1.0 returns c1; amount=0.0 returns c2.
local function blend(c1, c2, amount)
  local function channel(hex, start)
    return tonumber(hex:sub(start, start + 1), 16)
  end

  local function mix(a, b)
    return math.floor(a * amount + b * (1 - amount) + 0.5)
  end

  return string.format(
    '#%02x%02x%02x',
    mix(channel(c1, 2), channel(c2, 2)),
    mix(channel(c1, 4), channel(c2, 4)),
    mix(channel(c1, 6), channel(c2, 6))
  )
end

-- Deepwhite uses pastel light_* blocks for syntax categories. On the warm
-- umber background these are low-lightness umber slabs so the blocks read as
-- warm texture: each slab is a desaturated tint of its accent hue, lifted
-- well above the background so the block itself is visible, and clearly
-- darker than the tinted foreground sitting on top of it.
local dark_tints = {
  light_orange = '#523823', -- amber umber
  light_yellow = '#524625', -- golden umber
  light_cyan = '#36473f', -- sage umber
  light_green = '#414826', -- olive umber
  light_blue = '#384a5a', -- steel umber
  light_purple = '#4b3d4a', -- mauve umber
  light_pink = '#523a2e', -- terracotta umber
  light_red = '#573128', -- brick umber
}

local light_tint_strength = 0.18

local tint_names = {
  light_orange = 'orange',
  light_yellow = 'yellow',
  light_cyan = 'cyan',
  light_green = 'green',
  light_blue = 'blue',
  light_purple = 'purple',
  light_pink = 'pink',
  light_red = 'red',
}

---@param variant string  'hearthglass' or 'hearthglass-light'
---@param options table|nil
---@return table
function M.get_colors(variant, options)
  options = options or {}
  local kind = variant == 'hearthglass-light' and 'light' or 'dark'
  local palette = vim.tbl_extend('force', {}, palettes[kind])
  local color_accents = accents[kind]
  local tints = dark_tints

  -- Colorblind-safe remaps. The red/green pair is the only accent pair the
  -- theme uses for meaning (diffs, diagnostics, success/error), so it is the
  -- one that matters. 'protan' and 'deutan' share a remap: red shifts toward
  -- rose and green toward teal, keeping both distinguishable for red-green
  -- deficiencies (the blue component survives). 'tritan' moves blue toward
  -- violet and cyan toward steel so they stop colliding with the gold family.
  local cb = options.colorblind
  if cb == true then
    cb = 'deutan'
  elseif cb == 'protan' then
    cb = 'deutan'
  end
  if cb == 'deutan' or cb == 'tritan' then
    color_accents = vim.tbl_extend('force', {}, color_accents)
    tints = vim.tbl_extend('force', {}, tints)
    if cb == 'deutan' then
      if kind == 'dark' then
        color_accents.red = '#d96a6f' -- rose (blue-leaning red)
        color_accents.green = '#5f9c8b' -- teal (blue-leaning green)
        color_accents.cyan = '#5f8098' -- steel, so cyan stays apart from teal
        tints.light_green = '#33453c' -- teal umber
        tints.light_red = '#4a3038' -- rose umber
      else
        color_accents.red = '#a84a5a'
        color_accents.green = '#3f6e60'
        color_accents.cyan = '#4a6a80'
      end
    else -- tritan
      if kind == 'dark' then
        color_accents.blue = '#8579ae' -- violet-leaning blue
        color_accents.cyan = '#5f8098' -- steel
        tints.light_blue = '#3a3448' -- violet umber
      else
        color_accents.blue = '#5c5690'
        color_accents.cyan = '#4a6a80'
      end
    end
  end

  for name, color in pairs(color_accents) do
    palette[name] = color
  end

  -- These two names are consumed by the DAP highlight groups in the cloned
  -- deepwhite scheme.
  palette.iris = color_accents.purple
  palette.muted = palette.base3

  if options.low_blue_light and kind == 'light' then
    palette.base7 = blend('#ffffff', palette.base7, 0.35)
  end

  for light_name, accent_name in pairs(tint_names) do
    if kind == 'dark' then
      palette[light_name] = tints[light_name]
    else
      palette[light_name] = blend(color_accents[accent_name], palette.base7, light_tint_strength)
    end
  end

  -- Dark-only readability tints for the deepwhite syntax blocks: the text
  -- keeps its warm ivory family but is nudged toward the slab's hue so
  -- String/Constant/Statement read at a glance instead of all being base0.
  -- Derived from the (possibly remapped) accents, so colorblind modes flow
  -- through automatically. Light keeps the faithful deepwhite base0 text.
  if kind == 'dark' then
    palette.syntax_string = blend(palette.base0, palette.green, 0.5)
    palette.syntax_constant = blend(palette.base0, palette.yellow, 0.5)
    palette.syntax_statement = blend(palette.base0, palette.orange, 0.45)
  else
    palette.syntax_string = palette.base0
    palette.syntax_constant = palette.base0
    palette.syntax_statement = palette.base0
  end

  return palette
end

return M