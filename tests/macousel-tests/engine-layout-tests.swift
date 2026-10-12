import CoreGraphics
import StripCore
import Testing

@testable import Macousel

@MainActor
struct EngineLayoutTests {
  private static let frame = #"{"x":0,"y":38,"width":960,"height":1205}"#

  private static func row(_ id: Int32, focused: Bool = false) -> String {
    """
    {"window_id":\(id),"bundle_id":"app","app_name":"App","title":"","focused":\(focused),\
    "floating":false,"display_id":1,"frame":\(frame),"visible":true}
    """
  }

  private static func record(_ id: Int32) -> String {
    """
    {"id":\(id),"app_name":"App","bundle_id":"app","title":"","frame":\(frame),\
    "floating":false,"managed":true,"visible":true,"focused":false}
    """
  }

  private static let state = """
    {"version":1,"timestamp":0,"active":{"display_id":1,"native_workspace_id":3,\
    "virtual_workspace_number":1,"focused_window_id":7},"virtual_workspaces":[\
    {"number":1,"native_workspace_id":3,"active":true,\
    "windows":[\(row(7, focused: true)),\(row(8)),\(row(9))]}]}
    """

  private static let layout = """
    {"displays":[{"id":1,"frame":\(frame),"active":true,"workspaces":[\
    {"number":1,"native_id":3,"active":true,"columns":[\
    {"kind":"tabs","width_ratio":0.5,"selected":0,"windows":[\(record(7)),\(record(8))]},\
    {"kind":"single","width_ratio":0.5,"selected":0,"windows":[\(record(9))]}],"floating":[]},\
    {"number":2,"native_id":3,"active":false,"columns":[\
    {"kind":"single","width_ratio":0.5,"selected":0,"windows":[\(record(20))]}],"floating":[]}]},\
    {"id":2,"frame":\(frame),"active":false,"workspaces":[\
    {"number":1,"native_id":5,"active":true,"columns":[\
    {"kind":"single","width_ratio":0.5,"selected":0,"windows":[\(record(30))]}],"floating":[]}]}],\
    "focused":7}
    """

  private func window(_ id: Int32, x: Int = 0, y: Int = 38) -> EngineWindow {
    EngineWindow(
      windowId: id, displayId: 1,
      frame: EngineWindow.Frame(x: x, y: y, width: 960, height: 1205))
  }

  private func ids(_ columns: EngineColumns) -> [[UInt32]] {
    columns.windowIDs.map { $0.map(\.rawValue) }
  }

