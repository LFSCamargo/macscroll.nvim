public enum ScrollMath {
  public static func preferredAxis(point: Double, fixed: Double, line: Double) -> Double {
    if point != 0 {
      return point
    }
    if fixed != 0 {
      return fixed
    }
    return line
  }

  public static func invert(_ pending: Double) -> Int {
    if pending > 0 {
      return -1
    }
    if pending < 0 {
      return 1
    }
    return 0
  }

  public static func clampDir(_ value: Int) -> Int {
    if value == 0 {
      return 0
    }
    return value > 0 ? 1 : -1
  }
}

public enum EventPolicy {
  /// Swallow the CGEvent so the TTY cannot filter or rewrite it.
  public static func swallow(terminalFrontmost: Bool, hasListeners: Bool) -> Bool {
    terminalFrontmost && hasListeners
  }
}

public enum RPC {
  public static func remoteExpr(horiz: Int, vert: Int, alt: Int, ctrl: Int) -> String {
    let h = ScrollMath.clampDir(horiz)
    let v = ScrollMath.clampDir(vert)
    return "luaeval(\"require('macscroll').scroll(\(h),\(v),\(alt),\(ctrl))\")"
  }
}
