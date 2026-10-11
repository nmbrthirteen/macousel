import StripCore

final class AppShortcutLauncher {
  private let state: TilingState
  private let source: any WindowSource
  private let environment: any DesktopEnvironment
  private let recents: RecentAppWindows
  private let router: CommandRouter

  init(
    state: TilingState, source: any WindowSource, environment: any DesktopEnvironment,
    recents: RecentAppWindows, router: CommandRouter
  ) {
    self.state = state
    self.source = source
    self.environment = environment
    self.recents = recents
    self.router = router
  }

  func jump(to bundleIdentifier: String) {
    router.closeOverview()
    let windows = tiledWindows(of: bundleIdentifier)
    guard let first = windows.first else {
      environment.activateOrLaunch(bundleIdentifier: bundleIdentifier)
      return
    }
    router.reveal(target(among: windows, bundleIdentifier: bundleIdentifier) ?? first)
  }

  private func target(among windows: [WindowID], bundleIdentifier: String) -> WindowID? {
    if let current = focusedWindow, let index = windows.firstIndex(of: current) {
      return windows[(index + 1) % windows.count]
    }
    return recents.window(for: bundleIdentifier).flatMap { windows.contains($0) ? $0 : nil }
  }

  private var focusedWindow: WindowID? {
    guard let key = state.focusedKey ?? state.pointerKey,
      let window = state.workspaces[key]?.strip.focusedWindow,
      source.window(window.rawValue)?.pid == environment.frontmostProcessID
    else { return nil }
    return window
  }

  private func tiledWindows(of bundleIdentifier: String) -> [WindowID] {
    let leftToRight = state.tiledDisplays.sorted { $0.frame.minX < $1.frame.minX }
    return leftToRight.compactMap(state.activeKey(for:)).flatMap { key in
      (state.workspaces[key]?.strip.windows ?? []).filter {
        source.window($0.rawValue)?.bundleIdentifier == bundleIdentifier
      }
    }
  }
}
