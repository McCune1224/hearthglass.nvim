-- ============================================================================
-- hearthglass/colors.lua
--
-- Expands a compact theme palette into the deepwhite contract the scheme file
-- consumes: base0..base7, the light_* syntax slabs, and the named accents.
--
-- The original `hearthglass` palette keeps a hand-tuned values under `legacy`:
-- the dark face leans into gruvboxy warmth with earthy brown backgrounds,
-- muted gold, orange as the UI hero and rose for keyword syntax. Every other
-- palette in `themes.lua` is derived from its nine defining colors:
--
--   * the ramp keeps the same lightness steps as the original, so comments,
--     selections and the cursorline sit where deepwhite expects them;
--   * the hero accent (crimson) becomes `orange` for cursor, search, warnings
--     and the mode block;
--   * a second accent becomes `rose` for keyword syntax, keeping it distinct
--     from the orange UI signals;
--   * terracotta becomes `pink` (preprocessor), so the secondary accent stays
--     in play next to the hero instead of collapsing into one hue;
--   * cyan and purple are mixed from the compact palette rather than invented,
--     so supporting accents stay inside the theme's temperature.
--
-- Readability tuning still applies: dark syntax text is nudged toward its
-- slab's hue, light syntax text keeps the ink-dark foreground, and the
-- colorblind remaps replace the red/green meaning pair on every theme.
-- ============================================================================

local themes = require('hearthglass.themes')

local M = {}

-- Legacy accents, retaining deepwhite's semantic names. Orange carries the
-- UI hero role while rose carries keyword syntax so the two do not collapse
-- into one signal. Green and red remain vivid as context colors. The quiet
-- supporting accents (cyan/blue/purple/pink) stay desaturated.
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
    yellow = '#7a6420',
    cyan = '#356050',
    green = '#486230',
    blue = '#385a78',
    purple = '#685868',
    pink = '#884848',
    rose = '#8a5a62',
    red = '#b04830',
  },
}

