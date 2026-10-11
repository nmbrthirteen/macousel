import StripCore

nonisolated enum EngineWindowID {
  static func make(_ identifier: Int32) -> WindowID? {
    UInt32(exactly: identifier).map { WindowID($0) }
  }
}
