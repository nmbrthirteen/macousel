import CoreGraphics
import os

private nonisolated let logger = Logger(
  subsystem: "dev.macousel.app", category: "scroll-gesture-tap")

private nonisolated func scrollTapCallback(
  _ proxy: CGEventTapProxy, _ type: CGEventType, _ event: CGEvent,
  _ refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  guard let refcon else { return Unmanaged.passUnretained(event) }
  let session = Unmanaged<ScrollTapSession>.fromOpaque(refcon).takeUnretainedValue()
  return session.shouldSwallow(type: type, event: event) ? nil : Unmanaged.passUnretained(event)
}

nonisolated final class ScrollTapSession {
  private let modifiers: ScrollTapModifiers
  private let deliver: @Sendable (Double, ScrollGestureTap.Phase) -> Void
  private var port: CFMachPort?

  init(
    modifiers: ScrollTapModifiers,
    deliver: @escaping @Sendable (Double, ScrollGestureTap.Phase) -> Void
  ) {
    self.modifiers = modifiers
    self.deliver = deliver
  }

  func run(handle: TapThreadHandle) {
    let mask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
    guard
      let port = CGEvent.tapCreate(
        tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: mask, callback: scrollTapCallback,
        userInfo: Unmanaged.passUnretained(self).toOpaque())
    else {
      logger.error("CGEvent.tapCreate failed, Accessibility permission is probably missing")
      handle.publish(runLoop: nil)
      return
    }
    self.port = port
    let runLoop = CFRunLoopGetCurrent()
    let source = CFMachPortCreateRunLoopSource(nil, port, 0)
    CFRunLoopAddSource(runLoop, source, .commonModes)
    CGEvent.tapEnable(tap: port, enable: true)
    handle.publish(runLoop: runLoop)

    CFRunLoopRun()

    CGEvent.tapEnable(tap: port, enable: false)
    CFRunLoopRemoveSource(runLoop, source, .commonModes)
    CFMachPortInvalidate(port)
    self.port = nil
    handle.finish()
  }

  fileprivate func shouldSwallow(type: CGEventType, event: CGEvent) -> Bool {
    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
      if let port { CGEvent.tapEnable(tap: port, enable: true) }
      return false
    case .scrollWheel:
      break
    default:
      return false
    }

    let decision = ScrollEventClassifier(modifiers: modifiers.value).decision(
      flags: event.flags,
      momentumPhase: event.getIntegerValueField(.scrollWheelEventMomentumPhase),
      scrollPhase: event.getIntegerValueField(.scrollWheelEventScrollPhase),
      horizontalDelta: event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2),
      verticalDelta: event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1))
    switch decision {
    case .passThrough:
      return false
    case .swallow:
      return true
    case .deliver(let deltaX, let phase):
      deliver(deltaX, phase)
      return true
    }
  }
}
