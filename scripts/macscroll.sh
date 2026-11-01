#!/usr/bin/env bash
# Build or install the Darwin background handler (not a TTY script).
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd -P)"
PKG="$ROOT/handler/darwin"
BIN="${MACSCROLL_BIN:-$HOME/.local/share/nvim/macscroll/macscroll-worker}"
PLIST="${HOME}/Library/LaunchAgents/com.macscroll.worker.plist"
LABEL='com.macscroll.worker'

is_darwin() { [[ "$(uname -s)" == Darwin ]]; }

say() { printf '%s\n' "$*"; }
die() { printf 'macscroll: %s\n' "$*" >&2; exit 1; }

build() {
  is_darwin || {
    say 'macscroll handler is macOS only.'
    return 0
  }
  command -v swift > /dev/null 2>&1 || {
    say 'swift not found; install Xcode Command Line Tools.'
    return 0
  }
  [[ -f "$PKG/Package.swift" ]] || die "Missing $PKG/Package.swift"
  swift build -c release --package-path "$PKG" --product macscroll-worker
  local built
  built="$(swift build -c release --package-path "$PKG" --show-bin-path)/macscroll-worker"
  [[ -x "$built" ]] || die "swift build did not produce $built"
  mkdir -p -- "$(dirname -- "$BIN")"
  cp -f -- "$built" "$BIN"
  chmod 755 "$BIN"
  say "Built $BIN"
}

running() {
  pgrep -x macscroll-worker > /dev/null 2>&1
}

ensure() {
  is_darwin || return 0
  [[ -x "$BIN" ]] || build
  [[ -x "$BIN" ]] || return 0
  if running; then
    return 0
  fi
  "$BIN" &
}

install_agent() {
  is_darwin || return 0
  [[ -x "$BIN" ]] || build
  [[ -x "$BIN" ]] || return 0
  mkdir -p -- "$(dirname -- "$PLIST")"
  local path_xml
  path_xml="$(printf '%s' "${HOME}/.local/bin:${HOME}/.local/opt/nvim/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin" | sed 's/&/\&amp;/g; s/</\&lt;/g')"
  cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${BIN}</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>${path_xml}</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>LimitLoadToSessionType</key>
  <string>Aqua</string>
</dict>
</plist>
EOF
  launchctl bootout "gui/$(id -u)/${LABEL}" > /dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"
  say "Loaded ${LABEL}. Allow Accessibility for macscroll-worker if prompted."
}

uninstall_agent() {
  is_darwin || return 0
  launchctl bootout "gui/$(id -u)/${LABEL}" > /dev/null 2>&1 || true
  rm -f -- "$PLIST"
  say "Stopped ${LABEL}."
}

cmd="${1:-ensure}"
case "$cmd" in
  build) build ;;
  ensure) ensure ;;
  install) install_agent ;;
  uninstall) uninstall_agent ;;
  *) die "Expected build, ensure, install, or uninstall" ;;
esac
