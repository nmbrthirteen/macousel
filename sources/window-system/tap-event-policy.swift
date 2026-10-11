import Foundation

nonisolated struct TapEventPolicy {
  static let minimumDraggedInterval: TimeInterval = 1.0 / 60

  private var lastDeliveredDrag: TimeInterval?

  mutating func verdict(for input: TapInput, scrollModifiers: Hotkey.Modifiers) -> TapVerdict {
    switch input {
    case .scroll(let flags, let momentumPhase, let scrollPhase, let horizontal, let vertical):
      return scrollVerdict(
        ScrollEventClassifier(modifiers: scrollModifiers).decision(
          flags: flags, momentumPhase: momentumPhase, scrollPhase: scrollPhase,
          horizontalDelta: horizontal, verticalDelta: vertical))
    case .mouse(let kind, let location, let timestamp):
      return mouseVerdict(kind: kind, location: location, timestamp: timestamp)
    }
  }

  private func scrollVerdict(_ decision: ScrollEventDecision) -> TapVerdict {
    switch decision {
    case .passThrough:
      return .ignored
    case .swallow:
      return TapVerdict(swallows: true, delivery: nil)
    case .deliver(let deltaX, let phase):
      return TapVerdict(swallows: true, delivery: .scroll(deltaX: deltaX, phase: phase))
    }
  }

  private mutating func mouseVerdict(
    kind: TapMouseEvent.Kind, location: CGPoint, timestamp: TimeInterval
  ) -> TapVerdict {
    if kind == .dragged {
      if let last = lastDeliveredDrag, timestamp - last < Self.minimumDraggedInterval {
        return .ignored
      }
      lastDeliveredDrag = timestamp
    } else {
      lastDeliveredDrag = nil
    }
    return TapVerdict(
      swallows: false, delivery: .mouse(TapMouseEvent(kind: kind, location: location)))
  }
}
