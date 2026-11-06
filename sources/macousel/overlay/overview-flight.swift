import CoreGraphics

enum OverviewFlight {
  struct Transform: Equatable {
    static let identity = Transform(offset: .zero, scale: CGSize(width: 1, height: 1))

    var offset: CGSize
    var scale: CGSize
  }

  // A parked window keeps at most a sliver on screen, so its card flies in from the screen
  // edge on its side instead of from wherever the parking spot happens to be.
  static func source(of frame: CGRect, on displayFrame: CGRect) -> CGRect {
    var local = frame.offsetBy(dx: -displayFrame.minX, dy: -displayFrame.minY)
    let bounds = CGRect(origin: .zero, size: displayFrame.size)
    let shown = local.intersection(bounds)
    guard shown.isNull || shown.width < Metrics.Overview.parkedSliver else { return local }
    local.origin.x = local.midX < bounds.midX ? bounds.minX - local.width : bounds.maxX
    return local
  }

  static func transform(from slot: CGRect, to source: CGRect) -> Transform {
    guard slot.width > 0, slot.height > 0 else { return .identity }
    return Transform(
      offset: CGSize(width: source.midX - slot.midX, height: source.midY - slot.midY),
      scale: CGSize(width: source.width / slot.width, height: source.height / slot.height))
  }
}
