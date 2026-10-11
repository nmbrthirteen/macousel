import AppKit
import StripCore

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
