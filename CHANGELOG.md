# Changelog

All notable changes to this project are documented in this file.

## [v1] - 2026-11-01

### Features

- macOS Neovim plugin that owns horizontal and vertical trackpad and mouse-wheel scrolling
- Darwin `macscroll-worker` session tap swallows `scrollWheel` events so terminals cannot drop axis-2 or rewrite axis-1
- RPC into `require('macscroll').scroll` over a pid-guarded listen socket
- Option/Ctrl plus vertical wheel maps to sideways scroll
- Packpath install, `:MacscrollBuild` / `:MacscrollStart` / `:MacscrollStop`, and `:checkhealth macscroll`

### Documentation

- Accessibility grant path for `macscroll-worker` in the README, tutorial, and `:help macscroll-accessibility`
