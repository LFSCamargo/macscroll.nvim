# macscroll.nvim

macOS trackpad and mouse-wheel scrolling for Neovim. A Darwin background
handler taps `scrollWheel` events, swallows them, and RPCs this plugin so
Warp, Terminal.app, iTerm, Kitty, Ghostty, WezTerm, and Alacritty cannot
drop sideways motion or rewrite vertical wheels before Neovim sees them.

Requires Neovim 0.10+ and, for the handler, Xcode Command Line Tools plus
Accessibility permission for `macscroll-worker`.

## Install

### lazy.nvim

```lua
{
  'LFSCamargo/macscroll.nvim',
  lazy = false,
  build = 'make worker',
  opts = {},
}
```

Until this repository is on GitHub, use a local path:

```lua
{
  dir = vim.fn.expand('~/work/macscroll.nvim'),
  name = 'macscroll.nvim',
  lazy = false,
  build = 'make worker',
  opts = {},
}
```

### vim-plug

```vim
Plug 'LFSCamargo/macscroll.nvim'
```

Then run `:MacscrollBuild` once, or `make worker` from the plugin directory.

### packpath / `:packadd`

Clone into `pack/*/start/macscroll.nvim` so `lua/` and `plugin/` load on
startup. The `plugin/macscroll.lua` entry calls `setup()` unless you set
`vim.g.macscroll_auto = false`.

## Setup

```lua
require('macscroll').setup({
  horiz_step = 6,
  vert_step = 3,
  mouse = true,
  keymaps = true,
  auto_worker = true,
  skip_buftypes = { 'prompt' },
})
```

On first launch the plugin compiles `handler/darwin` into
`stdpath('data')/macscroll/macscroll-worker` and starts it. Allow
**macscroll-worker** under System Settings → Privacy & Security →
Accessibility.

Optional login helper:

```sh
make install     # LaunchAgent
make uninstall
```

Add extra terminal bundle IDs with `MACSCROLL_BUNDLE_IDS=com.foo.term,com.bar.term`.

## Commands

| Command | Action |
| --- | --- |
| `:MacscrollBuild` | Compile the Darwin handler |
| `:MacscrollStart` | Listen and start the handler |
| `:MacscrollStop` | Close the RPC socket |
| `:checkhealth macscroll` | Diagnose worker, socket, and toolchain |

## Tests

```sh
make test        # Lua unit + Swift unit + e2e + packpath nvim suite
make test-lua
make test-swift
make e2e
make test-nvim   # isolated XDG + pack/*/start install
```

See [docs/E2E-TESTPLAN.md](docs/E2E-TESTPLAN.md).
