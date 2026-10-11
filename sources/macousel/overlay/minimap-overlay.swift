import AppKit
import SwiftUI

struct MinimapSnapshot: Equatable {
  struct Column: Equatable {
    var x: Double
    var width: Double
    var rowShares: [Double]
    var isFocused: Bool
  }
  var columns: [Column]
  var contentWidth: Double
  var viewportOffset: Double
  var viewportWidth: Double
}

@Observable
final class MinimapModel {
  var snapshot = MinimapSnapshot(columns: [], contentWidth: 0, viewportOffset: 0, viewportWidth: 0)
}

final class MinimapOverlay {
  private static let size = CGSize(width: 280, height: 48)
  private static let bottomInset = Metrics.Spacing.spacious

  private let model = MinimapModel()
  private let panel: OverlayPanel
  private var hideTask: Task<Void, Never>?
  private var lastDisplayFrame: CGRect?

  init() {
    panel = OverlayPanel(content: MinimapView(model: model), interactive: false)
  }

  func show(_ snapshot: MinimapSnapshot, on displayFrame: CGRect) {
    if snapshot != model.snapshot { model.snapshot = snapshot }
    if displayFrame != lastDisplayFrame {
      lastDisplayFrame = displayFrame
      let axFrame = CGRect(
        x: displayFrame.midX - Self.size.width / 2,
        y: displayFrame.maxY - Self.bottomInset - Self.size.height,
        width: Self.size.width, height: Self.size.height)
      panel.setFrame(axFrame.axToCocoa, display: true)
    }
    panel.present(fadeDuration: OverlayTiming.fade)

    hideTask?.cancel()
    hideTask = Task { [weak self] in
      try? await Task.sleep(for: OverlayTiming.minimapLinger)
      guard !Task.isCancelled else { return }
      self?.panel.dismiss(fadeDuration: OverlayTiming.slowFade)
    }
  }

  func hide() {
    hideTask?.cancel()
    hideTask = nil
    panel.dismiss(fadeDuration: 0)
  }
}

struct MinimapView: View {
  let model: MinimapModel

  private static let padding = Metrics.Spacing.regular + Metrics.Spacing.hairline
  private static let columnGap = 1.5

  var body: some View {
    Canvas { context, size in
      draw(model.snapshot, in: context, size: size)
    }
    .padding(Self.padding)
    .overlaySurface(in: RoundedRectangle(cornerRadius: Metrics.Radius.panel))
    .accessibilityHidden(true)
  }

  private func draw(_ snapshot: MinimapSnapshot, in context: GraphicsContext, size: CGSize) {
    let start = min(0, snapshot.viewportOffset)
    let end = max(snapshot.contentWidth, snapshot.viewportOffset + snapshot.viewportWidth)
    let span = end - start
    guard span > 0 else { return }
    let scale = size.width / span

    for column in snapshot.columns {
      let x = (column.x - start) * scale
      let width = max(column.width * scale - Self.columnGap, 1)
      let shares = column.rowShares.isEmpty ? [1] : column.rowShares
      let total = shares.reduce(0, +)
      guard total > 0 else { continue }
      let usableHeight = size.height - Self.columnGap * Double(shares.count - 1)
      let color: Color = column.isFocused ? .accentColor : .primary.opacity(0.3)

      var y = 0.0
      for share in shares {
        let height = max(usableHeight * share / total, 1)
        let rect = CGRect(x: x, y: y, width: width, height: height)
        context.fill(Path(roundedRect: rect, cornerRadius: Metrics.Radius.column), with: .color(color))
        y += height + Self.columnGap
      }
    }

    let viewport = CGRect(
      x: (snapshot.viewportOffset - start) * scale, y: 0,
      width: snapshot.viewportWidth * scale, height: size.height)
    context.stroke(
      Path(roundedRect: viewport.insetBy(dx: 0.5, dy: 0.5), cornerRadius: Metrics.Radius.viewport),
      with: .color(.primary), lineWidth: Metrics.Size.outlineStroke)
  }
}
