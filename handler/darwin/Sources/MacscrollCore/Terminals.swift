import Foundation

public enum Terminals {
  public static let bundledIds: Set<String> = [
    "dev.warp.Warp-Stable",
    "dev.warp.Warp",
    "dev.warp.Warp-Preview",
    "com.apple.Terminal",
    "com.googlecode.iterm2",
    "net.kovidgoyal.kitty",
    "com.mitchellh.ghostty",
    "com.github.wez.wezterm",
    "org.alacritty",
    "io.alacritty",
    "co.zeit.hyper",
    "com.googlecode.iterm2.iTerm2",
  ]

  public static func extraIds(from env: String) -> Set<String> {
    Set(
      env.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    )
  }

  public static func isKnown(_ id: String, extra: Set<String> = []) -> Bool {
    bundledIds.contains(id) || extra.contains(id)
  }
}
