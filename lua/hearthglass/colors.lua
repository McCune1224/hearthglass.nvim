-- ============================================================================
-- hearthglass/colors.lua
--
-- This is intentionally shaped like deepwhite.nvim's colors.lua:
-- base0..base7, light_* syntax backgrounds, and the eight accent names.
-- The scheme file consumes these names unchanged. Only the palette values are
-- different, using Ember's dark and light palettes.
-- ============================================================================

local M = {}

-- Ember accents, retaining deepwhite's semantic names.
local accents = {
  dark = {
    orange = '#c09058',
    yellow = '#c8b468',
    cyan = '#80a090',
    green = '#8a9868',
    blue = '#7890a0',
    purple = '#988090',
    pink = '#b07878',
    red = '#e08060',
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
    base0 = '#d8d0c0', -- ember fg
    base1 = '#b8b0a0', -- ember base8
    base2 = '#b0a898', -- ember fg_alt
    base3 = '#908a7e', -- ember base7
    base4 = '#706c61', -- ember base6
    base5 = '#585550', -- ember base5
    base6 = '#2e2d2a', -- ember base3
    base7 = '#1c1b19', -- ember bg
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

-- Deepwhite uses pastel light_* blocks for syntax categories. On a dark
-- graphite background, blending Ember's warm accents directly produces muddy
-- brown slabs. Use quiet, cool Ember-adjacent graphite surfaces instead:
-- coral remains the one vivid spark, while steel/sage carry cool structure.
local dark_tints = {
  light_orange = '#34302b', -- warm graphite, not orange-brown
  light_yellow = '#35342b', -- muted gold/olive graphite
  light_cyan = '#293332', -- sage/steel graphite
  light_green = '#2e352c', -- olive graphite
  light_blue = '#2b3238', -- steel graphite
  light_purple = '#332d36', -- mauve graphite
  light_pink = '#382d32', -- rose graphite
  light_red = '#3b2d2b', -- restrained coral graphite
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
      palette[light_name] = dark_tints[light_name]
    else
      palette[light_name] = blend(color_accents[accent_name], palette.base7, light_tint_strength)
    end
  end

  return palette
end

return M