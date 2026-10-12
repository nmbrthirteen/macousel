import CoreGraphics
import StripCore
import WindowSystem

@testable import Macousel

@MainActor
final class SettleProbe {
  var sleeps = 0
  var onSleep: (() -> Void)?
  var centersFocus = false
  var centeringSleeps = 0
}

@MainActor
final class EngineDragFixture {
  let pointer = FakePointerDevice()
  let clock = ManualClock()
  let host = FakeOverlayHost()
  let commands = FakeEngineCommands(log: EngineCallLog())
  let strip: FakePaneruStrip
  let world: EngineWorld
  let reorder: EngineReorder
  let overview: EngineOverview
  let drag: EngineDrag
  let centering: EngineCentering
  let probe = SettleProbe()

  init(columns: [[Int32]] = [[1], [2], [3]]) {
    let strip = FakePaneruStrip(columns: columns)
    commands.strip = strip
    let displays: () -> [Display] = { [.fake(width: 4000)] }
    let probe = probe
    let commands = commands
    let reorder = EngineReorder(
      commands: commands, sleep: { _ in await Task.yield() }, now: { FrozenInstant.now })
    let world = EngineWorld(commands: commands, sleep: { _ in })
    let overview = EngineOverview(host: host, displays: displays, reorder: reorder)
    let centering = EngineCentering(
      commands: commands, pointer: pointer, displays: displays,
      isEnabled: { probe.centersFocus },
      sleep: { _ in
        probe.centeringSleeps += 1
        strip.advance()
        await Task.yield()
      },
      now: { FrozenInstant.now })
    self.centering = centering
    self.strip = strip
    self.world = world
    self.reorder = reorder
    self.overview = overview
    drag = EngineDrag(
      pointer: pointer, clock: clock, host: host, world: world, displays: displays,
      reorder: reorder,
      settler: EngineSettler(
        commands: commands,
        sleep: { _ in
          probe.sleeps += 1
          probe.onSleep?()
          await Task.yield()
          try Task.checkCancellation()
        },
        now: { FrozenInstant.now }),
      centering: centering,
      isSuppressed: { overview.isOpen })
    pointer.windowAtPoint = { _ in 1 }
  }

  static let displayCenter = CGPoint(x: 2000, y: 400)

  func engineWarpsThePointerOnCenter() {
    let pointer = pointer
    strip.afterApply = { _, words in
      if words == ["window", "center"] { pointer.movePrimarySilently(to: Self.displayCenter) }
    }
  }

  func primeWorld() async {
    world.refresh()
    _ = await eventually { self.world.snapshot != nil }
  }

  func start() async {
    await primeWorld()
    drag.start()
  }

  func press(_ window: UInt32 = 1) {
    let frame = windowFrame(window)
    pointer.windowAtPoint = { _ in window }
    pointer.setServerBounds(frame, of: window)
    pointer.pressPrimary(at: CGPoint(x: frame.midX, y: frame.midY))
  }

  func windowFrame(_ window: UInt32) -> CGRect {
    strip.snapshot.tiledColumns.frame(of: WindowID(window)) ?? .zero
  }

  func drag(_ window: UInt32 = 1, by offset: CGSize, to point: CGPoint) {
    let frame = windowFrame(window)
    pointer.setServerBounds(frame.offsetBy(dx: offset.width, dy: offset.height), of: window)
    pointer.dragPrimary(to: point)
  }

  func eventually(_ condition: () -> Bool) async -> Bool {
    for _ in 0..<2000 {
      if condition() { return true }
      await Task.yield()
    }
    return false
  }
}