local palettes = {
  dark = {
    base0 = '#e0cc98', -- warm ivory foreground
    base1 = '#c4b088', -- warm sand
    base2 = '#a89878', -- warm camel
    base3 = '#94836f', -- warm taupe (comments, line numbers)
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

-- Deepwhite uses pastel light_* blocks for syntax categories. On the warm
-- background these are low-lightness umber slabs so the blocks read as warm
-- texture: each slab is a desaturated tint of its accent hue, lifted well
-- above the background so the block itself is visible, and clearly darker
-- than the tinted foreground sitting on top of it.
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
local dark_tint_strength = 0.26

-- Blend two #rrggbb colors. amount=1.0 returns c1; amount=0.0 returns c2.
-- Exported so the Zed, KDE and kitty generators can derive extra shades from
-- the same palette instead of hard-coding a second set of hex values.
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

M.blend = blend

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

-- Expand a compact palette (see hearthglass/themes.lua) into the deepwhite
-- ramp and accent names. Tints are generated later because colorblind remaps
-- change the accent they are derived from.
local function expand(compact, kind)
  local fg = compact.fg
  local bg = compact.bg
  local comment = compact.comment

  -- The light ramp climbs toward the background; dark descends from the
  -- foreground. The selection steps are closer to the background on dark so
  -- they read as a lift, and further on light so they read as a wash.
  local palette = {
    base0 = fg,
    base1 = blend(comment, fg, 0.57),
    base2 = blend(comment, fg, 0.82),
    base3 = comment,
    base4 = blend(comment, bg, kind == 'dark' and 0.65 or 0.80),
    base5 = blend(comment, bg, kind == 'dark' and 0.47 or 0.58),
    base6 = compact.bg2,
    base7 = bg,
  }

  local color_accents = {
    -- The crimson hero doubles as `red` so errors, deletions and the cursor
    -- all come from the same wound; the theme never introduces a second red.
    orange = compact.crimson,
    red = compact.crimson,
    yellow = compact.gold,
    green = compact.green,
    blue = compact.blue,
    cyan = blend(compact.blue, compact.green, 0.5),
    purple = blend(compact.crimson, compact.blue, 0.55),
    pink = compact.terracotta,
    -- Keyword syntax gets a cooler, dustier cousin of the hero and secondary
    -- so it reads apart from the orange UI signals without leaving the theme.
    rose = blend(blend(compact.crimson, compact.terracotta, 0.55), compact.comment, 0.82),
  }

  return palette, color_accents
end

---@param variant string  'hearthglass', 'daisy', 'daisy-light', ...
---@param options table|nil
---@return table
function M.get_colors(variant, options)
  options = options or {}

  local key, face = themes.split(variant)
  local kind = (face == 'light') and 'light' or 'dark'
  local theme = themes.get(key)
  local legacy = theme.legacy == true

  local palette, color_accents, tints

  if legacy then
    palette = vim.tbl_extend('force', {}, palettes[kind])
    color_accents = vim.tbl_extend('force', {}, accents[kind])
    tints = vim.tbl_extend('force', {}, dark_tints)
  else
    palette, color_accents = expand(theme[kind], kind)
    tints = nil
  end

  -- Colorblind-safe remaps. The red/green pair is the only accent pair the
  -- theme uses for meaning (diffs, diagnostics, success/error), so it is the
  -- one that matters. 'protan' and 'deutan' share a remap: red shifts toward
  -- rose and green toward teal, keeping both distinguishable for red-green
  -- deficiencies (the blue component survives). 'tritan' moves blue toward
  -- purple and cyan toward steel so they stop colliding with the gold family.
  local cb = options.colorblind
  if cb == true then
    cb = 'deutan'
  elseif cb == 'protan' then
    cb = 'deutan'
  end
  if cb == 'deutan' or cb == 'tritan' then
    color_accents = vim.tbl_extend('force', {}, color_accents)
    if cb == 'deutan' then
      if kind == 'dark' then
        color_accents.red = '#e07075' -- rose (blue-leaning red)
        color_accents.green = '#5f9c8b' -- teal (blue-leaning green)
        color_accents.cyan = '#7a9fb5' -- steel, so cyan stays apart from teal
        if legacy then
          tints = vim.tbl_extend('force', {}, tints)
          tints.light_green = '#33453c' -- teal umber
          tints.light_red = '#4a3038' -- rose umber
        end
      else
        color_accents.red = '#9e4353'
        color_accents.green = '#3a6659'
        color_accents.cyan = '#436075'
      end
    else -- tritan
      if kind == 'dark' then
        color_accents.blue = '#9a8fc4' -- purple-leaning blue
        color_accents.cyan = '#7a9fb5' -- steel
        if legacy then
          tints = vim.tbl_extend('force', {}, tints)
          tints.light_blue = '#3a3448' -- purple umber
        end
      else
        color_accents.blue = '#5c5690'
        color_accents.cyan = '#436075'
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
      -- Legacy keeps its hand-tuned slabs (and colorblind overrides); new
      -- themes derive slabs from the remapped accents so they always match.
      if legacy then
        palette[light_name] = tints[light_name]
      else
        palette[light_name] = blend(color_accents[accent_name], palette.base7, dark_tint_strength)
      end
    else
      palette[light_name] = blend(color_accents[accent_name], palette.base7, light_tint_strength)
    end
  end

  -- Syntax text. Dark faces nudge the ivory foreground toward the slab hue so
  -- String/Constant/Statement read at a glance. Keywords use rose rather than
  -- the orange UI hero, so syntax and UI stay separate. Light faces keep the
  -- ink-dark foreground, as deepwhite does.
  if kind == 'dark' then
    palette.syntax_string = blend(palette.base0, color_accents.green, 0.5)
    palette.syntax_constant = blend(palette.base0, color_accents.yellow, 0.5)
    palette.syntax_statement = blend(palette.base0, color_accents.rose, legacy and 0.45 or 0.55)
  elseif legacy then
    palette.syntax_string = palette.base0
    palette.syntax_constant = palette.base0
    palette.syntax_statement = palette.base0
  else
    palette.syntax_string = blend(palette.base0, color_accents.green, 0.5)
    palette.syntax_constant = blend(palette.base0, color_accents.yellow, 0.4)
    palette.syntax_statement = palette.base0
  end

  -- Type follows the gold-on-dark / orange-on-light philosophy: gold reads as
  -- the type hue against the umber background, while on parchment the burnt
  -- orange carries the emphasis instead.
  if kind == 'dark' then
    palette.syntax_type = color_accents.yellow
  else
    palette.syntax_type = color_accents.orange
  end

  return palette
end

--- Metadata for every theme in the family (name, tagline, key).
---@return table[]
function M.list()
  local items = {}
  for _, key in ipairs(themes.keys()) do
    local theme = themes.get(key)
    table.insert(items, {
      key = key,
      name = theme.name,
      tagline = theme.tagline,
      legacy = theme.legacy == true,
    })
  end
  return items
end

return M
