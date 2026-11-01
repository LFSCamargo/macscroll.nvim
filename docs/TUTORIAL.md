# Tutorial

This walkthrough gets horizontal and vertical trackpad scrolling working
in Neovim on macOS. The plugin can map `<ScrollWheel*>` without any extra
permission. The Darwin handler that **owns** those events (so Warp,
Terminal.app, iTerm, and other TTYs cannot drop them) needs Accessibility.

## 1. Install the plugin

With lazy.nvim:

```lua
{
  'LFSCamargo/macscroll.nvim',
  lazy = false,
  build = 'make worker',
  opts = {},
}
```

Restart Neovim so `plugin/macscroll.lua` runs `setup()` and compiles
`macscroll-worker` into `stdpath('data')/macscroll/macscroll-worker`
(usually `~/.local/share/nvim/macscroll/macscroll-worker`).

Or from the plugin checkout: `make worker`, then `:MacscrollStart`.

## 2. Grant Accessibility

The worker installs a `CGEvent` session tap. macOS only delivers those
events to an app listed under Accessibility. Until that is on, the
worker cannot see the trackpad and the terminal still decides which
wheels reach Neovim.

1. Open **System Settings**.
2. Go to **Privacy & Security**.
3. Open **Accessibility** (sometimes under **Privacy** on older macOS).
4. Unlock the list (click the lock, or use Touch ID / your password).
5. Turn on **macscroll-worker**.

If the row is missing:

1. Click **+**.
2. Press **Cmd+Shift+G** and paste:

   `~/.local/share/nvim/macscroll/macscroll-worker`
3. Select the file and enable the checkbox.

Use the path from `:checkhealth macscroll` if you use `NVIM_APPNAME` or
a custom `XDG_DATA_HOME`. Grant the **worker binary**, not `nvim`,
`swift`, or your terminal.

## 3. Restart the worker

macOS applies Accessibility to the next launch, not to a process that
already failed to create the tap.

- In Neovim: `:MacscrollStop` then `:MacscrollStart`
- Or quit Neovim and open it again
- If you installed the login helper (`make install`), log out or
  `launchctl kickstart -k gui/$(id -u)/com.macscroll.worker`

## 4. Check that it worked

`:checkhealth macscroll` should show the worker binary and that
`macscroll-worker` is running.

Then, in a terminal Neovim session with a wide or tall file:

- Two-finger swipe up/down moves `topline`
- Two-finger swipe left/right moves `leftcol`
- Option or Ctrl plus a vertical swipe also moves sideways

If only vertical motion works, the TTY is still filtering axis-2 and
the tap is not active. Repeat step 2 and restart the worker. After
`make worker` or `:MacscrollBuild`, macOS may treat the new binary as
unsigned or new; toggle the Accessibility row off and on.

## Optional: start at login

```sh
make install     # LaunchAgent for the same macscroll-worker path
make uninstall
```

The LaunchAgent needs the same Accessibility grant. You do not grant
`launchctl` itself.
