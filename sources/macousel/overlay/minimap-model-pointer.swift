import CoreGraphics
import StripCore

extension MinimapModel {
  func pressed(at point: CGPoint) {
    guard let cell = MinimapGeometry(snapshot: snapshot).cell(at: point) else {
      interaction = .idle
      return
    }
    interaction = .pressed(window: cell.window, origin: point)
  }

  func dragged(to point: CGPoint) {
    switch interaction {
    case .pressed(let window, let origin):
      guard hypot(point.x - origin.x, point.y - origin.y) > Metrics.Overlay.dragThreshold else {
        return
      }
      interaction = begin(window, from: origin)
      dragged(to: point)
    case .dragging(let drag):
      move(drag, to: point)
    case .idle:
      break
    }
  }

  func released(at point: CGPoint) {
    if case .dragging = interaction { dragged(to: point) }
    let ended = interaction
    interaction = .idle
    setArrangement(arrangement, lift: nil)
    switch ended {
    case .pressed(let window, _):
      onSelect(window)
    case .dragging(let drag) where drag.target != .nowhere:
      onMove(drag.window, drag.target)
    default:
      break
    }
    finishInteraction(pointerIsInside: MinimapGeometry(snapshot: snapshot).bounds.contains(point))
  }

  private func begin(_ window: WindowID, from origin: CGPoint) -> MinimapInteraction {
    guard let cell = MinimapGeometry(snapshot: snapshot).cells.first(where: { $0.window == window })
    else { return .idle }
    return .dragging(
      .init(
        window: window, cell: cell.id,
        grab: CGVector(dx: origin.x - cell.rect.minX, dy: origin.y - cell.rect.minY),
        target: .nowhere))
  }

  private func move(_ drag: MinimapInteraction.Drag, to point: CGPoint) {
    let geometry = MinimapGeometry(snapshot: snapshot)
    guard let cell = geometry.cells.first(where: { $0.id == drag.cell }) else { return }
    var next = drag
    next.target = MinimapDropTargeting(snapshot: snapshot, geometry: geometry)
      .target(dragging: drag.window, at: point)
    interaction = .dragging(next)
    let slack = geometry.containerWidth - cell.rect.width
    let left = min(max(point.x - drag.grab.dx, 0), max(slack, 0))
    setArrangement(
      MinimapArrangement(snapshot: snapshot).applying(next.target, moving: drag.window),
      lift: Lift(cell: drag.cell, offset: left - cell.rect.minX))
  }
}
