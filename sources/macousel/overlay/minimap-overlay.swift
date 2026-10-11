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
  private static let numberFontSize = 9.0
  private static let restingColumnOpacity = 0.3

  var body: some View {
    GeometryReader { proxy in
      let geometry = MinimapGeometry(snapshot: model.snapshot, size: proxy.size)
      ZStack(alignment: .topLeading) {
        ForEach(geometry.cells) { cell in
          RoundedRectangle(cornerRadius: Metrics.Radius.column)
            .fill(cell.isFocused ? Color.accentColor : Color.primary.opacity(Self.restingColumnOpacity))
            .frame(width: cell.rect.width, height: cell.rect.height)
            .offset(x: cell.rect.minX, y: cell.rect.minY)
        }
        ForEach(geometry.labels) { label in
          Text("\(label.number)")
            .font(
              .system(size: Self.numberFontSize, weight: .semibold, design: .rounded)
                .monospacedDigit()
            )
            .foregroundStyle(Color.primary)
            .position(label.center)
        }
        RoundedRectangle(cornerRadius: Metrics.Radius.viewport)
          .strokeBorder(Color.primary, lineWidth: Metrics.Size.outlineStroke)
          .frame(width: geometry.viewport.width, height: geometry.viewport.height)
          .offset(x: geometry.viewport.minX, y: geometry.viewport.minY)
      }
    }
    .padding(Self.padding)
    .overlaySurface(in: RoundedRectangle(cornerRadius: Metrics.Radius.panel))
    .accessibilityHidden(true)
  }
}
