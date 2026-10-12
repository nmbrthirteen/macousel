import CoreGraphics
import StripCore
import Testing
import WindowSystem

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct EngineOverviewReorderTests {
  private let host = FakeOverlayHost()
  private let commands: FakeEngineCommands
  private let strip: FakePaneruStrip
  private let overview: EngineOverview
  private let minimap: EngineMinimap
  private let preferences: PreferencesStore

  init() throws {
    let fake = FakeEngineCommands(log: EngineCallLog())
    let strip = FakePaneruStrip(columns: [[1], [2, 3], [4], [5]], focused: 1)
    fake.strip = strip
    let reorder = EngineReorder(commands: fake, sleep: { _ in await Task.yield() })
    let displays: () -> [Display] = { [.fake()] }
    let store = PreferencesStore(defaults: try IsolatedDefaults().defaults)
    commands = fake
    self.strip = strip
    preferences = store
    overview = EngineOverview(host: host, displays: displays, reorder: reorder)
    minimap = EngineMinimap(host: host, store: store, displays: displays, reorder: reorder)
  }

  private var shown: [[UInt32]] {
    host.overview.map { OverviewSnapshots.windows($0.snapshot) } ?? []
  }

  private func eventually(_ condition: () -> Bool) async -> Bool {
    for _ in 0..<2000 {
      if condition() { return true }
      await Task.yield()
    }
    return false
  }

  @Test func dropMovesTheRealWindowAndRedrawsTheOpenOverview() async {
    overview.toggle(with: strip.snapshot)
    #expect(shown == [[1], [2, 3], [4], [5]])

    host.drop(WindowID(1), as: .column(position: 3))

    #expect(await eventually { shown == [[2, 3], [4], [5], [1]] })
    #expect(strip.columns == [[2, 3], [4], [5], [1]])
    #expect(host.overview?.snapshot.selection == WindowID(1))
  }

  @Test func dropOntoAWindowStacksTheRealWindows() async {
    overview.toggle(with: strip.snapshot)

    host.drop(WindowID(5), as: .stack(onto: WindowID(4), side: .below))

    #expect(await eventually { shown == [[1], [2, 3], [4, 5]] })
  }

  @Test func keyboardMovesShiftTheSelectedColumn() async {
    overview.toggle(with: strip.snapshot)

    host.press(.moveWindow(.right))

    #expect(await eventually { shown == [[2, 3], [1], [4], [5]] })
  }

  @Test func keyboardPlaceMovesTheSelectedWindowToThatColumn() async {
    overview.toggle(with: strip.snapshot)
    host.press(.jump(4))
    host.press(.moveWindowToPlace(1))

    #expect(await eventually { shown == [[5], [1], [2, 3], [4]] })
  }

  @Test func keyboardRowMovesReorderAStack() async {
    overview.toggle(with: strip.snapshot)
    host.press(.move(.right))
    host.press(.move(.down))
    host.press(.moveWindow(.up))

    #expect(await eventually { shown == [[1], [3, 2], [4], [5]] })
    #expect(host.overview?.snapshot.selection == WindowID(3))
  }

  @Test func widthKeysChangeNothing() async {
    overview.toggle(with: strip.snapshot)

    host.press(.widen)
    host.press(.narrow)
    await Task.yield()

    #expect(commands.sent.isEmpty)
  }

  @Test func overviewDrawsTheRealStructureWithoutResizeGrips() {
    overview.toggle(with: strip.snapshot)

    let snapshot = host.overview?.snapshot
    let geometry = snapshot.map { OverviewGeometry(snapshot: $0, size: OverviewSnapshots.size) }

    #expect(snapshot?.columns.map(\.cards.count) == [1, 2, 1, 1])
    #expect(snapshot?.allowsResize == false)
    #expect(geometry?.hitAreas.edges.isEmpty == true)
    #expect(geometry?.hitAreas.dividers.isEmpty == true)
  }

  @Test func adoptedSnapshotsRefreshTheOpenOverview() {
    overview.toggle(with: strip.snapshot)
    strip.columns = [[5], [1], [2, 3], [4]]

    overview.refresh(with: strip.snapshot)

    #expect(shown == [[5], [1], [2, 3], [4]])
  }

  @Test func refreshDoesNothingWhileClosed() {
    overview.refresh(with: strip.snapshot)

    #expect(host.overview == nil)
  }

  @Test func closesWhenTheRefreshedStripIsEmpty() {
    overview.toggle(with: strip.snapshot)
    strip.columns = []

    overview.refresh(with: strip.snapshot)

    #expect(host.overview == nil)
    #expect(!overview.isOpen)
  }

  @Test func minimapDropMovesTheRealWindow() async {
    host.onMinimapMove?(WindowID(4), .column(position: 0))

    #expect(await eventually { strip.columns == [[4], [1], [2, 3], [5]] })
  }

  @Test func closedOverviewIgnoresTheResultOfAMove() async {
    overview.toggle(with: strip.snapshot)
    host.drop(WindowID(1), as: .column(position: 3))
    overview.close()

    #expect(await eventually { strip.columns == [[2, 3], [4], [5], [1]] })
    #expect(host.overview == nil)
  }
}
