-- ============================================================================
-- scripts/build-readme-assets.lua
--
-- Builds the SVG previews the README shows, straight from the palettes in
-- lua/hearthglass/themes.lua and lua/hearthglass/colors.lua. Nothing here is a
-- second copy of the colors: the mock editor renders real highlight colors, so
-- the pictures cannot drift from the theme without the drift check noticing.
--
-- Run it with Neovim, from the root of the repository:
--
--   nvim --headless -l scripts/build-readme-assets.lua
--
-- Writes assets/previews/family.svg and one card per theme:
-- assets/previews/<key>.svg.
-- ============================================================================

local script = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(script, ':p:h:h')

vim.opt.runtimepath:prepend(root)
package.path = root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path

local themes = require('hearthglass.themes')
local colors = require('hearthglass.colors')

local MONO = "ui-monospace, 'SF Mono', 'Cascadia Mono', Menlo, Consolas, 'DejaVu Sans Mono', monospace"
local SANS = "-apple-system, 'Segoe UI', Helvetica, Arial, sans-serif"
local INK = '#7d8590'

local out_dir = root .. '/assets/previews'

local function esc(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
end

local function fmt(n)
  return string.format('%.2f', n)
end

-- Token list -> absolute columns, so every glyph lands on one monospace grid
-- and the tinted slabs behind strings, keywords and constants line up.
local function line(tokens)
  local out, col = {}, 0
  for _, tok in ipairs(tokens) do
    out[#out + 1] = { col = col, text = tok[1], kind = tok[2] }
    col = col + #tok[1]
  end
  return out
end

local function sp(n)
  return { string.rep(' ', n or 1), 'space' }
end

-- Syntax map used by the mocks. These are the real highlight groups from
-- lua/hearthglass/scheme.lua, expanded through colors.get_colors.
local function syntax(c)
  return {
    id = { fg = c.base0 },
    kw = { fg = c.syntax_statement, bg = c.light_rose },
    str = { fg = c.syntax_string, bg = c.light_green },
    const = { fg = c.syntax_constant, bg = c.light_yellow },
    fn = { fg = c.blue },
    comment = { fg = c.base3 },
    type = { fg = c.syntax_type },
    space = {},
  }
end

local function draw_line(tokens, x, baseline, size, map)
  local adv = size * 0.6
  local parts = {}
  for _, tok in ipairs(tokens) do
    local style = map[tok.kind]
    if style and style ~= map.space then
      local tx, w = x + tok.col * adv, #tok.text * adv
      if style.bg then
        parts[#parts + 1] = string.format(
          '<rect x="%s" y="%s" width="%s" height="%s" rx="3" fill="%s"/>',
          fmt(tx - 1), fmt(baseline - size * 0.8), fmt(w + 2), fmt(size * 1.06), style.bg
        )
      end
      parts[#parts + 1] = string.format(
        '<text x="%s" y="%s" font-family="%s" font-size="%d" fill="%s" textLength="%s" lengthAdjust="spacing">%s</text>',
        fmt(tx), fmt(baseline), MONO, size, style.fg, fmt(w), esc(tok.text)
      )
    end
  end
  return table.concat(parts)
end

local function chips(swatches, x, y, width, height, label_size)
  local gap = 8
  local w = (width - gap * (#swatches - 1)) / #swatches
  local parts = {}
  for i, swatch in ipairs(swatches) do
    local cx = x + (i - 1) * (w + gap)
    parts[#parts + 1] = string.format(
      '<rect x="%s" y="%s" width="%s" height="%d" rx="3" fill="%s"/>',
      fmt(cx), fmt(y), fmt(w), height, swatch.color
    )
    if label_size and label_size > 0 then
      parts[#parts + 1] = string.format(
        '<text x="%s" y="%s" font-family="%s" font-size="%s" fill="%s" text-anchor="middle">%s</text>',
        fmt(cx + w / 2), fmt(y + height + label_size + 2), MONO, label_size, swatch.ink, esc(swatch.color)
      )
    end
  end
  return table.concat(parts)
end

-- The palette story of one face: hero, keyword, string, function, type, comment.
local function swatches(c)
  return {
    { color = c.orange, ink = c.base3 },
    { color = c.rose, ink = c.base3 },
    { color = c.syntax_string, ink = c.base3 },
    { color = c.blue, ink = c.base3 },
    { color = c.syntax_type, ink = c.base3 },
    { color = c.base3, ink = c.base3 },
  }
end

local snippet = {
  line { { '-- nine palettes, one family', 'comment' } },
  line {
    { 'local', 'kw' }, sp(), { 'hearth', 'id' }, sp(), { '=', 'id' }, sp(),
    { 'require', 'fn' }, { '(', 'id' }, { "'hearthglass'", 'str' }, { ')', 'id' },
  },
  {},
  line {
    { 'hearth', 'id' }, { '.setup', 'fn' }, sp(), { '{', 'id' },
  },
  line {
    sp(2), { 'colorblind', 'id' }, sp(), { '=', 'id' }, sp(),
    { "'deutan'", 'str' }, { ',', 'id' },
  },
  line {
    sp(2), { 'low_blue_light', 'id' }, sp(), { '=', 'id' }, sp(),
    { 'true', 'const' }, { ',', 'id' },
  },
  line { { '}', 'id' } },
  line {
    { 'hearth', 'id' }, { '.set_theme', 'fn' }, { '(', 'id' },
    { "'seaglass'", 'str' }, { ')', 'id' },
  },
}

local function face_pane(face, key, x, y, w)
  local c = colors.get_colors(themes.variant(key, face))
  local map = syntax(c)
  local size = 13
  local adv = size * 0.6
  local bar = 26
  local gutter = 30
  local pad = 14
  local text_x = x + pad + gutter
  local parts = {}

  local code_bottom = y + bar + 22 + (#snippet - 1) * 19
  local chip_y = code_bottom + 30
  local pane_h = chip_y + 18 + 10 + 12 - y

  parts[#parts + 1] = string.format(
    '<rect x="%s" y="%s" width="%s" height="%s" rx="10" fill="%s" stroke="%s" stroke-opacity="0.28"/>',
    fmt(x), fmt(y), fmt(w), fmt(pane_h), c.base7, c.base4
  )
  parts[#parts + 1] = string.format(
    '<path d="M%s %s a10 10 0 0 1 10 -10 h%s a10 10 0 0 1 10 10 v%s h%s z" fill="%s"/>',
    fmt(x), fmt(y + 10), fmt(w - 20), fmt(bar - 10), fmt(-w), c.base6
  )

  local dots = { c.orange, c.pink, c.green }
  for i, dot in ipairs(dots) do
    parts[#parts + 1] = string.format(
      '<circle cx="%s" cy="%s" r="3.5" fill="%s"/>',
      fmt(x + 16 + (i - 1) * 14), fmt(y + bar / 2), dot
    )
  end
  parts[#parts + 1] = string.format(
    '<text x="%s" y="%s" font-family="%s" font-size="10" fill="%s">init.lua</text>',
    fmt(x + 16 + 3 * 14 + 4), fmt(y + bar / 2 + 3.5), MONO, c.base3
  )
  parts[#parts + 1] = string.format(
    '<text x="%s" y="%s" font-family="%s" font-size="10" fill="%s" text-anchor="end" letter-spacing="0.6">%s</text>',
    fmt(x + w - 12), fmt(y + bar / 2 + 3.5), SANS, c.base3, face:upper()
  )

  local baseline = y + bar + 22
  for i, tokens in ipairs(snippet) do
    local by = baseline + (i - 1) * 19
    parts[#parts + 1] = string.format(
      '<text x="%s" y="%s" font-family="%s" font-size="10" fill="%s" text-anchor="end">%d</text>',
      fmt(x + pad + gutter - 10), fmt(by), MONO, c.base4, i
    )
    parts[#parts + 1] = draw_line(tokens, text_x, by, size, map)
    if tokens == snippet[7] then
      -- cursor sits right after the closing brace of setup
      local col = 1
      parts[#parts + 1] = string.format(
        '<rect x="%s" y="%s" width="%s" height="%s" rx="2" fill="%s"/>',
        fmt(text_x + col * adv), fmt(by - size * 0.92), fmt(adv), fmt(size * 1.22), c.orange
      )
    end
  end

  parts[#parts + 1] = chips(swatches(c), x + pad, chip_y, w - pad * 2, 18, 8.5)

  return table.concat(parts), pane_h
end

local function theme_card(key)
  local theme = themes.get(key)
  local w, gap = 398, 24
  local total = w * 2 + gap
  local head = 36

  local dark, pane_h = face_pane('dark', key, 0, head, w)
  local light = face_pane('light', key, w + gap, head, w)
  local height = math.ceil(head + pane_h)

  local parts = {
    string.format(
      '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" role="img" aria-label="%s, dark and light faces">',
      total, height, total, height, esc(theme.name)
    ),
    string.format(
      '<text x="0" y="22" font-family="%s" font-size="19" font-weight="600" fill="%s">%s</text>',
      SANS, INK, esc(theme.name)
    ),
    dark,
    light,
    '</svg>',
  }
  return table.concat(parts)
end

-- ---------------------------------------------------------------------------
-- Family wall: one tile per theme, dark face, so the range reads at a glance.
-- ---------------------------------------------------------------------------

local tile_snippet = {
  line { { '-- nine palettes,', 'comment' } },
  line { { 'local', 'kw' }, sp(), { 'glass', 'id' }, sp(), { '=', 'id' }, sp(), { 'true', 'const' } },
  line {
    { 'glass', 'id' }, { '.set', 'fn' }, { '(', 'id' }, { "'sea'", 'str' }, { ')', 'id' },
  },
}

local function family_tile(key, x, y, w, h)
  local theme = themes.get(key)
  local c = colors.get_colors(key)
  local map = syntax(c)
  local parts = {}

  parts[#parts + 1] = string.format(
    '<rect x="%s" y="%s" width="%d" height="%d" rx="10" fill="%s" stroke="%s" stroke-opacity="0.3"/>',
    fmt(x), fmt(y), w, h, c.base7, c.base4
  )
  parts[#parts + 1] = string.format(
    '<text x="%s" y="%s" font-family="%s" font-size="14" font-weight="600" fill="%s">%s</text>',
    fmt(x + 14), fmt(y + 24), SANS, c.base0, esc(theme.name)
  )

  local swatch_list = {}
  for _, item in ipairs(swatches(c)) do
    swatch_list[#swatch_list + 1] = { color = item.color, ink = item.ink }
  end
  parts[#parts + 1] = chips(swatch_list, x + 14, y + 34, w - 28, 12, 0)

  local baseline = y + 78
  for i, tokens in ipairs(tile_snippet) do
    parts[#parts + 1] = draw_line(tokens, x + 14, baseline + (i - 1) * 17, 12, map)
  end

  return table.concat(parts)
end

local function family_wall()
  local cols, w, h, gap = 3, 296, 126, 16
  local total_w = cols * w + (cols - 1) * gap
  local rows = math.ceil(#themes.keys() / cols)
  local total_h = rows * h + (rows - 1) * gap
  local parts = {
    string.format(
      '<svg xmlns="http://www.w3.org/2000/svg" width="%d" viewBox="0 0 %d %d" role="img" aria-label="The nine Hearthglass themes">',
      total_w * 2, total_w, total_h
    ),
  }
  for i, key in ipairs(themes.keys()) do
    local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
    parts[#parts + 1] = family_tile(key, col * (w + gap), row * (h + gap), w, h)
  end
  parts[#parts + 1] = '</svg>'
  return table.concat(parts)
end

local files = {
  { name = 'family.svg', body = family_wall() },
}
for _, key in ipairs(themes.keys()) do
  table.insert(files, { name = key .. '.svg', body = theme_card(key) })
end

-- `--check` exits 1 when the shipped previews are stale, so palette edits
-- cannot quietly leave the README showing old colors.
local check = false
for _, value in ipairs(arg or {}) do
  if value == '--check' then
    check = true
  end
end

if check then
  local stale = 0
  for _, entry in ipairs(files) do
    local path = out_dir .. '/' .. entry.name
    local existing = table.concat(vim.fn.readfile(path), '\n')
    if existing ~= entry.body then
      stale = stale + 1
      print('STALE ' .. path)
    end
  end
  if stale > 0 then
    print('preview check: ' .. stale .. ' stale file(s), run scripts/build-readme-assets.lua')
    os.exit(1)
  end
  print('preview check: ' .. #files .. ' previews up to date')
  os.exit(0)
end

vim.fn.mkdir(out_dir, 'p')
for _, entry in ipairs(files) do
  vim.fn.writefile({ entry.body }, out_dir .. '/' .. entry.name)
end
print('wrote ' .. #files .. ' previews to assets/previews/')
