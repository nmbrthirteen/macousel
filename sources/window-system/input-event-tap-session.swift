import CoreGraphics
import Foundation
import os

private nonisolated let logger = Logger(
  subsystem: "dev.macousel.app", category: "input-event-tap")

private nonisolated func inputTapCallback(
  _ proxy: CGEventTapProxy, _ type: CGEventType, _ event: CGEvent,
  _ refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  guard let refcon else { return Unmanaged.passUnretained(event) }
  let session = Unmanaged<InputEventTapSession>.fromOpaque(refcon).takeUnretainedValue()
  return session.shouldSwallow(type: type, event: event) ? nil : Unmanaged.passUnretained(event)
}

nonisolated final class InputEventTapSession {
  private static let nanosecondsPerSecond = 1e9
  private static let observedTypes: [CGEventType] = [
    .scrollWheel, .leftMouseDown, .leftMouseDragged, .leftMouseUp,
  ]

  private let modifiers: InputEventTapModifiers
  private let deliver: @Sendable (TapDelivery) -> Void
  private var policy = TapEventPolicy()
  private var port: CFMachPort?

  init(modifiers: InputEventTapModifiers, deliver: @escaping @Sendable (TapDelivery) -> Void) {
    self.modifiers = modifiers
    self.deliver = deliver
  }

  func run(handle: TapThreadHandle) {
    let mask = Self.observedTypes.reduce(CGEventMask(0)) {
      (mask: CGEventMask, type: CGEventType) -> CGEventMask in
      mask | (CGEventMask(1) << type.rawValue)
    }
    guard
      let port = CGEvent.tapCreate(
        tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: mask, callback: inputTapCallback,
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
    guard let input = input(for: type, event: event) else {
      if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput, let port {
        CGEvent.tapEnable(tap: port, enable: true)
      }
      return false
    }
    let verdict = policy.verdict(for: input, scrollModifiers: modifiers.value)
    if let delivery = verdict.delivery { deliver(delivery) }
    return verdict.swallows
  }

  private func input(for type: CGEventType, event: CGEvent) -> TapInput? {
    switch type {
    case .scrollWheel:
      return .scroll(
        flags: event.flags,
        momentumPhase: event.getIntegerValueField(.scrollWheelEventMomentumPhase),
        scrollPhase: event.getIntegerValueField(.scrollWheelEventScrollPhase),
        horizontalDelta: event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2),
        verticalDelta: event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1))
    case .leftMouseDown:
      return mouseInput(.pressed, event)
    case .leftMouseDragged:
      return mouseInput(.dragged, event)
    case .leftMouseUp:
      return mouseInput(.released, event)
    default:
      return nil
    }
  }

  private func mouseInput(_ kind: TapMouseEvent.Kind, _ event: CGEvent) -> TapInput {
    .mouse(
      kind: kind, location: event.location,
      timestamp: TimeInterval(event.timestamp) / Self.nanosecondsPerSecond)
  }
}
