-- ============================================================================
-- hearthglass/zed.lua
--
-- Builds a Zed Editor theme family from the same palette the colorscheme uses.
--
-- Zed themes are JSON files describing a *family* (one or more variants), so
-- this module produces the family table and encodes it as JSON. The palette
-- comes straight from `hearthglass.colors`, which means the `low_blue_light`
-- and `colorblind` options apply here exactly as they do in Neovim: there is
-- no second copy of the palette to keep in sync.
--
-- Mapping notes (Neovim group -> Zed capture):
--   * Zed colors code with tree-sitter captures rather than Vim highlight
--     groups, so the groups from `hearthglass.scheme` are re-expressed as
--     capture names: Comment -> comment, String -> string,
--     Constant -> constant/number/boolean, Statement -> keyword,
--     Type -> type, Function -> function, PreProc -> preproc/attribute,
--     Identifier -> variable/punctuation.
--   * The deepwhite pastel slabs (the light_* backgrounds behind String,
--     Constant and Statement) carry over as `background_color` on the
--     matching captures, so the Zed theme keeps the warm-block look of the
--     Neovim one.
--   * Zed has no cursor or search highlight groups, so the theme's hero
--     accent moves up into the UI layer: focused borders, the accent text
--     color and the active search match all use the orange accent slot.
--   * Zed's `vim.*` keys paint the Vim mode indicator; they reuse the
--     mini.statusline slabs from the Neovim theme.
--
-- Usage:
--   require('hearthglass.zed').family()      -- the theme family as a table
--   require('hearthglass.zed').json(opts)    -- the family as JSON text
-- ============================================================================

local M = {}

-- Fully transparent, for borders and ghost elements that should not paint.
local TRANSPARENT = '#00000000'

-- Append an alpha channel to a color: alpha('#e0893d', '66') -> '#e0893d66'.
local function alpha(hex, a)
  return hex:sub(1, 7) .. a
end

-- Mix a color toward white. Used for the bright ANSI terminals.
local function brighten(hex, amount)
  return require('hearthglass.colors').blend(hex, '#ffffff', amount)
end

-- Mix a color toward the terminal background. Used for the dim ANSI slots.
local function dim(hex, background, amount)
  return require('hearthglass.colors').blend(hex, background, amount)
end

-- ---------------------------------------------------------------------------
-- JSON encoding
-- ---------------------------------------------------------------------------

local function is_array(t)
  local count = 0
  for key in pairs(t) do
    if type(key) ~= 'number' then
      return false
    end
    count = count + 1
  end
  for i = 1, count do
    if t[i] == nil then
      return false
    end
  end
  return true
end

local ESCAPES = {
  ['"'] = '\\"',
  ['\\'] = '\\\\',
  ['\b'] = '\\b',
  ['\f'] = '\\f',
  ['\n'] = '\\n',
  ['\r'] = '\\r',
  ['\t'] = '\\t',
}

local function escape(str)
  return (str:gsub('[%c"\\]', function(ch)
    return ESCAPES[ch] or string.format('\\u%04x', ch:byte())
  end))
end

-- Encode a Lua value as pretty-printed JSON. Object keys are sorted so the
-- generated file is stable across runs and diffs cleanly.
local function encode(value, level)
  level = level or 0
  local indent = string.rep('  ', level)
  local inner = string.rep('  ', level + 1)

  local value_type = type(value)
  if value_type == 'string' then
    return '"' .. escape(value) .. '"'
  elseif value_type == 'number' then
    if value == math.floor(value) then
      return string.format('%d', value)
    end
    return tostring(value)
  elseif value_type == 'boolean' then
    return tostring(value)
  elseif value_type == 'nil' then
    return 'null'
  end

  if is_array(value) then
    if #value == 0 then
      return '[]'
    end
    local lines = {}
    for _, item in ipairs(value) do
      table.insert(lines, inner .. encode(item, level + 1))
    end
    return '[\n' .. table.concat(lines, ',\n') .. '\n' .. indent .. ']'
  end

  local keys = {}
  for key in pairs(value) do
    table.insert(keys, key)
  end
  if #keys == 0 then
    return '{}'
  end
  table.sort(keys)
  local lines = {}
  for _, key in ipairs(keys) do
    local item = value[key]
    if item ~= nil then
      table.insert(lines, inner .. '"' .. escape(key) .. '": ' .. encode(item, level + 1))
    end
  end
  return '{\n' .. table.concat(lines, ',\n') .. '\n' .. indent .. '}'
