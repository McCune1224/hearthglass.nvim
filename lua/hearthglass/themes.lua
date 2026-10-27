-- ============================================================================
-- hearthglass/themes.lua
--
-- The theme family. Each entry is a compact palette — the nine colors that
-- define its character — plus the metadata every integration needs (Neovim,
-- kitty, Zed, KDE).
--
--   bg          main background            base7
--   bg2         cursorline / raised panel  base6
--   fg          main foreground            base0
--   comment     comments, line numbers     base3
--   crimson     hero accent (cursor, search, keywords, mode block)
--   terracotta  strings' warmth, preprocessor, secondary accent
--   gold        types, functions, numbers
--   blue        functions, links, info
--   green       diffs added, success, hints
--
-- `colors.lua` expands the compact palette into the full deepwhite contract
-- (base0..base7, light_* slabs, the eight named accents). The original
-- `hearthglass` palette keeps its historical, hand-tuned values verbatim and
-- is marked `legacy`; every other theme is derived from the compact data below
-- so every theme stays structurally identical.
--
-- The family spans amber, vermilion, wine, coral, smoked gray, polar blue-gray,
-- ink black and forest green. Every theme carries a glass name. Stained Glass,
-- Smoked Glass, Frosted Glass, Cathedral Glass and Leaded Glass add the newer
-- directions; Smoked Glass is deliberately minimal, with a single warm accent
-- and gray syntax support, while the others keep several unrelated accents in
-- play so their highlight patterns stay colorful.
--
-- Palette ancestors, matched color for color: Gruvbox (stainedglass), Nord
-- (frostedglass), Kanagawa (cathedralglass) and Everforest (leadedglass).
-- Hearthglass itself follows deepwhite's structure and Ember's direction. Only
-- `seaglass` is anchored to a photographed petal reference instead: deep teal
-- shadow #0e2426, coral petal #e08a6d, cyan rim #5fd6d2, amber pollen #d98f3a
-- and bone highlight #f3ded0. Its dark face uses those anchors directly; the
-- light face keeps each hue angle and shifts lightness only as far as WCAG
-- contrast requires.
-- ============================================================================

local M = {}

M.order = {
  'hearthglass',
  'stainedglass',
  'flameglass',
  'cranberryglass',
  'seaglass',
  'smokedglass',
  'frostedglass',
  'cathedralglass',
  'leadedglass',
}

