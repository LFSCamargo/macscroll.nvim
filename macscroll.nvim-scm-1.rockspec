-- Optional rockspec for rocks.nvim / LuaRocks (scm install from git).
-- Publish a tagged release with luarocks-tag-release if you want luarocks.org.

local _MODREV, _SPECREV = 'scm', '-1'

rockspec_format = '3.0'
package = 'macscroll.nvim'
version = _MODREV .. _SPECREV

source = {
  url = 'git+https://github.com/LFSCamargo/macscroll.nvim',
}

description = {
  summary = 'macOS trackpad and mouse-wheel scrolling for Neovim',
  detailed = [[
    A Darwin background handler taps scrollWheel events and RPCs this
    plugin so terminals cannot drop sideways motion or rewrite vertical
    wheels before Neovim sees them.
  ]],
  homepage = 'https://github.com/LFSCamargo/macscroll.nvim',
  license = 'MIT',
  labels = { 'neovim', 'nvim', 'macos' },
}

dependencies = {
  'lua >= 5.1',
}

build = {
  type = 'builtin',
  copy_directories = {
    'doc',
    'handler',
    'plugin',
    'scripts',
  },
}