end

-- ---------------------------------------------------------------------------
-- Theme construction
-- ---------------------------------------------------------------------------

-- The syntax captures, mirroring the highlight groups in `hearthglass.scheme`.
--
-- The pastel slabs are the deepwhite structure: strings sit on the green
-- block, constants and numbers on the yellow block, keywords and labels on
-- the orange block. Everything else keeps the group colors of the Neovim
-- theme (steel blue functions, terracotta preprocessor, gold types).
local function build_syntax(c)
  return {
    attribute = { color = c.pink },
    boolean = { color = c.syntax_constant, background_color = c.light_yellow },
    comment = { color = c.base3 },
    -- Doc comments are lifted one step out of the comment gray so they stay
    -- readable without competing with the code around them.
    ['comment.doc'] = { color = c.base2 },
    constant = { color = c.syntax_constant, background_color = c.light_yellow },
    constructor = { color = c.base0 },
    embedded = { color = c.base1 },
    emphasis = { color = c.base0, font_style = 'italic' },
    ['emphasis.strong'] = { color = c.base0, font_weight = 700 },
    enum = { color = c.syntax_type },
    ['function'] = { color = c.blue },
    ['function.builtin'] = { color = c.blue },
    ['function.method'] = { color = c.blue },
    ['function.method.call'] = { color = c.blue },
    hint = { color = c.cyan },
    keyword = { color = c.syntax_statement, background_color = c.light_orange },
    label = { color = c.syntax_statement, background_color = c.light_orange },
    link_text = { color = c.base0, font_style = 'italic' },
    link_uri = { color = c.orange },
    namespace = { color = c.pink },
    number = { color = c.syntax_constant, background_color = c.light_yellow },
    operator = { color = c.base0 },
    predictive = { color = c.base3, font_style = 'italic' },
    preproc = { color = c.pink },
    primary = { color = c.base0 },
    property = { color = c.base0 },
    punctuation = { color = c.base0 },
    ['punctuation.bracket'] = { color = c.base0 },
    ['punctuation.delimiter'] = { color = c.base0 },
    ['punctuation.list_marker'] = { color = c.base0 },
    ['punctuation.markup'] = { color = c.blue },
    ['punctuation.special'] = { color = c.base0 },
    selector = { color = c.orange },
    ['selector.pseudo'] = { color = c.purple },
    string = { color = c.syntax_string, background_color = c.light_green },
    ['string.escape'] = { color = c.blue },
    ['string.regex'] = { color = c.syntax_string, background_color = c.light_green },
    ['string.special'] = { color = c.blue },
    ['string.special.symbol'] = { color = c.base0 },
    tag = { color = c.syntax_statement, background_color = c.light_orange },
    ['text.literal'] = { color = c.base1 },
    title = { color = c.base0, font_weight = 700 },
    type = { color = c.syntax_type },
    variable = { color = c.base0 },
    ['variable.parameter'] = { color = c.base0 },
    ['variable.special'] = { color = c.base0 },
    variant = { color = c.base0 },
    ['diff.plus'] = { color = c.green },
    ['diff.minus'] = { color = c.red },
  }
end

-- The status colors (diff, diagnostics, git). Green and red stay the only
-- pair that carries meaning, exactly as in the Neovim theme.
local function build_status(c)
  return {
    conflict = { color = c.orange, background = c.light_orange, border = c.orange },
    created = { color = c.green, background = c.light_green, border = c.green },
    deleted = { color = c.red, background = c.light_red, border = c.red },
    error = { color = c.red, background = c.light_red, border = c.red },
    hidden = { color = c.base4, background = c.base6, border = c.base5 },
    hint = { color = c.cyan, background = c.light_cyan, border = c.cyan },
    ignored = { color = c.base4, background = c.base6, border = c.base5 },
    info = { color = c.blue, background = c.light_blue, border = c.blue },
    modified = { color = c.orange, background = c.light_orange, border = c.orange },
    predictive = { color = c.base3, background = c.light_purple, border = c.base4 },
    renamed = { color = c.blue, background = c.light_blue, border = c.blue },
    success = { color = c.green, background = c.light_green, border = c.green },
    unreachable = { color = c.base3, background = c.base6, border = c.base5 },
    warning = { color = c.orange, background = c.light_orange, border = c.orange },
  }
