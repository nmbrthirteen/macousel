import Foundation

public final class InputEventTap {
  public enum Client: Hashable, Sendable {
    case scroll, mouse
  }

  public var scrollModifiers: Hotkey.Modifiers {
    get { configuredModifiers.value }
    set { configuredModifiers.value = newValue }
  }
  public var onScroll: ((_ deltaX: Double, _ phase: ScrollGesturePhase) -> Void)?
  public var onMouse: ((TapMouseEvent) -> Void)?

  private let configuredModifiers = InputEventTapModifiers()
  private var handle: TapThreadHandle?
  // Scrolling and the pointer share one tap, so it runs while either still needs it.
  private var clients: Set<Client> = []

  public init() {}

  public var isRunning: Bool { handle != nil }

  public func start(for client: Client) -> Bool {
    let observedScroll = clients.contains(.scroll)
    clients.insert(client)
    if clients.contains(.scroll) != observedScroll { stop() }
    return start()
  }

  public func stop(for client: Client) {
    let observedScroll = clients.contains(.scroll)
    clients.remove(client)
    guard !clients.isEmpty else { return stop() }
    if clients.contains(.scroll) != observedScroll {
      stop()
      _ = start()
    }
  }

  private func start() -> Bool {
    if handle != nil { return true }
    let handle = TapThreadHandle()
    let modifiers = configuredModifiers
    let observesScroll = clients.contains(.scroll)
    let deliver: @Sendable (TapDelivery) -> Void = { [weak self] delivery in
      DispatchQueue.main.async {
        MainActor.assumeIsolated { self?.dispatch(delivery) }
      }
    }
    let thread = Thread {
      InputEventTapSession(modifiers: modifiers, observesScroll: observesScroll, deliver: deliver)
        .run(handle: handle)
    }
    thread.name = "dev.macousel.input-tap"
    thread.qualityOfService = .userInteractive
    thread.start()
    guard handle.awaitStart() else { return false }
    self.handle = handle
    return true
  }

  private func stop() {
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
