import CoreGraphics
import StripCore

extension OverviewModel {
  func pressed(at point: CGPoint, in size: CGSize) {
    let geometry = OverviewGeometry(snapshot: snapshot, size: size)
    let press: OverviewInteraction.Press
    if let edge = geometry.hitAreas.edge(at: point) {
      press = .edge(edge)
    } else if let divider = geometry.hitAreas.divider(at: point) {
      press = .divider(divider)
    } else if let card = geometry.cards.first(where: { $0.rect.contains(point) }) {
      press = .card(card.id)
    } else {
      press = .backdrop
    }
    interaction = .pressed(press, origin: point)
  }

  private var isAwaitingMovement: Bool {
    if case .pressed = interaction { return true }
    return false
  }

  func dragged(to point: CGPoint, in size: CGSize) {
    switch interaction {
    case .pressed(let press, let origin):
      guard hypot(point.x - origin.x, point.y - origin.y) > Metrics.Overview.dragThreshold else {
        return
      }
      interaction = begin(press, from: origin, size: size)
      dragged(to: point, in: size)
    case .movingCard(let drag):
      moveCard(drag, to: point, size: size)
    case .resizingColumn(let session):
      resizeColumn(session, to: point)
    case .resizingRows(let session):
      resizeRows(session, to: point)
    case .idle:
      break
    }
  }

  func released(at point: CGPoint, in size: CGSize) {
    if !isAwaitingMovement { dragged(to: point, in: size) }
    let ended = interaction
    endInteraction()
    switch ended {
    case .pressed(.card(let window), _):
      onSelect(window)
    case .pressed(.backdrop, _):
      onDismiss()
    case .movingCard(let drag) where drag.target != .nowhere:
      onMove(drag.window, drag.target)
    case .resizingColumn(let session) where session.hasChanged:
      onColumnWidth(session.window, session.current.fraction)
    case .resizingRows(let session) where session.upperShare != session.resize.upperShare:
      onRowHeight(session.divider.upper, session.upperShare, .below)
    default:
      break
    }
  }

  private func begin(
    _ press: OverviewInteraction.Press, from origin: CGPoint, size: CGSize
  ) -> OverviewInteraction {
    let geometry = OverviewGeometry(snapshot: snapshot, size: size)
    switch press {
    case .card(let window):
      guard let card = geometry.cards.first(where: { $0.id == window }) else { return .idle }
      let grab = CGVector(dx: origin.x - card.rect.minX, dy: origin.y - card.rect.minY)
      return .movingCard(
        .init(window: window, grab: grab, size: card.rect.size, target: .nowhere))
    case .edge(let edge):
      let resize = OverviewColumnResize(
        column: snapshot.columns[edge.column], scale: geometry.scale, snapshot: snapshot)
      guard resize.isResolvable else { return .idle }
      return .resizingColumn(
        .init(
          window: edge.window, column: edge.column, origin: origin, resize: resize,
          current: resize.resolve(translation: 0)))
    case .divider(let divider):
      return .resizingRows(rowResize(for: divider, origin: origin, geometry: geometry))
    case .backdrop:
      return .idle
    }
  }

  private func rowResize(
    for divider: OverviewHitAreas.Divider, origin: CGPoint, geometry: OverviewGeometry
  ) -> OverviewInteraction.RowResize {
    let cards = snapshot.columns[divider.column].cards
    let share = { (window: WindowID) in cards.first { $0.window == window }?.heightShare ?? 0 }
    let height = geometry.cards.filter { $0.column == divider.column }.reduce(0) {
      $0 + $1.rect.height
    }
    let resize = OverviewRowResize(
      upperShare: share(divider.upper), lowerShare: share(divider.lower), columnHeight: height)
    return .init(divider: divider, origin: origin, resize: resize, upperShare: resize.upperShare)
  }

  private func moveCard(_ drag: OverviewInteraction.CardDrag, to point: CGPoint, size: CGSize) {
    let geometry = OverviewGeometry(snapshot: snapshot, size: size)
    var next = drag
    next.target = OverviewDropTargeting(snapshot: snapshot, geometry: geometry)
      .target(dragging: drag.window, at: point)
    interaction = .movingCard(next)
    let origin = CGPoint(x: point.x - drag.grab.dx, y: point.y - drag.grab.dy)
    setArrangement(
      OverviewArrangement(snapshot: snapshot).applying(next.target, moving: drag.window),
      lift: Lift(window: drag.window, rect: CGRect(origin: origin, size: drag.size)))
  }

  private func resizeColumn(_ session: OverviewInteraction.ColumnResize, to point: CGPoint) {
    var next = session
    next.current = session.resize.resolve(translation: point.x - session.origin.x)
    interaction = .resizingColumn(next)
    var arranged = snapshot
    arranged.columns[session.column].width = next.current.width
    setArrangement(
      arranged, lift: nil,
      label: ResizeLabel(
        window: session.window, text: OverviewColumnResize.label(for: next.current.fraction)))
  }

  private func resizeRows(_ session: OverviewInteraction.RowResize, to point: CGPoint) {
    let shares = session.resize.resolve(translation: point.y - session.origin.y)
    var next = session
    next.upperShare = shares.upper
    interaction = .resizingRows(next)
    var arranged = snapshot
    for index in arranged.columns[session.divider.column].cards.indices {
      let window = arranged.columns[session.divider.column].cards[index].window
      if window == session.divider.upper {
        arranged.columns[session.divider.column].cards[index].heightShare = shares.upper
      } else if window == session.divider.lower {
        arranged.columns[session.divider.column].cards[index].heightShare = shares.lower
      }
    }
    setArrangement(arranged, lift: nil, divider: session.divider.upper)
  }
}
