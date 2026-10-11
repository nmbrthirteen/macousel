import WindowSystem

final class EngineMinimap {
  var onSelect: ((Int) -> Void)?

  private let host: any OverlayHost
  private let store: PreferencesStore
  private let displays: () -> [Display]
  private var shown: EngineSnapshot?

  init(host: any OverlayHost, store: PreferencesStore, displays: @escaping () -> [Display]) {
    self.host = host
    self.store = store
    self.displays = displays
    host.onMinimapSelect = { [weak self] window in
      guard let column = self?.shown?.columnIndex(of: window) else { return }
      self?.onSelect?(column)
    }
  }

  func flash(_ snapshot: EngineSnapshot) {
    guard store.preferences.showsMinimap, let content = EngineMinimapBuilder(snapshot: snapshot).build(),
      let display = snapshot.display(in: displays())
    else {
      hide()
      return
    }
    shown = snapshot
    host.showMinimap(content, update: .animated, on: display.visibleFrame)
  }

  func hide() {
    shown = nil
    host.hideMinimap()
  }
}
