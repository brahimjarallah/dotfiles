-- Enable 24-bit color
vim.opt.termguicolors = true

-- Set background and foreground colors globally
local bg = "#0d0f18"
local fg = "#c0caf5"

-- Apply custom highlights
vim.cmd(string.format([[
  hi Normal       guibg=%s guifg=%s
  hi NormalNC     guibg=%s
  hi NormalFloat  guibg=%s
  hi FloatBorder  guibg=%s guifg=#3b4261
  hi VertSplit    guibg=%s guifg=#1a1b26
  hi SignColumn   guibg=%s
  hi StatusLine   guibg=%s guifg=%s
  hi TabLineFill  guibg=%s
  hi EndOfBuffer  guibg=%s guifg=#1a1b26
  hi Pmenu        guibg=%s guifg=%s
  hi PmenuSel     guibg=#1a1b26 guifg=%s
]], bg, fg, bg, bg, bg, bg, bg, bg, fg, bg, bg, bg, fg, fg))
