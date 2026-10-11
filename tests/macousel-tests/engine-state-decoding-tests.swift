import Testing

@testable import Macousel

@MainActor
struct EngineStateDecodingTests {
  @Test func decodesTheStateDocument() throws {
    let snapshot = try #require(EngineFixtures.snapshot())

    #expect(snapshot.version == 1)
    #expect(snapshot.active.displayId == 1)
    #expect(snapshot.active.focusedWindowId == 322)
    #expect(snapshot.active.focusedBundleId == "com.apple.Safari")
    #expect(snapshot.virtualWorkspaces.count == 2)
    let windows = snapshot.virtualWorkspaces[0].windows
    #expect(windows.map(\.windowId) == [321, 322, 323, 324])
    #expect(windows[0].frame == EngineWindow.Frame(x: 0, y: 25, width: 960, height: 1055))
    #expect(windows[3].floating)
    #expect(!windows[2].visible)
  }

  @Test func toleratesMissingOptionalWindowFields() throws {
    let text = """
      {"version":1,"timestamp":1,"active":{},"virtual_workspaces":[{"number":3,\
      "native_workspace_id":4,"active":true,"windows":[{"window_id":9,"bundle_id":"a",\
      "app_name":"A","title":"t","focused":true,"floating":false}]}]}
      """

    let snapshot = try #require(EngineSnapshot.decode(text))

    #expect(snapshot.active.displayId == nil)
    #expect(snapshot.virtualWorkspaces[0].windows[0].visible)
    #expect(snapshot.virtualWorkspaces[0].windows[0].frame == nil)
  }

  @Test func rejectsTextThatIsNotAStateDocument() {
    #expect(EngineSnapshot.decode("not json") == nil)
    #expect(EngineSnapshot.decode("") == nil)
  }

  @Test func decodesVirtualWorkspaceChanged() throws {
    let line =
      #"{"event":"virtual_workspace_changed","active":{"display_id":1,"virtual_workspace_number":2}}"#

    let event = try #require(EngineEvent.decode(line: line))

    #expect(
      event == .virtualWorkspaceChanged(EngineActive(displayId: 1, virtualWorkspaceNumber: 2)))
  }

  @Test func decodesWindowsChanged() throws {
    let line =
      #"{"event":"windows_changed","virtual_workspace_number":1,"active":{"focused_window_id":5}}"#

    let event = try #require(EngineEvent.decode(line: line))

    #expect(event == .windowsChanged(workspace: 1, active: EngineActive(focusedWindowId: 5)))
  }

  @Test func decodesWindowFocused() throws {
    let line =
      #"{"event":"window_focused","window_id":321,"bundle_id":"com.apple.Terminal","title":"zsh","virtual_workspace_number":1}"#

    let event = try #require(EngineEvent.decode(line: line))

    #expect(
      event
        == .windowFocused(
          windowId: 321, bundleId: "com.apple.Terminal", title: "zsh", workspace: 1))
  }

  @Test func decodesOnScreenChanged() throws {
    let line =
      #"{"event":"on_screen_changed","windows":[{"window_id":1,"bundle_id":"a","app_name":"A","title":"t","focused":false,"floating":false,"display_id":1,"visible":true}],"active":{"display_id":1}}"#

    let event = try #require(EngineEvent.decode(line: line))

    guard case .onScreenChanged(let windows, let active) = event else {
      Issue.record("Expected an on-screen event")
      return
    }
    #expect(windows.map(\.windowId) == [1])
    #expect(active.displayId == 1)
  }

  @Test func decodesWindowTitleChanged() throws {
    let line = #"{"event":"window_title_changed","window_id":7,"title":"New"}"#

    #expect(
      EngineEvent.decode(line: line) == .windowTitleChanged(windowId: 7, title: "New"))
  }

  @Test func decodesDisplayChanged() throws {
    #expect(
      EngineEvent.decode(line: #"{"event":"display_changed","display_id":2}"#)
        == .displayChanged(displayId: 2))
    #expect(
      EngineEvent.decode(line: #"{"event":"display_changed","display_id":null}"#)
        == .displayChanged(displayId: nil))
  }

  @Test func keepsUnknownEventsInsteadOfFailing() {
    #expect(EngineEvent.decode(line: #"{"event":"future_event"}"#) == .unrecognized("future_event"))
    #expect(EngineEvent.decode(line: "garbage") == nil)
  }
}
