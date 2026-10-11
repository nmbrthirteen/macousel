import AppKit

public final class EnvironmentObserver {
  public var onDisplaysChanged: (() -> Void)?
  public var onSpaceChanged: (() -> Void)?

  private var tokens: [(center: NotificationCenter, token: NSObjectProtocol)] = []

  public init() {}

  public func start() {
    guard tokens.isEmpty else { return }
    let displays = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated { self?.onDisplaysChanged?() }
    }
    let workspaceCenter = NSWorkspace.shared.notificationCenter
    let spaces = workspaceCenter.addObserver(
      forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated { self?.onSpaceChanged?() }
    }
    tokens = [(NotificationCenter.default, displays), (workspaceCenter, spaces)]
  }

  public func stop() {
    for entry in tokens { entry.center.removeObserver(entry.token) }
    tokens = []
  }
}
