local src = debug.getinfo(1, 'S').source:sub(2)
vim.env.MACSCROLL_ROOT = vim.env.MACSCROLL_ROOT or vim.fn.fnamemodify(src, ':p:h:h:h')
vim.env.E2E_DIR = vim.env.E2E_DIR or vim.fn.tempname()
vim.opt.runtimepath:prepend(vim.env.MACSCROLL_ROOT)
vim.opt.packpath = ''
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.macscroll_auto = false
vim.g.macscroll_disable = false
vim.cmd('runtime plugin/macscroll.lua')
require('macscroll').setup({
  auto_worker = false,
  keymaps = true,
  mouse = true,
  horiz_step = 6,
  vert_step = 3,
})
