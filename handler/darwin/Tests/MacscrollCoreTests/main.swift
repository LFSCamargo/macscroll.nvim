import Foundation
import MacscrollCore

private var failed = 0
private var passed = 0

private func expect(_ cond: Bool, _ name: String) {
  if cond {
    passed += 1
    print("PASS \(name)")
  } else {
    failed += 1
    FileHandle.standardError.write(Data("FAIL \(name)\n".utf8))
  }
}

expect(SocketName.isSafe("123.sock"), "pid socket is safe")
expect(SocketName.isSafe("1.sock"), "single-digit pid is safe")
expect(!SocketName.isSafe("nvim.sock"), "named socket is rejected")
expect(!SocketName.isSafe("123.sock.bak"), "extra suffix is rejected")
expect(!SocketName.isSafe("123"), "missing extension is rejected")
expect(!SocketName.isSafe(".sock"), "empty pid is rejected")
expect(!SocketName.isSafe("../123.sock"), "parent path is rejected")

let dirs = SocketName.directories(
  stateHomes: [URL(fileURLWithPath: "/tmp/state", isDirectory: true)],
  appname: "nvim"
)
expect(dirs.map(\.path) == ["/tmp/state/nvim/macscroll"], "socket dirs stay under app state")

expect(Terminals.isKnown("dev.warp.Warp"), "Warp is a known terminal")
expect(Terminals.isKnown("com.apple.Terminal"), "Terminal.app is a known terminal")
expect(Terminals.isKnown("com.googlecode.iterm2"), "iTerm is a known terminal")
expect(Terminals.isKnown("net.kovidgoyal.kitty"), "Kitty is a known terminal")
expect(!Terminals.isKnown("com.apple.Safari"), "Safari is not a terminal")

let extra = Terminals.extraIds(from: " com.foo.term ,bar.app ")
expect(Terminals.isKnown("com.foo.term", extra: extra), "MACSCROLL_BUNDLE_IDS is honored")

expect(ScrollMath.preferredAxis(point: 4, fixed: 2, line: 1) == 4, "pixel delta wins")
expect(ScrollMath.preferredAxis(point: 0, fixed: 2, line: 1) == 2, "fixed delta is fallback")
expect(ScrollMath.preferredAxis(point: 0, fixed: 0, line: 1) == 1, "line delta is last resort")
expect(ScrollMath.invert(3) == -1, "natural swipe inverts positive")
expect(ScrollMath.invert(-2) == 1, "natural swipe inverts negative")
expect(ScrollMath.invert(0) == 0, "zero pending is zero")

expect(EventPolicy.swallow(terminalFrontmost: true, hasListeners: true), "swallow when listening in a terminal")
expect(!EventPolicy.swallow(terminalFrontmost: true, hasListeners: false), "pass through without listeners")
expect(!EventPolicy.swallow(terminalFrontmost: false, hasListeners: true), "pass through outside a terminal")

expect(
  RPC.remoteExpr(horiz: 3, vert: -2, alt: 1, ctrl: 0)
    == "luaeval(\"require('macscroll').scroll(1,-1,1,0)\")",
  "RPC expr calls plugin scroll"
)

print("swift unit tests: \(passed) passed, \(failed) failed")
if failed > 0 {
  exit(1)
}
