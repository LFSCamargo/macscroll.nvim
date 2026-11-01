---
name: check
description: >-
  Run macscroll.nvim unit and e2e tests. Use when finishing a code change,
  before claiming tests pass, or when the user asks to check, test, or
  validate the plugin.
---

# Check

From the repository root:

```sh
make test
```

That runs Lua unit tests (`tests/lua/run.lua`), Swift `MacscrollCore` tests
when Darwin + swift are available, `bash -n` on `scripts/macscroll.sh`,
the headless e2e suite, and the packpath Neovim suite (`make test-nvim`).

If only one layer changed:

```sh
make test-lua
make test-swift
make e2e
make test-nvim
```

Do not finish a runtime change while any of these fail. Add a failing
regression first when fixing a bug, then make it pass.
