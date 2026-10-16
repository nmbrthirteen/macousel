import AppKit
import CoreGraphics
import WindowSystem

private nonisolated func practiceTapCallback(
  _ proxy: CGEventTapProxy, _ type: CGEventType, _ event: CGEvent,
  _ refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  // The tap's source is on the main run loop, so this already runs on the main thread and
  // assumeIsolated checks it. The event and pointer never leave that thread.
  nonisolated(unsafe) let event = event
  nonisolated(unsafe) let refcon = refcon
  MainActor.assumeIsolated {
    guard let refcon else { return }
    Unmanaged<PracticeKeyTap>.fromOpaque(refcon).takeUnretainedValue().handle(
      type: type, event: event)
  }
  return Unmanaged.passUnretained(event)
}

// Paneru consumes its shortcuts in a HID-level tap, so an NSEvent monitor never sees them.
// A later head-insert tap sits ahead of it. An active tap needs only Accessibility, while a
// listen-only keyboard tap would need Input Monitoring. The callback never alters the event.
final class PracticeKeyTap {
  private var port: CFMachPort?
  private var source: CFRunLoopSource?
  private var onHotkey: ((Hotkey) -> Void)?

  func start(_ onHotkey: @escaping (Hotkey) -> Void) {
    stop()
    let mask = CGEventMask(1) << CGEventType.keyDown.rawValue
    guard
      let port = CGEvent.tapCreate(
        tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: mask, callback: practiceTapCallback,
        userInfo: Unmanaged.passUnretained(self).toOpaque())
    else { return }
    let source = CFMachPortCreateRunLoopSource(nil, port, 0)
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    CGEvent.tapEnable(tap: port, enable: true)
    self.port = port
    self.source = source
    self.onHotkey = onHotkey
  }

  func stop() {
    guard let port, let source else { return }
    CGEvent.tapEnable(tap: port, enable: false)
    CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
    CFMachPortInvalidate(port)
    self.port = nil
    self.source = nil
    onHotkey = nil
  }

  fileprivate func handle(type: CGEventType, event: CGEvent) {
    switch type {
    case .keyDown:
      guard let nsEvent = NSEvent(cgEvent: event), !nsEvent.isARepeat,
        let hotkey = Hotkey(event: nsEvent)
      else { return }
      onHotkey?(hotkey)
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
      if let port { CGEvent.tapEnable(tap: port, enable: true) }
    default:
      break
    }
  }
}
