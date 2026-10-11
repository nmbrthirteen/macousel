import AppKit
import CoreGraphics

nonisolated enum ScrollEventDecision: Equatable {
  case passThrough
  case swallow
  case deliver(deltaX: Double, phase: ScrollGesturePhase)
}

nonisolated struct ScrollEventClassifier {
  let modifiers: Hotkey.Modifiers

  func decision(
    flags: CGEventFlags, momentumPhase: Int64, scrollPhase: Int64, horizontalDelta: Double,
    verticalDelta: Double
  ) -> ScrollEventDecision {
    guard !modifiers.isEmpty, Self.modifiers(of: flags) == modifiers else { return .passThrough }
    if momentumPhase != 0 { return .swallow }

    let phase: ScrollGesturePhase
    switch NSEvent.Phase(rawValue: UInt(scrollPhase)) {
    case .began: phase = .began
    case .ended, .cancelled: phase = .ended
    case .mayBegin: return .swallow
    default: phase = .changed
    }
    return .deliver(deltaX: horizontalDelta == 0 ? verticalDelta : horizontalDelta, phase: phase)
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
