import AppKit
import StripCore
import SwiftUI

struct TabBarModel: Equatable, Identifiable {
  struct Tab: Equatable, Identifiable {
    var id: WindowID
    var title: String
    var isActive: Bool
  }

  var id: WindowID
  var frame: CGRect
  var tabs: [Tab]
}

@Observable
final class TabBarContent {
  var tabs: [TabBarModel.Tab] = []
  @ObservationIgnored var onSelect: (WindowID) -> Void = { _ in }
}

final class TabBarOverlay {
  private struct Entry {
    let panel: OverlayPanel
    let content: TabBarContent
    var model: TabBarModel
  }

  var onSelect: ((WindowID) -> Void)?
  private var entries: [WindowID: Entry] = [:]

  init() {}

  func update(_ bars: [TabBarModel]) {
    let liveIDs = Set(bars.map(\.id))
    for id in entries.keys where !liveIDs.contains(id) {
      entries.removeValue(forKey: id)?.panel.orderOut(nil)
    }

    for bar in bars {
      if var entry = entries[bar.id] {
        guard entry.model != bar else { continue }
        apply(bar, to: &entry)
        entries[bar.id] = entry
      } else {
        var entry = makeEntry(for: bar)
        apply(bar, to: &entry)
        entries[bar.id] = entry
        entry.panel.present(fadeDuration: 0)
      }
    }
  }

  private func makeEntry(for bar: TabBarModel) -> Entry {
    let content = TabBarContent()
    content.onSelect = { [weak self] id in self?.onSelect?(id) }
    let panel = OverlayPanel(content: TabBarView(content: content), interactive: true)
    return Entry(panel: panel, content: content, model: bar)
  }

  private func apply(_ bar: TabBarModel, to entry: inout Entry) {
    if bar.frame != entry.model.frame || entry.panel.frame == .zero {
      let cocoaFrame = bar.frame.axToCocoa
      if entry.panel.frame.size == cocoaFrame.size {
        entry.panel.setFrameOrigin(cocoaFrame.origin)
      } else {
        entry.panel.setFrame(cocoaFrame, display: true)
      }
    }
    if bar.tabs != entry.content.tabs { entry.content.tabs = bar.tabs }
    entry.model = bar
  }
}

struct TabBarView: View {
  let content: TabBarContent

  var body: some View {
    HStack(spacing: Metrics.Spacing.hairline) {
      ForEach(content.tabs) { tab in
        Text(tab.title)
          .font(.callout)
          .lineLimit(1)
          .truncationMode(.middle)
          .foregroundStyle(tab.isActive ? Color.primary : Color.secondary)
          .padding(.horizontal, Metrics.Spacing.regular)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(
            tab.isActive ? Color.accentColor.opacity(Metrics.Opacity.activeTab) : .clear,
            in: Capsule()
          )
          .contentShape(Rectangle())
          .onTapGesture { content.onSelect(tab.id) }
          .accessibilityAddTraits(tab.isActive ? [.isButton, .isSelected] : .isButton)
      }
    }
    .padding(Metrics.Spacing.hairline)
    .overlaySurface(in: Capsule())
  }
}
