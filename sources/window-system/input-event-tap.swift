import Foundation

public final class InputEventTap {
  public var scrollModifiers: Hotkey.Modifiers {
    get { configuredModifiers.value }
    set { configuredModifiers.value = newValue }
  }
  public var onScroll: ((_ deltaX: Double, _ phase: ScrollGesturePhase) -> Void)?
  public var onMouse: ((TapMouseEvent) -> Void)?

  private let configuredModifiers = InputEventTapModifiers()
  private var handle: TapThreadHandle?

  public init() {}

  public var isRunning: Bool { handle != nil }

  public func start() -> Bool {
    if handle != nil { return true }
    let handle = TapThreadHandle()
    let modifiers = configuredModifiers
    let deliver: @Sendable (TapDelivery) -> Void = { [weak self] delivery in
      DispatchQueue.main.async {
        MainActor.assumeIsolated { self?.dispatch(delivery) }
      }
    }
    let thread = Thread {
      InputEventTapSession(modifiers: modifiers, deliver: deliver).run(handle: handle)
    }
    thread.name = "dev.macousel.input-tap"
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

  private func dispatch(_ delivery: TapDelivery) {
    switch delivery {
    case .scroll(let deltaX, let phase): onScroll?(deltaX, phase)
    case .mouse(let event): onMouse?(event)
    }
  }
}
