import Foundation

public enum SocketName {
  public static func isSafe(_ name: String) -> Bool {
    let parts = name.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 2, parts[1] == "sock", !parts[0].isEmpty else {
      return false
    }
    return parts[0].allSatisfy(\.isNumber)
  }

  public static func directories(stateHomes: [URL], appname: String) -> [URL] {
    let app = appname.isEmpty ? "nvim" : appname
    return stateHomes.map {
      $0.appendingPathComponent(app, isDirectory: true)
        .appendingPathComponent("macscroll", isDirectory: true)
    }
  }
}
