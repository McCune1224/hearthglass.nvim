-- ============================================================================
-- hearthglass/colors.lua
--
-- This is intentionally shaped like deepwhite.nvim's colors.lua:
-- base0..base7, light_* syntax backgrounds, and the eight accent names.
-- The scheme file consumes these names unchanged. Only the palette values are
-- different: the dark variant re-tunes Ember's dark graphite toward a
-- gruvboxy warmth (earthy brown backgrounds, muted yellow, orange as the
-- hero accent), while the light variant is orange-forward on parchment.
--
-- Readability tuning on top of the deepwhite contract:
--   * dark ramp slots base3/base5/base6 are lifted so comments, visual
--     selection, and the cursorline are clearly visible against the warm
--     background;
--   * the dark light_* syntax slabs are raised from near-invisible umber to
--     clearly readable warm blocks;
--   * dark syntax text (String/Constant/Statement) is nudged toward its
--     slab's hue so categories read at a glance instead of all being one
--     warm ivory;
--   * colorblind-safe remaps replace the red/green meaning pair when
--     options.colorblind is set (see apply_colorblind below).
-- ============================================================================

local M = {}

-- Accent colors, retaining deepwhite's semantic names. The dark variant leans
-- into gruvboxy warmth: earthy brown backgrounds, orange as the hero accent
-- for UI highlights (cursor, search, warnings), and a clean gold for types
-- and constants. Rose carries keyword syntax, giving it a cooler tone that
-- separates keywords from the orange UI signals. Green and red remain vivid
-- as context signals (diffs, diagnostics, errors/success). The quiet
-- supporting accents (cyan/blue/purple/pink) stay desaturated.
--
-- The light variant is orange-forward: its orange is deepened to a burnt
-- orange that clears the parchment, and gold is kept warm so types and
-- constants read clearly on parchment.
local accents = {
  dark = {
    orange = '#d77c3a',
    yellow = '#d4a840',
    cyan = '#6b9480',
    green = '#8a9a50',
    blue = '#7894a8',
    purple = '#a0889a',
    pink = '#c48870',
    rose = '#c08088',
    red = '#d85848',
  },
  light = {
    orange = '#8a4820',
    yellow = '#907830',
    cyan = '#356050',
    green = '#486230',
    blue = '#385a78',
    purple = '#685868',
    pink = '#884848',
    rose = '#906068',
    red = '#b04830',
  },
}

-- The ramp order follows deepwhite exactly: base0 is the main foreground,
-- base7 is the main background. The dark variant reverses Ember's visual
-- ramp; the light variant uses it in the same direction as deepwhite.
local palettes = {
  dark = {
    base0 = '#e0cc98', -- warm ivory foreground
    base1 = '#c4b088', -- warm sand
    base2 = '#a89878', -- warm camel
    base3 = '#8a7a68', -- warm taupe (comments, line numbers)
    base4 = '#605240', -- warm umber
    base5 = '#4a3e30', -- warm charcoal (visual selection)
    base6 = '#342c24', -- deep warm umber (cursorline)
    base7 = '#1e1814', -- warm dark background
  },
  light = {
    base0 = '#2a2218', -- warm dark foreground
    base1 = '#4a4230', -- warm dark alt
    base2 = '#5a5240', -- warm mid-dark
    base3 = '#625a4a', -- warm mid
    base4 = '#7a7262', -- warm light-mid
    base5 = '#989080', -- warm light
    base6 = '#e8e0d4', -- warm parchment alt
    base7 = '#f2eae0', -- warm parchment background
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
  light_orange = '#4a3528', -- burnt umber
  light_yellow = '#4a3e20', -- gold umber
  light_cyan = '#344438', -- sage umber
  light_green = '#3a4228', -- olive umber
  light_blue = '#364858', -- steel umber
  light_purple = '#443844', -- mauve umber
  light_pink = '#4a3428', -- terracotta umber
  light_rose = '#443038', -- rose umber
  light_red = '#503028', -- brick umber
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
  light_rose = 'rose',
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
    palette.syntax_statement = blend(palette.base0, palette.rose, 0.45)
  else
    palette.syntax_string = palette.base0
    palette.syntax_constant = palette.base0
    palette.syntax_statement = palette.base0
  end

  -- Type follows the gold-on-dark / orange-on-light philosophy: gold reads
  -- as the type hue against the umber background, while on parchment gold
  -- washes out and orange carries the emphasis instead.
  if kind == 'dark' then
    palette.syntax_type = palette.yellow
  else
    palette.syntax_type = palette.orange
  end

  return palette
end

return M