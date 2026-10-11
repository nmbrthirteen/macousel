import Foundation

public final class ScrollGestureTap {
  public nonisolated enum Phase: Sendable { case began, changed, ended }

  public var modifiers: Hotkey.Modifiers {
    get { configuredModifiers.value }
    set { configuredModifiers.value = newValue }
  }
  public var onScroll: ((_ deltaX: Double, _ phase: Phase) -> Void)?

  private let configuredModifiers = ScrollTapModifiers()
  private var handle: TapThreadHandle?

  public init() {}

  public func start() -> Bool {
    if handle != nil { return true }
    let handle = TapThreadHandle()
    let modifiers = configuredModifiers
    let deliver: @Sendable (Double, Phase) -> Void = { [weak self] deltaX, phase in
      DispatchQueue.main.async {
        MainActor.assumeIsolated { self?.onScroll?(deltaX, phase) }
      }
    }
    let thread = Thread {
      ScrollTapSession(modifiers: modifiers, deliver: deliver).run(handle: handle)
    }
    thread.name = "dev.macousel.scroll-tap"
    thread.qualityOfService = .userInteractive
    thread.start()
    guard handle.awaitStart() else { return false }
    self.handle = handle
    return true
  }

  public func stop() {
    guard let handle else { return }
    self.handle = nil
    handle.stopAndWait()
  }
}
