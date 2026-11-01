# Agent instructions

Cursor, Claude Code, and Codex follow this file. Cursor also loads
`.cursor/rules/`. Claude Code also loads `CLAUDE.md`. Project skills are
identical copies under `.cursor/skills/`, `.claude/skills/`, and
`.codex/skills/`; edit one and copy it to the others.

Do not finish work that skipped a required check. Do not commit or push
unless the user asked.

## Layout

| Path | Role |
| --- | --- |
| `lua/macscroll/` | Plugin API (`init.lua`) and testable helpers (`dirs`, `view`, `config`, `paths`) |
| `plugin/macscroll.lua` | Commands and default `setup()` |
| `handler/darwin/` | Swift package: `MacscrollCore` + `MacscrollWorker` |
| `scripts/macscroll.sh` | Build / LaunchAgent only — not the handler source |
| `tests/lua/` | Lua unit tests |
| `tests/e2e/` | Headless Neovim integration |
| `doc/` | `:help macscroll` |
| `docs/` | Human test plan |

Do not put Swift sources under `scripts/`. The worker is a background handler.

## Changing files

After any code, script, or test change, complete all five before you stop:

1. **Write tests.** Lua helpers → `tests/lua/run.lua`. Handler math / sockets /
   RPC → `handler/darwin/Tests`. Runtime behavior → `tests/e2e/e2e.lua` and
   `docs/E2E-TESTPLAN.md`. Bug fixes need a regression that fails without the
   patch.
2. **Check spaghetti.** Keep `lua/macscroll/init.lua` as wiring. Put normalize
   math in `dirs.lua`, view math in `view.lua`, path lookup in `paths.lua`.
   Handler policy stays in `MacscrollCore`; AppKit tap stays in
   `MacscrollWorker`.
3. **Run tests.** `make test` (Lua + Swift + e2e + `test-nvim`). Fix failures
   before finishing. Do not use `$NVIM` as the binary; that is a listen
   socket. The Makefile uses `NVIM_BIN` and `NVIM_WRAPPER=0`. Packpath /
   user-install coverage lives in `tests/nvim/suite.lua`.
4. **Check vulnerabilities.** No `jobstart` / `system` via a shell string. Socket
   names must be `<pid>.sock`. Quote bash variables. Prefer argv arrays. Do not
   log secrets.
5. **Keep docs in sync.** Install / opts → `README.md`. Commands →
   `doc/macscroll.txt`. E2E cases → `docs/E2E-TESTPLAN.md`.

Docs-only edits skip tests when runtime behavior did not change. Still scan
for secrets.

## Integration

Users load this as a normal Neovim plugin (`lua/` + `plugin/`). Do not require
`nvim.setup` modules. `E2E_DIR` must keep `listen()` and `ensure_worker()` off
unless `{ force = true }`. The handler must swallow scroll events when a
known terminal is frontmost and sockets are live — the TTY must not decide
which events reach Neovim.

## Committing

Only commit when asked. Use Conventional Commits
(`feat`, `fix`, `docs`, `test`, `refactor`, `build`, `chore`).
