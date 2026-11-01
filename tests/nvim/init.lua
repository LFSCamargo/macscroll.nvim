-- Isolated user config for the packpath suite.
-- Neovim loads this from XDG_CONFIG_HOME/nvim/init.lua, then start plugins.
vim.env.E2E_DIR = vim.env.E2E_DIR or vim.fn.stdpath('state') .. '/e2e'
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.macscroll_opts = {
  auto_worker = false,
  keymaps = true,
  mouse = true,
  horiz_step = 6,
  vert_step = 3,
}
vim.opt.swapfile = false
vim.opt.hidden = true
