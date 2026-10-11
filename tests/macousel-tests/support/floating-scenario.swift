import CoreGraphics

@testable import Macousel

@MainActor
struct FloatingScenario {
  let fixture: ControllerFixture
  let row: [FakeWindow]
  let floater: FakeWindow

  init(keepsFloatingWindowsOnTop: Bool = true, rowCount: CGWindowID = 3) throws {
    fixture = try ControllerFixture {
      $0.appRules = [AppRule(bundleIdentifier: FakeApp.floater.bundleIdentifier, behavior: .float)]
      $0.keepsFloatingWindowsOnTop = keepsFloatingWindowsOnTop
    }
    row = fixture.openRow(rowCount)
    floater = fixture.open(10, app: .floater)
    fixture.environment.stack(frontToBack: [10] + (1...rowCount).map { $0 })
    fixture.launch()
  }

  var coveringFrame: CGRect {
    fixture.display.visibleFrame.insetBy(dx: 100, dy: 100)
  }

  func coverTheScreen() {
    fixture.source.userMoved(floater, to: coveringFrame)
  }

  func addFloater(_ id: CGWindowID, covering frame: CGRect) -> FakeWindow {
    let window = fixture.open(id, app: .floater)
    fixture.source.userMoved(window, to: frame)
    return window
  }

  func letRaiseDelayPass() {
    fixture.clock.advance(by: FloatingWindowKeeper.raiseDelay)
  }
}