end

-- The editor chrome and UI surfaces. Zed stacks surfaces in three levels:
-- the editor sits on the background, panels and chrome sit one step up, and
-- raised surfaces (popups, toolbars, the active tab) sit above that.
local function build_style(c, dark)
  local blend = require('hearthglass.colors').blend

  local surface = c.base6
  -- On parchment the raised surfaces go the other way: a popup is a near-white
  -- card floating over the panel, while the panel itself is a shade darker
  -- than the editor, the way the light ramp runs.
  local raised = dark and c.base5 or blend(c.base7, '#ffffff', 0.6)
  local active = dark and c.base4 or blend(c.base6, c.base4, 0.85)
  local hover = dark and c.base5 or blend(c.base6, c.base5, 0.85)

  -- On parchment the borders need to read darker, not lighter, so the border
  -- ramp runs the other way in the light variant.
  local border = dark and c.base3 or c.base4
  local border_variant = dark and c.base5 or blend(c.base6, c.base4, 0.7)
  local border_disabled = dark and c.base5 or blend(c.base6, c.base4, 0.5)

  local terminal_bg = c.base7
  local ansi_black = dark and c.base7 or c.base0
  local ansi_white = dark and c.base0 or c.base7

  local style = {
    -- Surfaces -------------------------------------------------------
    background = c.base7,
    ['surface.background'] = surface,
    ['elevated_surface.background'] = raised,
    ['panel.background'] = surface,
    ['panel.overlay_background'] = raised,
    ['panel.overlay_hover'] = active,
    ['status_bar.background'] = surface,
    ['title_bar.background'] = surface,
    -- The inactive title bar recedes into the app background in both
    -- variants: down into the ash on dark, up into the parchment on light.
    ['title_bar.inactive_background'] = c.base7,
    ['toolbar.background'] = raised,
    ['tab_bar.background'] = surface,
    ['tab.inactive_background'] = surface,
    ['tab.active_background'] = raised,

    -- Elements -------------------------------------------------------
    ['element.background'] = surface,
    ['element.hover'] = hover,
    ['element.active'] = active,
    ['element.selected'] = active,
    ['element.disabled'] = surface,
    ['element.selection_background'] = alpha(c.base5, '4d'),
    ['ghost_element.background'] = TRANSPARENT,
    ['ghost_element.hover'] = surface,
    ['ghost_element.active'] = hover,
    ['ghost_element.selected'] = hover,
    ['ghost_element.disabled'] = surface,
    ['drop_target.background'] = alpha(c.orange, '33'),
    ['drop_target.border'] = c.orange,

    -- Borders --------------------------------------------------------
    border = border,
    ['border.variant'] = border_variant,
    ['border.focused'] = c.orange,
    ['border.selected'] = c.orange,
    ['border.transparent'] = TRANSPARENT,
    ['border.disabled'] = border_disabled,
    ['panel.focused_border'] = c.orange,
    ['pane.focused_border'] = c.orange,
    ['pane_group.border'] = border_variant,

    -- Text and icons -------------------------------------------------
    text = c.base0,
    ['text.muted'] = c.base3,
    ['text.placeholder'] = c.base4,
    ['text.disabled'] = c.base4,
    ['text.accent'] = c.orange,
    icon = c.base0,
    ['icon.muted'] = c.base3,
    ['icon.disabled'] = c.base4,
    ['icon.placeholder'] = c.base3,
    ['icon.accent'] = c.orange,
    ['debugger.accent'] = c.cyan,
    ['link_text.hover'] = c.blue,

    -- Search ---------------------------------------------------------
    ['search.match_background'] = alpha(dark and c.base4 or c.yellow, '66'),
    ['search.active_match_background'] = alpha(c.orange, '66'),

    -- Editor ---------------------------------------------------------
    ['editor.foreground'] = c.base0,
    ['editor.background'] = c.base7,
    ['editor.gutter.background'] = c.base7,
    ['editor.subheader.background'] = surface,
    ['editor.active_line.background'] = surface,
    ['editor.highlighted_line.background'] = surface,
    ['editor.line_number'] = c.base3,
    ['editor.active_line_number'] = c.yellow,
    ['editor.hover_line_number'] = c.base2,
    ['editor.invisible'] = c.base4,
    ['editor.code_lens.foreground'] = c.base3,
    ['editor.wrap_guide'] = alpha(c.base5, '33'),
    ['editor.active_wrap_guide'] = alpha(c.base4, '66'),
    ['editor.indent_guide'] = alpha(c.base5, '26'),
    ['editor.indent_guide_active'] = alpha(c.base4, '66'),
    ['panel.indent_guide'] = alpha(c.base5, '26'),
    ['panel.indent_guide_hover'] = alpha(c.base4, '66'),
    ['panel.indent_guide_active'] = alpha(c.base4, '66'),
    ['editor.document_highlight.read_background'] = alpha(c.base5, '66'),
    ['editor.document_highlight.write_background'] = alpha(c.light_orange, '99'),
    ['editor.document_highlight.bracket_background'] = alpha(c.base5, '66'),

    -- Scrollbars and minimap -----------------------------------------
    ['scrollbar.thumb.background'] = alpha(c.base5, '4c'),
    ['scrollbar.thumb.hover_background'] = alpha(c.base3, '4c'),
    ['scrollbar.thumb.active_background'] = alpha(c.orange, 'ac'),
    ['scrollbar.thumb.border'] = TRANSPARENT,
    ['scrollbar.track.background'] = TRANSPARENT,
    ['scrollbar.track.border'] = TRANSPARENT,
    ['minimap.thumb.background'] = alpha(c.base5, '4c'),
    ['minimap.thumb.hover_background'] = alpha(c.base4, '4c'),
    ['minimap.thumb.active_background'] = alpha(c.orange, 'ac'),
    ['minimap.thumb.border'] = TRANSPARENT,

    -- Terminal -------------------------------------------------------
    ['terminal.background'] = terminal_bg,
    ['terminal.foreground'] = c.base0,
    ['terminal.bright_foreground'] = c.base0,
    ['terminal.dim_foreground'] = c.base3,
    ['terminal.ansi.background'] = terminal_bg,
    ['terminal.ansi.black'] = ansi_black,
    ['terminal.ansi.red'] = c.red,
    ['terminal.ansi.green'] = c.green,
    ['terminal.ansi.yellow'] = c.yellow,
    ['terminal.ansi.blue'] = c.blue,
    ['terminal.ansi.magenta'] = c.purple,
    ['terminal.ansi.cyan'] = c.cyan,
    ['terminal.ansi.white'] = ansi_white,
    ['terminal.ansi.bright_black'] = c.base4,
    ['terminal.ansi.bright_red'] = brighten(c.red, 0.22),
    ['terminal.ansi.bright_green'] = brighten(c.green, 0.22),
    ['terminal.ansi.bright_yellow'] = brighten(c.yellow, 0.22),
    ['terminal.ansi.bright_blue'] = brighten(c.blue, 0.22),
    ['terminal.ansi.bright_magenta'] = brighten(c.purple, 0.22),
    ['terminal.ansi.bright_cyan'] = brighten(c.cyan, 0.22),
    ['terminal.ansi.bright_white'] = brighten(ansi_white, 0.22),
    ['terminal.ansi.dim_black'] = dim(ansi_black, terminal_bg, 0.6),
    ['terminal.ansi.dim_red'] = dim(c.red, terminal_bg, 0.6),
    ['terminal.ansi.dim_green'] = dim(c.green, terminal_bg, 0.6),
    ['terminal.ansi.dim_yellow'] = dim(c.yellow, terminal_bg, 0.6),
    ['terminal.ansi.dim_blue'] = dim(c.blue, terminal_bg, 0.6),
    ['terminal.ansi.dim_magenta'] = dim(c.purple, terminal_bg, 0.6),
    ['terminal.ansi.dim_cyan'] = dim(c.cyan, terminal_bg, 0.6),
    ['terminal.ansi.dim_white'] = dim(ansi_white, terminal_bg, 0.6),

    -- Version control ------------------------------------------------
    ['version_control.added'] = c.green,
    ['version_control.deleted'] = c.red,
    ['version_control.modified'] = c.orange,
    ['version_control.renamed'] = c.blue,
    ['version_control.conflict'] = c.orange,
    ['version_control.ignored'] = c.base4,
    ['version_control.word_added'] = c.green,
    ['version_control.word_deleted'] = c.red,
    ['version_control.conflict_marker.ours'] = c.green,
    ['version_control.conflict_marker.theirs'] = c.orange,

    -- Vim mode indicator ---------------------------------------------
    ['vim.normal.background'] = TRANSPARENT,
    ['vim.insert.background'] = c.light_green,
    ['vim.replace.background'] = c.light_red,
    ['vim.visual.background'] = c.light_cyan,
    ['vim.visual_line.background'] = c.light_cyan,
    ['vim.visual_block.background'] = c.light_cyan,
    ['vim.yank.background'] = c.light_green,
    ['vim.normal.foreground'] = c.base0,
    ['vim.insert.foreground'] = c.base0,
    ['vim.replace.foreground'] = c.base0,
    ['vim.visual.foreground'] = c.base0,
    ['vim.visual_line.foreground'] = c.base0,
    ['vim.visual_block.foreground'] = c.base0,

    -- Syntax ---------------------------------------------------------
    syntax = build_syntax(c),
  }

  -- The status colors are flat keys in Zed's schema, so they are folded in
  -- from the compact table above.
  for name, colors in pairs(build_status(c)) do
    style[name] = colors.color
    style[name .. '.background'] = colors.background
    style[name .. '.border'] = colors.border
  end

  -- The accent list Zed shows in the theme picker.
  style.accents = { c.orange, c.yellow, c.green, c.cyan, c.blue, c.purple, c.pink, c.red }

  -- The cursor colors of collaborating users.
  local player_colors = { c.orange, c.yellow, c.green, c.cyan, c.blue, c.purple, c.pink, c.red }
  local players = {}
  for _, color in ipairs(player_colors) do
    table.insert(players, {
      cursor = color,
      background = color,
      selection = alpha(color, '3d'),
    })
  end
  style.players = players

  return style
