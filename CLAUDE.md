# Claude Code

Follow @AGENTS.md.

## Changing files

Before you finish a code change: write tests in `tests/lua/`,
`handler/darwin/Tests/`, and `tests/e2e/` (bug fixes need a regression that
fails without the patch and is listed in `docs/E2E-TESTPLAN.md`), keep Swift
in `handler/darwin` (not `scripts/`), run `make test`, review the diff for
command injection and unsafe sockets, and keep `README.md` plus
`doc/macscroll.txt` in sync.

## Committing

Only commit when asked. Use Conventional Commits. Skills are identical under
`.claude/skills/`, `.cursor/skills/`, and `.codex/skills/`.
