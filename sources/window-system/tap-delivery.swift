nonisolated enum TapDelivery: Sendable, Equatable {
  case scroll(deltaX: Double, phase: ScrollGesturePhase)
  case mouse(TapMouseEvent)
}
