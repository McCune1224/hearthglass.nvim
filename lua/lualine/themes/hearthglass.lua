-- lualine theme for hearthglass (dark variant)
-- Cloned from deepwhite.nvim's lualine theme, recolored with hearthglass dark.
-- Active section is the deepwhite signature inverted block: bg-colored text
-- on a fg-colored background.
local colors = require('hearthglass.colors').get_colors('hearthglass', {})

return {
	visual = {
		a = { fg = colors.base7, bg = colors.base0, gui = 'bold' },
		b = { fg = colors.base0, bg = colors.base7 },
		c = { fg = colors.base0, bg = colors.base7 },
	},
	replace = {
		a = { fg = colors.base7, bg = colors.base0, gui = 'bold' },
		b = { fg = colors.base0, bg = colors.base7 },
		c = { fg = colors.base0, bg = colors.base7 },
	},
	inactive = {
		a = { fg = colors.base7, bg = colors.base0, gui = 'bold' },
		b = { fg = colors.base0, bg = colors.base7 },
		c = { fg = colors.base0, bg = colors.base7 },
	},
	normal = {
		a = { fg = colors.base7, bg = colors.base0, gui = 'bold' },
		b = { fg = colors.base0, bg = colors.base7 },
		c = { fg = colors.base0, bg = colors.base7 },
	},
	insert = {
		a = { fg = colors.base7, bg = colors.base0, gui = 'bold' },
		b = { fg = colors.base0, bg = colors.base7 },
		c = { fg = colors.base0, bg = colors.base7 },
	},
}
