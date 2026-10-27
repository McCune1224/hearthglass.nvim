-- ============================================================================
-- scripts/audit-contrast.lua
--
-- WCAG contrast audit for the whole hearthglass family. Run from the repo
-- root with Neovim:
--
--   nvim --headless -l scripts/audit-contrast.lua
--
-- For every dark and light face, and for every option combination the
-- colorscheme exposes, this checks:
--
--   * base0 (main foreground) against base7 >= 7.0:1
--   * base3 (comments) against base7 >= 4.5:1
--   * the hero and every named text accent against base7 >= 4.5:1
--   * string, constant and statement syntax text against their tinted slab
--     >= 4.5:1
--
-- Exits 1 when any measurement misses its threshold.
-- ============================================================================

local script = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(script, ':p:h:h')

vim.opt.runtimepath:prepend(root)
package.path = root .. '/lua/?.lua;' .. root .. '/lua/?/init.lua;' .. package.path

local themes = require('hearthglass.themes')
local colors = require('hearthglass.colors')

local function channel(value, offset)
  return tonumber(value:sub(offset, offset + 1), 16) / 255
end

local function linear(value)
  if value <= 0.04045 then
    return value / 12.92
  end
  return ((value + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex)
  return 0.2126 * linear(channel(hex, 2))
    + 0.7152 * linear(channel(hex, 4))
    + 0.0722 * linear(channel(hex, 6))
end

local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then
    la, lb = lb, la
  end
  return (la + 0.05) / (lb + 0.05)
end

-- Every accent that is used as text in the scheme. `orange` is the hero;
-- `red` deliberately shares it. The derived cyan/purple also count.
local text_accents = { 'orange', 'red', 'yellow', 'green', 'blue', 'cyan', 'purple', 'pink', 'rose' }

local checks = {
  { name = 'base0', fg = 'base0', bg = 'base7', minimum = 7.0 },
  { name = 'comment', fg = 'base3', bg = 'base7', minimum = 4.5 },
}

for _, accent in ipairs(text_accents) do
  table.insert(checks, { name = 'accent:' .. accent, fg = accent, bg = 'base7', minimum = 4.5 })
end

table.insert(checks, { name = 'syntax:string', fg = 'syntax_string', bg = 'light_green', minimum = 4.5 })
table.insert(checks, { name = 'syntax:constant', fg = 'syntax_constant', bg = 'light_yellow', minimum = 4.5 })
table.insert(checks, { name = 'syntax:statement', fg = 'syntax_statement', bg = 'light_orange', minimum = 4.5 })

local variants = {
  { label = 'plain', options = { colorblind = false, low_blue_light = false }, light_only = false },
  { label = 'deutan', options = { colorblind = 'deutan', low_blue_light = false }, light_only = false },
  { label = 'tritan', options = { colorblind = 'tritan', low_blue_light = false }, light_only = false },
  { label = 'plain+low-blue', options = { colorblind = false, low_blue_light = true }, light_only = true },
  { label = 'deutan+low-blue', options = { colorblind = 'deutan', low_blue_light = true }, light_only = true },
  { label = 'tritan+low-blue', options = { colorblind = 'tritan', low_blue_light = true }, light_only = true },
}

local failures = 0
local rows = 0

local function format(value)
  return string.format('%.2f', value)
end

print('hearthglass contrast audit')
print(string.format('%-13s %-6s %-16s %-7s %-7s %-7s %-7s', 'theme', 'face', 'options', 'base0', 'comment', 'hero', 'syntax'))
print(string.rep('-', 82))

for _, key in ipairs(themes.keys()) do
  for _, face in ipairs({ 'dark', 'light' }) do
    for _, variant in ipairs(variants) do
      if face == 'light' or not variant.light_only then
        local name = themes.variant(key, face)
        local palette = colors.get_colors(name, variant.options)
        local measured = {}
        local failed = {}

        for _, check in ipairs(checks) do
          local ratio = contrast(palette[check.fg], palette[check.bg])
          measured[check.name] = ratio
          if ratio + 1e-9 < check.minimum then
            table.insert(failed, ('%s %s on %s = %s:1 < %.1f:1'):format(
              key .. ' ' .. face .. ' ' .. variant.label,
              check.name,
              check.bg,
              format(ratio),
              check.minimum
            ))
          end
        end

        local syntax_min = math.min(
          measured['syntax:string'],
          measured['syntax:constant'],
          measured['syntax:statement']
        )

        rows = rows + 1
        print(string.format(
          '%-13s %-6s %-16s %-7s %-7s %-7s %-7s',
          key,
          face,
          variant.label,
          format(measured.base0),
          format(measured.comment),
          format(measured['accent:orange']),
          format(syntax_min)
        ))

        for _, failure in ipairs(failed) do
          failures = failures + 1
          print('  FAIL ' .. failure)
        end
      end
    end
  end
end

print(string.rep('-', 82))
print(('%d measurement sets checked, %d failure(s)'):format(rows, failures))

if failures > 0 then
  vim.cmd('cquit 1')
end
print('contrast audit passed')
