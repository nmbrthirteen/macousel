nonisolated struct EngineActive: Decodable, Equatable, Sendable {
  var displayId: UInt32?
  var nativeWorkspaceId: UInt64?
  var virtualWorkspaceNumber: Int?
  var focusedWindowId: Int32?
  var focusedBundleId: String?
  var focusedAppName: String?
  var focusedWindowTitle: String?
}
