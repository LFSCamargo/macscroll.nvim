import AppKit
import ApplicationServices
import Darwin
import Foundation
import MacscrollCore

/// Session tap for trackpad and mouse wheel events.
/// Terminals drop or rewrite axis-2 (and sometimes axis-1). This handler
/// swallows the CGEvent and RPCs Neovim so the TTY never decides.

private func homeStateRoot() -> URL {
  FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".local", isDirectory: true)
    .appendingPathComponent("state", isDirectory: true)
}

private func socketDirs() -> [URL] {
  let env = ProcessInfo.processInfo.environment
  let app = env["NVIM_APPNAME"].flatMap { $0.isEmpty ? nil : $0 } ?? "nvim"
  var roots: [URL] = [homeStateRoot()]
  if let raw = env["XDG_STATE_HOME"], !raw.isEmpty {
    roots.append(URL(fileURLWithPath: raw, isDirectory: true))
  }
  return SocketName.directories(stateHomes: roots, appname: app)
}

private func canConnect(_ path: String) -> Bool {
  guard path.utf8.count < 104 else {
    return false
  }
  let fd = socket(AF_UNIX, SOCK_STREAM, 0)
  guard fd >= 0 else {
    return false
  }
  defer { close(fd) }
  var addr = sockaddr_un()
  addr.sun_family = sa_family_t(AF_UNIX)
  path.withCString { src in
    withUnsafeMutablePointer(to: &addr.sun_path) { dst in
      dst.withMemoryRebound(to: CChar.self, capacity: 104) { buf in
        _ = strncpy(buf, src, 103)
      }
    }
  }
  return withUnsafePointer(to: &addr) { ptr in
    ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
      connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) == 0
    }
  }
}

private var cachedSockets: [String] = []
private var cachedAt = Date.distantPast

private func liveSockets() -> [String] {
  if Date().timeIntervalSince(cachedAt) < 0.25 {
    return cachedSockets
  }
  cachedSockets = sockets()
  cachedAt = Date()
  return cachedSockets
}

private func sockets() -> [String] {
  var paths: [String] = []
  let files = FileManager.default
  for folder in socketDirs() {
    guard let names = try? files.contentsOfDirectory(atPath: folder.path) else {
      continue
    }
    for name in names where SocketName.isSafe(name) {
      let path = folder.appendingPathComponent(name).path
      if canConnect(path) {
        paths.append(path)
      } else {
        try? files.removeItem(atPath: path)
      }
    }
  }
  return paths
}

private func nvimLaunchPath() -> String {
  let home = FileManager.default.homeDirectoryForCurrentUser.path
  return [
    "\(home)/.local/bin",
    "\(home)/.local/opt/nvim/bin",
    "/opt/homebrew/bin",
    "/usr/local/bin",
    "/usr/bin",
    "/bin",
  ].joined(separator: ":")
}

private func nvimURL() -> URL? {
  let file = FileManager.default
  for dir in nvimLaunchPath().split(separator: ":") {
    let url = URL(fileURLWithPath: String(dir), isDirectory: true)
      .appendingPathComponent("nvim")
    if file.isExecutableFile(atPath: url.path) {
      return url
    }
  }
  return nil
}

private let notifyQueue = DispatchQueue(label: "com.macscroll.worker")
private var notifyBusy = false

private func notify(horiz: Int, vert: Int, alt: Int, ctrl: Int) {
  let expr = RPC.remoteExpr(horiz: horiz, vert: vert, alt: alt, ctrl: ctrl)
  if horiz == 0 && vert == 0 {
    return
  }
  notifyQueue.async {
    if notifyBusy {
      return
    }
    notifyBusy = true
    defer { notifyBusy = false }
    guard let nvim = nvimURL() else {
      return
    }
    for sock in liveSockets() {
      let proc = Process()
      proc.executableURL = nvim
      proc.arguments = [
        "--headless", "--server", sock, "--remote-expr", expr,
      ]
      proc.environment = ["PATH": nvimLaunchPath()]
      proc.standardOutput = FileHandle.nullDevice
      proc.standardError = FileHandle.nullDevice
      do {
        try proc.run()
      } catch {
        continue
      }
      let done = DispatchSemaphore(value: 0)
      proc.terminationHandler = { _ in done.signal() }
      if done.wait(timeout: .now() + 0.8) == .timedOut {
        proc.terminate()
      }
    }
  }
}

private func terminalIsFrontmost() -> Bool {
  guard let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
    return false
  }
  let extra = Terminals.extraIds(
    from: ProcessInfo.processInfo.environment["MACSCROLL_BUNDLE_IDS"] ?? ""
  )
  return Terminals.isKnown(id, extra: extra)
}

private var lastFire = Date.distantPast
private var pendingH = 0.0
private var pendingV = 0.0

private func axes(_ event: CGEvent) -> (Double, Double) {
  let axis1 = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
  let axis2 = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis2))
  let point1 = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
  let point2 = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)
  let fixed1 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
  let fixed2 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
  let vert = ScrollMath.preferredAxis(point: point1, fixed: fixed1, line: axis1)
  let horiz = ScrollMath.preferredAxis(point: point2, fixed: fixed2, line: axis2)
  return (horiz, vert)
}

private func handle(_ event: CGEvent) -> Unmanaged<CGEvent>? {
  let listeners = liveSockets()
  if !EventPolicy.swallow(terminalFrontmost: terminalIsFrontmost(), hasListeners: !listeners.isEmpty)
  {
    return Unmanaged.passUnretained(event)
  }

  let (horiz, vert) = axes(event)
  pendingH += horiz
  pendingV += vert

  let flags = event.flags
  let alt = flags.contains(.maskAlternate) ? 1 : 0
  let ctrl = flags.contains(.maskControl) ? 1 : 0

  let now = Date()
  if now.timeIntervalSince(lastFire) >= 0.03 && (pendingH != 0 || pendingV != 0) {
    lastFire = now
    notify(
      horiz: ScrollMath.invert(pendingH),
      vert: ScrollMath.invert(pendingV),
      alt: alt,
      ctrl: ctrl
    )
    pendingH = 0
    pendingV = 0
  }

  return nil
}

let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
var tap: CFMachPort?
var source: CFRunLoopSource?

func attachTap() -> Bool {
  if tap != nil {
    return true
  }
  guard
    let next = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: mask,
      callback: { _, _, event, _ in handle(event) },
      userInfo: nil
    )
  else {
    return false
  }
  tap = next
  source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, next, 0)
  CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
  CGEvent.tapEnable(tap: next, enable: true)
  return true
}

if !attachTap() {
  FileHandle.standardError.write(
    Data(
      "macscroll-worker: enable Accessibility for this binary in System Settings → Privacy & Security.\n"
        .utf8)
  )
}

Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
  _ = attachTap()
}

CFRunLoopRun()
