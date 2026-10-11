nonisolated struct EngineWorkspace: Decodable, Equatable, Sendable {
  var number: Int
  var nativeWorkspaceId: UInt64
  var active: Bool
  var windows: [EngineWindow]
}