M.themes = {
  ['hearthglass'] = {
    name = 'Hearthglass',
    tagline = 'The original: amber hero, ivory ink, hearth ash.',
    legacy = true,
  },

  ['stainedglass'] = {
    name = 'Stained Glass',
    tagline = 'Gruvbox bones, stained-glass fire. Retro warmth, hotter orange.',
    dark = {
      bg = '#282828',
      bg2 = '#3c3836',
      fg = '#ebdbb2',
      comment = '#a89984',
      crimson = '#ff9845',
      terracotta = '#ff5a44',
      gold = '#fabd2f',
      blue = '#83a598',
      green = '#b8bb26',
    },
    light = {
      bg = '#fbf1c7',
      bg2 = '#ebdbb2',
      fg = '#3c3836',
      comment = '#74675c',
      crimson = '#9b3202',
      terracotta = '#9d0006',
      gold = '#96600f',
      blue = '#076678',
      green = '#706b0c',
    },
  },

  ['flameglass'] = {
    name = 'Flame Glass',
    tagline = 'Ruby glass and vermilion fire. Hotter and redder than wine.',
    dark = {
      bg = '#170c0a',
      bg2 = '#28120f',
      fg = '#efdcd3',
      comment = '#ab837b',
      crimson = '#f04f3c',
      terracotta = '#d48554',
      gold = '#d8b066',
      blue = '#8494a8',
      green = '#95a06a',
    },
    light = {
      bg = '#f8e9e2',
      bg2 = '#edd6cc',
      fg = '#351b17',
      comment = '#82574f',
      crimson = '#a0281f',
      terracotta = '#9f5232',
      gold = '#876528',
      blue = '#405f78',
      green = '#526432',
    },
  },

  ['cranberryglass'] = {
    name = 'Cranberry Glass',
    tagline = 'Cranberry glass and plum shadow. A wine-dark rose that stays readable.',
    dark = {
      bg = '#1a0f14',
      bg2 = '#28161d',
      fg = '#ecd8d5',
      comment = '#a28386',
      crimson = '#d95a70',
      terracotta = '#c1805f',
      gold = '#cfa765',
      blue = '#8a94b0',
      green = '#8fa06a',
    },
    light = {
      bg = '#f6eae8',
      bg2 = '#ead8d6',
      fg = '#33201f',
      comment = '#7d5b5e',
      crimson = '#8e2f45',
      terracotta = '#9b5438',
      gold = '#846020',
      blue = '#4a5b86',
      green = '#506632',
    },
  },

  ['seaglass'] = {
    name = 'Sea Glass',
    tagline = 'Sea glass, coral light and a deep teal shadow.',
    dark = {
      bg = '#0e2426',
      bg2 = '#143032',
      fg = '#f3ded0',
      comment = '#93b3ac',
      crimson = '#e08a6d',
      terracotta = '#5fd6d2',
      gold = '#d98f3a',
      blue = '#7fb7c9',
      green = '#a9c08c',
    },
    light = {
      bg = '#f3ded0',
      bg2 = '#e7cdbc',
      fg = '#12302f',
      comment = '#4f6662',
      crimson = '#83331f',
      terracotta = '#106a63',
      gold = '#7b4a0d',
      blue = '#28566b',
      green = '#435a20',
    },
  },

  ['smokedglass'] = {
    name = 'Smoked Glass',
    tagline = 'Smoked glass and one warm accent. Quiet code, clear cursor.',
    dark = {
      bg = '#17181a',
      bg2 = '#212326',
      fg = '#e7e7e4',
      comment = '#9b9d9f',
      crimson = '#e8a05a',
      terracotta = '#b9b2a8',
      gold = '#c9c9c4',
      blue = '#9fb4c7',
      green = '#aab8a4',
    },
    light = {
      bg = '#f5f5f3',
      bg2 = '#e9e9e6',
      fg = '#1c1d1f',
      comment = '#626568',
      crimson = '#8a4c0e',
      terracotta = '#6b6258',
      gold = '#4d5054',
      blue = '#3c5f78',
      green = '#4f6350',
    },
  },

  ['frostedglass'] = {
    name = 'Frosted Glass',
    tagline = 'Frosted glass, polar blue-gray and aurora accents. Cold and soft.',
    dark = {
      bg = '#1f242c',
      bg2 = '#2a303a',
      fg = '#e5e9f0',
      comment = '#8391aa',
      crimson = '#88c0d0',
      terracotta = '#d08770',
      gold = '#ebcb8b',
      blue = '#81a1c1',
      green = '#a3be8c',
    },
    light = {
      bg = '#eceff4',
      bg2 = '#e1e6ee',
      fg = '#2e3440',
      comment = '#5e6b80',
      crimson = '#286172',
      terracotta = '#9a5a3a',
      gold = '#7a641f',
      blue = '#35658a',
      green = '#4f6b3a',
    },
  },

  ['cathedralglass'] = {
    name = 'Cathedral Glass',
    tagline = 'Ink black and cathedral light: lilac, peony, carp yellow, spring green.',
    dark = {
      bg = '#16161d',
      bg2 = '#1f1f28',
      fg = '#dcd7ba',
      comment = '#808592',
      crimson = '#9a85bd',
      terracotta = '#d27e99',
      gold = '#e6c384',
      blue = '#7fb4ca',
      green = '#98bb6c',
    },
    light = {
      bg = '#f2eedf',
      bg2 = '#e6e0ce',
      fg = '#1f1f28',
      comment = '#6a6a5a',
      crimson = '#5a3f8f',
      terracotta = '#9a4d6a',
      gold = '#7a5c1f',
      blue = '#2f6f8a',
      green = '#4f6b2a',
    },
  },

  ['leadedglass'] = {
    name = 'Leaded Glass',
    tagline = 'Leaded glass, forest shadow, cream light, autumn orange and river aqua.',
    dark = {
      bg = '#1e2320',
      bg2 = '#2a302b',
      fg = '#d3c6aa',
      comment = '#859289',
      crimson = '#a7c080',
      terracotta = '#e69875',
      gold = '#dbbc7f',
      blue = '#7fbbb3',
      green = '#b8c98a',
    },
    light = {
      bg = '#f2efdf',
      bg2 = '#e6e1cd',
      fg = '#3d484d',
      comment = '#59655d',
      crimson = '#465f30',
      terracotta = '#a3572c',
      gold = '#7a5c1f',
      blue = '#2f6f6a',
      green = '#4f6b2a',
    },
  },
}

--- Split a colorscheme variant name into its theme key and face.
---   'seaglass'       -> 'seaglass', 'dark'
---   'seaglass-light' -> 'seaglass', 'light'
---   'hearthglass-auto' -> 'hearthglass', 'auto'
---@param variant string
---@return string key, string face
function M.split(variant)
  if variant == 'hearthglass-auto' then
    return 'hearthglass', 'auto'
  end
  local key = variant:match('^(.*)%-light$')
  if key and M.themes[key] then
    return key, 'light'
  end
  if M.themes[variant] then
    return variant, 'dark'
  end
  return 'hearthglass', 'dark'
end

--- The colorscheme name for a theme key and face.
---@param key string
---@param face string  'dark' | 'light'
---@return string
function M.variant(key, face)
  if face == 'light' then
    return key .. '-light'
  end
  return key
end

--- Metadata for a theme key, with the display name always available.
---@param key string
---@return table
function M.get(key)
  return M.themes[key] or M.themes['hearthglass']
end

--- All valid theme keys, in presentation order.
---@return string[]
function M.keys()
  return M.order
end

return M
