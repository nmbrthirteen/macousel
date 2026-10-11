import CoreGraphics
import StripCore
import WindowSystem

final class Scratchpad {
  static let widthFraction = 0.6
  static let heightFraction = 0.7

  private enum Contents {
    case empty
    case hidden(CGWindowID)
    case shown(CGWindowID, on: Workspace.Key, frame: CGRect)
  }

  private let state: TilingState
  private let source: any WindowSource
  private let placer: any FramePlacer
  private let focus: FocusDriver
  private var contents = Contents.empty

  init(
    state: TilingState, source: any WindowSource, placer: any FramePlacer, focus: FocusDriver
  ) {
    self.state = state
    self.source = source
    self.placer = placer
    self.focus = focus
  }

  var window: CGWindowID? {
    switch contents {
    case .empty: nil
    case .hidden(let window), .shown(let window, _, _): window
    }
  }

  func holds(_ candidate: CGWindowID) -> Bool {
    window == candidate
  }

  func isHidden(_ candidate: CGWindowID) -> Bool {
    guard case .hidden(let hidden) = contents else { return false }
    return hidden == candidate
  }

  func send(_ incoming: CGWindowID, from key: Workspace.Key) -> Bool {
    guard let handle = source.window(incoming), let display = state.display(for: key),
      let frame = state.settledLayout(for: key)?[WindowID(incoming)]?.frame
    else { return false }
    contents = .hidden(incoming)
    park(handle, frame: frame, on: display)
    return true
  }

  func toggle() {
    switch contents {
    case .empty:
      break
    case .hidden:
      show()
    case .shown(let window, _, _):
      if source.focusedWindow()?.id == window { hide() } else { source.window(window)?.focus() }
    }
  }

  func retain(only alive: Set<CGWindowID>) {
    if let window, !alive.contains(window) { contents = .empty }
  }

  func reset() {
    contents = .empty
  }

  private func show() {
    guard let id = window, let handle = source.window(id),
      let key = state.focusedKey ?? state.pointerKey, let display = state.display(for: key)
    else { return }
    let frame = Self.frame(centeredIn: display.visibleFrame)
    placer.submit(frame, for: handle)
    contents = .shown(id, on: key, frame: frame)
    handle.focus()
  }

  private func hide() {
    guard case .shown(let id, let key, let frame) = contents, let handle = source.window(id)
    else { return }
    contents = .hidden(id)
    if let display = state.display(for: key) { park(handle, frame: frame, on: display) }
    let returnKey = state.activeKeys.contains(key) ? key : state.focusedKey ?? state.pointerKey
    guard let returnKey, let target = state.workspaces[returnKey]?.strip.focusedWindow else {
      return
    }
    focus.activate(target, in: returnKey, from: .command)
  }

  private func park(_ handle: any WindowHandle, frame: CGRect, on display: Display) {
    let parked = state.parkingPolicy(for: display).parkedFrame(frame, toward: .right)
    placer.submit(parked, for: handle)
  }

  private static func frame(centeredIn area: CGRect) -> CGRect {
    let size = CGSize(width: area.width * widthFraction, height: area.height * heightFraction)
    return CGRect(
      x: area.midX - size.width / 2, y: area.midY - size.height / 2, width: size.width,
      height: size.height)
  }
}
