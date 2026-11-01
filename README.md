# macscroll.nvim

macOS trackpad and mouse-wheel scrolling for Neovim. A Darwin background
handler taps `scrollWheel` events, swallows them, and RPCs this plugin so
Warp, Terminal.app, iTerm, Kitty, Ghostty, WezTerm, and Alacritty cannot
drop sideways motion or rewrite vertical wheels before Neovim sees them.

Requires Neovim 0.10+ and, for the handler, Xcode Command Line Tools.
The handler **cannot see trackpad or mouse-wheel events** until macOS
Accessibility is granted. See [Accessibility](#accessibility) and the
[tutorial](docs/TUTORIAL.md).

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
`stdpath('data')/macscroll/macscroll-worker` and starts it. It will not
scroll from the trackpad until you grant Accessibility (below).

## Accessibility

macOS blocks session-wide event taps unless the process is allowed under
**Privacy & Security → Accessibility**. `macscroll-worker` uses that tap so
the terminal never filters horizontal or vertical wheels. Without the
checkbox, the worker starts, prints an error on stderr, and Neovim only
sees whatever the TTY decides to forward.

1. Build and start the worker (`:MacscrollBuild`, `:MacscrollStart`, or
   restart Neovim after `build = 'make worker'`).
2. Open **System Settings → Privacy & Security → Accessibility**.
3. Unlock the pane (the lock at the bottom, or Touch ID).
4. Enable **macscroll-worker**. If it is missing, click **+** and add:

   `~/.local/share/nvim/macscroll/macscroll-worker`

   That is `stdpath('data')/macscroll/macscroll-worker`. If you set
   `NVIM_APPNAME` or `XDG_DATA_HOME`, use that data dir instead.
5. Quit the old worker and start a new one (`:MacscrollStop` then
   `:MacscrollStart`, or quit Neovim). macOS does not attach the tap to
   an already-running binary that was denied.

If you run `make install`, the LaunchAgent starts the same binary at
login. Grant Accessibility to that same path, not to `swift` or `nvim`.
Rebuilding the worker can make macOS treat it as a new app; toggle the
row off and on, or add the file again.

Confirm with `:checkhealth macscroll`. Extra terminal bundle IDs can be
set with `MACSCROLL_BUNDLE_IDS=com.foo.term,com.bar.term`.

Optional login helper:

```sh
make install     # LaunchAgent
make uninstall
```

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
