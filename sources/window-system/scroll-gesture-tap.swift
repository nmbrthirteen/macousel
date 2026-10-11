import AppKit
import CoreGraphics
import os

private let logger = Logger(subsystem: "dev.macousel.app", category: "scroll-gesture-tap")

private nonisolated func scrollTapCallback(
  _ proxy: CGEventTapProxy, _ type: CGEventType, _ event: CGEvent,
  _ refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  guard let refcon else { return Unmanaged.passUnretained(event) }
  let address = Int(bitPattern: refcon)
  nonisolated(unsafe) let tapEvent = event
  let swallow = MainActor.assumeIsolated {
    guard let pointer = UnsafeMutableRawPointer(bitPattern: address) else { return false }
    return Unmanaged<ScrollGestureTap>.fromOpaque(pointer).takeUnretainedValue().handle(
      type: type, event: tapEvent)
  }
  return swallow ? nil : Unmanaged.passUnretained(event)
}

public final class ScrollGestureTap {
  public enum Phase: Sendable { case began, changed, ended }

  public var modifiers: Hotkey.Modifiers = []
  public var onScroll: ((_ deltaX: Double, _ phase: Phase) -> Void)?

  private var port: CFMachPort?
  private var source: CFRunLoopSource?

  public init() {}

  public func start() -> Bool {
    if port != nil { return true }
    let mask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
    guard
      let port = CGEvent.tapCreate(
        tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: mask, callback: scrollTapCallback,
        userInfo: Unmanaged.passUnretained(self).toOpaque())
    else {
      logger.error("CGEvent.tapCreate failed, Accessibility permission is probably missing")
      return false
    }
    let source = CFMachPortCreateRunLoopSource(nil, port, 0)
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    CGEvent.tapEnable(tap: port, enable: true)
    self.port = port
    self.source = source
    return true
  }

  public func stop() {
    guard let port else { return }
    CGEvent.tapEnable(tap: port, enable: false)
    if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
    CFMachPortInvalidate(port)
    self.port = nil
    source = nil
  }

  fileprivate func handle(type: CGEventType, event: CGEvent) -> Bool {
    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
      if let port { CGEvent.tapEnable(tap: port, enable: true) }
      return false
    case .scrollWheel:
      break
    default:
      return false
    }

    guard !modifiers.isEmpty, Self.modifiers(of: event.flags) == modifiers else { return false }

    if event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0 { return true }

    let phase: Phase
    switch NSEvent.Phase(rawValue: UInt(event.getIntegerValueField(.scrollWheelEventScrollPhase)))
    {
    case .began: phase = .began
    case .ended, .cancelled: phase = .ended
    case .mayBegin: return true
    default: phase = .changed
    }

    var delta = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)
    if delta == 0 { delta = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1) }
    onScroll?(delta, phase)
    return true
  }

  private static func modifiers(of flags: CGEventFlags) -> Hotkey.Modifiers {
    var result: Hotkey.Modifiers = []
    if flags.contains(.maskControl) { result.insert(.control) }
    if flags.contains(.maskAlternate) { result.insert(.option) }
    if flags.contains(.maskShift) { result.insert(.shift) }
    if flags.contains(.maskCommand) { result.insert(.command) }
    return result
  }
}
