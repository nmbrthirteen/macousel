import CoreGraphics
import StripCore
import WindowSystem

final class FocusFollowsPointer {
  private static let commandGracePeriod = Duration.milliseconds(400)

  var isSuppressed: () -> Bool = { false }

  private let state: TilingState
  private let presenter: LayoutPresenter
  private let focus: FocusDriver
  private let store: PreferencesStore
  private let pointer: any PointerDevice

  init(
    state: TilingState, presenter: LayoutPresenter, focus: FocusDriver, store: PreferencesStore,
    pointer: any PointerDevice
  ) {
    self.state = state
    self.presenter = presenter
    self.focus = focus
    self.store = store
    self.pointer = pointer
  }

  func configure(isTiling: Bool) {
    pointer.stopObservingMovement()
    if isTiling && store.preferences.focusFollowsMouse {
      pointer.startObservingMovement { [weak self] point in self?.pointerMoved(to: point) }
    }
  }

  func stop() {
    pointer.stopObservingMovement()
  }

  private func isOverFocusedWindow(_ point: CGPoint) -> Bool {
    guard let key = state.focusedKey,
      let focused = state.workspaces[key]?.strip.focusedWindow,
      let frame = presenter.requestedFrame(for: focused.rawValue)
    else { return false }
    return frame.contains(point)
  }

  private func pointerMoved(to point: CGPoint) {
    guard presenter.isSettled, !isSuppressed(), !isOverFocusedWindow(point),
      !focus.hasCommandActivation(within: Self.commandGracePeriod),
      let window = pointer.windowID(at: point).map(WindowID.init(_:)),
      let key = state.activeKey(containing: window),
      state.focusedKey != key || state.workspaces[key]?.strip.focusedWindow != window
    else { return }
    state.workspaces[key]?.strip.focus(window)
    focus.activate(window, in: key, from: .pointer)
    presenter.render()
  }
}
