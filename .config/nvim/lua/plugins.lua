-- plugins.lua
vim.cmd [[packadd packer.nvim]]

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim' -- Let packer manage itself

  use {
    "catppuccin/nvim",
    as = "catppuccin",
    config = function()
      require("catppuccin").setup({
        flavour = "macchiato",
        term_colors = true,
        transparent_background = false,
      })
    end,
  }
end)

