@testable import Macousel


enum EngineFixtures {
  static let stateJSON = """
    {"version":1,"timestamp":1777740000,"active":{"display_id":1,"native_workspace_id":4,\
    "virtual_workspace_number":1,"focused_window_id":322,"focused_bundle_id":"com.apple.Safari",\
    "focused_app_name":"Safari","focused_window_title":"Docs"},"virtual_workspaces":[\
    {"number":1,"native_workspace_id":4,"active":true,"windows":[\
    {"window_id":321,"bundle_id":"com.apple.Terminal","app_name":"Terminal","title":"zsh",\
    "focused":false,"floating":false,"display_id":1,\
    "frame":{"x":0,"y":25,"width":960,"height":1055},"visible":true},\
    {"window_id":322,"bundle_id":"com.apple.Safari","app_name":"Safari","title":"Docs",\
    "focused":true,"floating":false,"display_id":1,\
    "frame":{"x":960,"y":25,"width":960,"height":1055},"visible":true},\
    {"window_id":323,"bundle_id":"com.apple.TextEdit","app_name":"TextEdit","title":"Notes",\
    "focused":false,"floating":false,"display_id":1,\
    "frame":{"x":1915,"y":25,"width":960,"height":1055},"visible":false},\
    {"window_id":324,"bundle_id":"com.apple.calculator","app_name":"Calculator","title":"Calculator",\
    "focused":false,"floating":true,"display_id":1,\
    "frame":{"x":400,"y":300,"width":300,"height":400},"visible":true}]},\
    {"number":2,"native_workspace_id":4,"active":false,"windows":[]}]}
    """

  static func snapshot() -> EngineSnapshot? {
    EngineSnapshot.decode(stateJSON)
  }

  static func tile(_ id: Int32, bundle: String, focused: Bool = false) -> EngineWindow {
    EngineWindow(
      windowId: id, bundleId: bundle, appName: bundle, title: bundle, focused: focused,
      displayId: 1, frame: EngineWindow.Frame(x: 0, y: 0, width: 100, height: 100))
  }

  static func snapshot(of windows: [EngineWindow]) -> EngineSnapshot {
    EngineSnapshot(
      version: 1, timestamp: 0,
      active: EngineActive(
        displayId: 1, nativeWorkspaceId: 4, virtualWorkspaceNumber: 1,
        focusedWindowId: windows.first { $0.focused }?.windowId),
      virtualWorkspaces: [
        EngineWorkspace(number: 1, nativeWorkspaceId: 4, active: true, windows: windows)
      ])
  }
}