  @Test func theBridgedDocumentCarriesTheColumnStructure() {
    let snapshot = EngineSnapshot.decode(
      bridged: #"{"state":\#(Self.state),"layout":\#(Self.layout)}"#)

    #expect(snapshot?.layout?.columns(onDisplay: 1) == [[7, 8], [9]])
    #expect(snapshot.map { ids($0.tiledColumns) } == [[7, 8], [9]])
    #expect(snapshot?.focusedColumnIndex == 0)
  }

  @Test func windowsSharingOneFrameSplitIntoColumnsWithoutTheStructure() {
    let snapshot = EngineSnapshot.decode(bridged: #"{"state":\#(Self.state),"layout":null}"#)

    #expect(snapshot?.layout == nil)
    #expect(snapshot.map { ids($0.tiledColumns) } == [[7], [8], [9]])
  }

  @Test func anUnreadableStructureStillYieldsTheState() {
    let snapshot = EngineSnapshot.decode(
      bridged: #"{"state":\#(Self.state),"layout":{"displays":7}}"#)

    #expect(snapshot?.layout == nil)
    #expect(snapshot?.tiledWindows.count == 3)
  }

  @Test func aDocumentWithoutStateIsRejected() {
    #expect(EngineSnapshot.decode(bridged: #"{"layout":\#(Self.layout)}"#) == nil)
    #expect(EngineSnapshot.decode(bridged: "") == nil)
  }

  @Test func onlyTheActiveWorkspaceOfTheAskedDisplayCounts() {
    let snapshot = EngineSnapshot.decode(
      bridged: #"{"state":\#(Self.state),"layout":\#(Self.layout)}"#)

    #expect(snapshot?.layout?.columns(onDisplay: 2) == [[30]])
    #expect(snapshot?.layout?.columns(onDisplay: nil) == [[7, 8], [9], [30]])
  }

  @Test func theStructureSeparatesParkedColumnsThatShareAFrame() {
    let windows = [window(1), window(2, x: 1911), window(3, x: 1911), window(4, x: 1911)]

    #expect(ids(EngineColumns(windows, grouping: [[1], [2], [3], [4]])) == [[1], [2], [3], [4]])
    #expect(ids(EngineColumns(windows, grouping: [[1], [2, 3], [4]])) == [[1], [2, 3], [4]])
  }

  @Test func theStructureOrdersTheColumns() {
    let windows = [window(1), window(2, x: 960), window(3, x: 1920)]

    #expect(ids(EngineColumns(windows, grouping: [[3], [1, 2]])) == [[3], [1, 2]])
  }

  @Test func windowsTheStateLeavesOutAreDroppedFromTheStructure() {
    let windows = [window(1), window(2, x: 960)]

    #expect(ids(EngineColumns(windows, grouping: [[1, 5], [6], [2]])) == [[1], [2]])
  }

  @Test func aStructureMissingATiledWindowFallsBackToFrames() {
    let windows = [window(1), window(2, x: 960), window(3, x: 960, y: 1243)]

    #expect(ids(EngineColumns(windows, grouping: [[1], [2]])) == [[1], [2, 3]])
  }

  @Test func aStructureNamingAWindowTwiceFallsBackToFrames() {
    let windows = [window(1), window(2, x: 960)]

    #expect(ids(EngineColumns(windows, grouping: [[1], [1], [2]])) == [[1], [2]])
    #expect(ids(EngineColumns(windows, grouping: [[1, 1, 2]])) == [[1], [2]])
  }

  @Test func aColumnSharesOneFrameOnlyWhenEveryMemberMatches() {
    let tabbed = EngineColumns([window(1), window(2)], grouping: [[1, 2]]).columns[0]
    let stacked = EngineColumns([window(1), window(2, y: 700)], grouping: [[1, 2]]).columns[0]
    let single = EngineColumns([window(1)]).columns[0]

    #expect(tabbed.sharesOneFrame)
    #expect(!stacked.sharesOneFrame)
    #expect(!single.sharesOneFrame)
  }

  @Test func aDropOnATabbedColumnJoinsItAfterTheLastTab() {
    let viewport = CGRect(x: 0, y: 38, width: 4000, height: 1205)
    let windows = [window(1), window(2, x: 1000), window(3, x: 1000), window(4, x: 1000)]
    let columns = EngineColumns(windows, grouping: [[1], [2, 3, 4]])
    let targeting = EngineDropTargeting(columns: columns, viewport: viewport)
    let preview = EngineDropPreview(columns: columns, viewport: viewport)

    let target = targeting.target(dragging: WindowID(1), at: CGPoint(x: 1480, y: 100))

    #expect(target == .stack(onto: WindowID(4), side: .below))
    #expect(
      preview.frame(for: target, dragging: WindowID(1))
        == CGRect(x: 1000, y: 38, width: 960, height: 1205))
  }

  @Test func aTabDraggedToBlankSpaceLeavesItsColumn() {
    let viewport = CGRect(x: 0, y: 38, width: 4000, height: 1205)
    let columns = EngineColumns([window(1), window(2)], grouping: [[1, 2]])
    let targeting = EngineDropTargeting(columns: columns, viewport: viewport)

    let target = targeting.target(dragging: WindowID(2), at: CGPoint(x: 2500, y: 100))

    #expect(target == .column(position: 1))
    #expect(
      EngineReorderPlan(columns: columns.windowIDs, moving: WindowID(2), to: target)?.steps
        == [.unstack])
  }
}