end

--- Display name for a theme key, as used by the Zed picker.
---@param key string
---@return string
local function display_name(key)
  local themes = require('hearthglass.themes')
  local theme = themes.get(key)
  if key == 'hearthglass' then
    return 'Hearthglass'
  end
  return 'Hearthglass ' .. theme.name
end

--- Build a single Zed theme for a theme key and face.
---@param key string  any theme key
---@param face string  'dark' | 'light'
---@param options table|nil  same options as the colorscheme
---@return table
function M.theme(key, face, options)
  local colors = require('hearthglass.colors').get_colors(
    require('hearthglass.themes').variant(key, face),
    options
  )
  local dark = face ~= 'light'
  local name = display_name(key)

  return {
    name = dark and (name .. ' Dark') or (name .. ' Light'),
    appearance = dark and 'dark' or 'light',
    style = build_style(colors, dark),
  }
end

--- Build the whole theme family (both faces) for a theme key.
---@param key string|nil  any theme key (default: hearthglass)
---@param options table|nil  same options as the colorscheme
---@return table
function M.family(key, options)
  key = key or 'hearthglass'
  return {
    ['$schema'] = 'https://zed.dev/schema/themes/v0.2.0.json',
    name = display_name(key),
    author = 'McCune1224',
    themes = {
      M.theme(key, 'dark', options),
      M.theme(key, 'light', options),
    },
  }
end

--- The theme family as JSON text, ready to write to a Zed themes directory.
---@param options table|nil  same options as the colorscheme
---@param key string|nil  any theme key (default: hearthglass)
---@return string
function M.json(options, key)
  return encode(M.family(key, options)) .. '\n'
end

return M
