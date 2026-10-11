import CoreGraphics
import StripCore

final class DropPlanner {
  private let state: TilingState

  init(state: TilingState) {
    self.state = state
  }

  func plan(
    dragging window: WindowID, from key: Workspace.Key, pointer: CGPoint,
    strips: [Workspace.Key: Strip]
  ) -> DropPlan? {
    guard let strip = strips[key] else { return nil }
    let destination = state.activeKey(at: pointer) ?? key
    if destination == key {
      return planWithinDisplay(window, strip: strip, key: key, pointer: pointer)
    }
    return planAcrossDisplays(
      window, strip: strip, from: key, to: destination, arriving: strips[destination])
  }

  func commit(_ plan: DropPlan) {
    for (key, strip) in plan.strips { state.workspaces[key]?.strip = strip }
    if plan.changesLayout { state.focusedKey = plan.destination }
  }

  private func planWithinDisplay(
    _ window: WindowID, strip: Strip, key: Workspace.Key, pointer: CGPoint
  ) -> DropPlan? {
    guard let display = state.display(for: key) else { return nil }
    let viewport = display.visibleFrame
    let layout = strip.layout(in: viewport, config: state.config)
    let rule = DropRule(strip: strip, layout: layout, viewport: viewport, dragging: window)
    let target = rule.target(at: pointer)
    guard target != .nowhere else {
      return DropPlan(
        target: .nowhere, destination: key, strips: [key: strip], movesToAnotherDisplay: false)
    }
    var result = rule.applying(target)
    result.scrollToFocus(viewportWidth: viewport.width, config: state.config)
    return DropPlan(
      target: target, destination: key, strips: [key: result], movesToAnotherDisplay: false,
      previewFrame: frame(of: window, in: result, on: viewport))
  }

  private func planAcrossDisplays(
    _ window: WindowID, strip: Strip, from source: Workspace.Key, to destination: Workspace.Key,
    arriving destinationStrip: Strip?
  ) -> DropPlan? {
    guard let sourceDisplay = state.display(for: source),
      let destinationDisplay = state.display(for: destination),
      var arriving = destinationStrip
    else { return nil }
    var leaving = strip
    leaving.remove(window)
    leaving.scrollToFocus(viewportWidth: sourceDisplay.visibleFrame.width, config: state.config)
    arriving.insert(window, config: state.config)
    arriving.scrollToFocus(
      viewportWidth: destinationDisplay.visibleFrame.width, config: state.config)
    return DropPlan(
      target: .nowhere, destination: destination,
      strips: [source: leaving, destination: arriving], movesToAnotherDisplay: true,
      previewFrame: frame(of: window, in: arriving, on: destinationDisplay.visibleFrame))
  }

  private func frame(of window: WindowID, in strip: Strip, on viewport: CGRect) -> CGRect? {
    strip.layout(in: viewport, config: state.config)[window]
      .map { $0.frame.intersection(viewport) }
  }
}
