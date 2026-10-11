import CoreGraphics
import StripCore

final class ResizeAdoption {
  private static let settleDelay = Duration.milliseconds(250)
  private static let ownRequestEchoWindow = Duration.milliseconds(300)
  private static let snapTolerance: CGFloat = 24
  private static let fullWidthMargin: CGFloat = 24

  private let state: TilingState
  private let source: any WindowSource
  private let presenter: LayoutPresenter
  private let pointer: any PointerDevice
  private var waits: [CGWindowID: Task<Void, Never>] = [:]

  init(
    state: TilingState, source: any WindowSource, presenter: LayoutPresenter,
    pointer: any PointerDevice
  ) {
    self.state = state
    self.source = source
    self.presenter = presenter
    self.pointer = pointer
  }

  func windowResized(_ window: CGWindowID) {
    guard !pointer.isPrimaryButtonDown else { return }
    if let age = presenter.sizeRequestAge(of: window), age < Self.ownRequestEchoWindow { return }
    waits[window]?.cancel()
    waits[window] = Task { [weak self] in await self?.adoptWhenSettled(window) }
  }

  func stop() {
    waits.values.forEach { $0.cancel() }
    waits = [:]
  }

  private func adoptWhenSettled(_ window: CGWindowID) async {
    repeat {
      try? await Task.sleep(for: Self.settleDelay)
      if Task.isCancelled { return }
    } while !presenter.isSettled
    waits[window] = nil
    adoptWidth(of: window)
  }

  private func adoptWidth(of window: CGWindowID) {
    let id = WindowID(window)
    guard let key = state.activeKey(containing: id), let display = state.display(for: key),
      let requested = presenter.requestedFrame(for: window),
      let actual = source.window(window)?.frame,
      abs(actual.width - requested.width) > Self.snapTolerance
    else { return }
    let usableWidth = state.usableWidth(of: display)
    if abs(usableWidth - actual.width) <= Self.fullWidthMargin {
      state.workspaces[key]?.strip.setFullWidth(true, of: id)
    } else {
      state.workspaces[key]?.strip.setFixedWidth(actual.width, of: id)
    }
    presenter.invalidate(window)
    state.scrollToFocus(key)
    presenter.relayout()
  }
}
