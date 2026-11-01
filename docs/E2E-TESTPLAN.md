# E2E test plan

`make e2e` runs `tests/e2e/e2e.lua` against an embedded Neovim that loads
the plugin from a test init. `make test-nvim` installs the repo on
`pack/*/start` under an isolated XDG home and starts Neovim without
`--clean`. `E2E_DIR` keeps the Darwin handler off. `make test-lua` covers
pure Lua modules. `make test-swift` covers `MacscrollCore`.

| Case | What must hold | Where |
| --- | --- | --- |
| Handler stays off in e2e | `interactive()`, `listen()`, and `ensure_worker()` are false/nil | `tests/e2e/e2e.lua` |
| Wheel maps | `<ScrollWheelRight>` and `<A-ScrollWheelDown>` have callbacks | `tests/e2e/e2e.lua` |
| Mouse options | `mouse` contains `a`; `sidescroll` 1; `sidescrolloff` 0 | `tests/e2e/e2e.lua` |
| Horizontal scroll | `scroll(1, 0)` increases `leftcol` by `horiz_step` | `tests/e2e/e2e.lua` |
| Vertical scroll | `scroll(0, 1)` increases `topline` by `vert_step` | `tests/e2e/e2e.lua` |
| Option+vertical | `scroll(0, 1, true)` moves `leftcol` only | `tests/e2e/e2e.lua` |
| Forced listen + RPC | `listen({ force = true })` then `--remote-expr` moves both axes | `tests/e2e/e2e.lua` |
| Socket cleanup | `stop()` removes the pid socket | `tests/e2e/e2e.lua` |
| Dir normalize | Option/Ctrl remap vertical-only steps | `tests/lua/run.lua` |
| View math | `leftcol`/`topline` clamp | `tests/lua/run.lua` |
| Handler path | Package lives in `handler/darwin`, not `scripts/` | `tests/lua/run.lua` |
| Safe sockets | Only `<pid>.sock` names | `handler/darwin/Tests` |
| Swallow policy | Consume only when a terminal is frontmost and Neovim is listening | `handler/darwin/Tests` |
| RPC expr | `--remote-expr` calls `require('macscroll').scroll` | `handler/darwin/Tests` |
| Packpath load | `plugin/macscroll.lua` loads from `pack/*/start` | `tests/nvim/suite.lua` |
| User commands | `:MacscrollBuild` / `Start` / `Stop` exist | `tests/nvim/suite.lua` |
| Real wheel | `nvim_input_mouse` wheel right/down moves the view | `tests/nvim/suite.lua` |
| Handler RPC into packpath session | `--remote-expr` scrolls the user-style instance | `tests/nvim/suite.lua` |
| Health | `require('macscroll.health').check()` runs | `tests/nvim/suite.lua` |
