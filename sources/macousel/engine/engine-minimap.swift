import StripCore
import WindowSystem

final class EngineMinimap {
  private let host: any OverlayHost
  private let store: PreferencesStore
  private let displays: () -> [Display]
  private let reorder: EngineReorder

  init(
    host: any OverlayHost, store: PreferencesStore, displays: @escaping () -> [Display],
    reorder: EngineReorder
  ) {
    self.host = host
    self.store = store
    self.displays = displays
    self.reorder = reorder
    host.onMinimapSelect = { [weak self] window in self?.select(window) }
    host.onMinimapMove = { [weak self] window, target in self?.drop(window, on: target) }
  }

  func flash(_ snapshot: EngineSnapshot) {
    guard store.preferences.showsMinimap, let display = snapshot.display(in: displays()),
      let content = EngineMinimapBuilder(snapshot: snapshot, viewport: display.visibleFrame).build()
    else {
      hide()
      return
    }
    host.showMinimap(content, update: .animated, on: display.visibleFrame)
  }

  func hide() {
    host.hideMinimap()
  }

  private func select(_ window: WindowID) {
    Task { [weak self] in await self?.reorder.focus(window) }
  }

  private func drop(_ window: WindowID, on target: DropTarget) {
    Task { [weak self] in
      guard let outcome = await self?.reorder.move(window, to: target),
        let snapshot = outcome.snapshot
      else { return }
      self?.flash(snapshot)
    }
  }
}
