nonisolated struct EngineWindow: Decodable, Equatable, Sendable {
  struct Frame: Decodable, Equatable, Sendable {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
  }

  var windowId: Int32
  var bundleId: String
  var appName: String
  var title: String
  var focused: Bool
  var floating: Bool
  var displayId: UInt32?
  var frame: Frame?
  var visible: Bool

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    windowId = try values.decode(Int32.self, forKey: .windowId)
    bundleId = try values.decodeIfPresent(String.self, forKey: .bundleId) ?? ""
    appName = try values.decodeIfPresent(String.self, forKey: .appName) ?? ""
    title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
    focused = try values.decodeIfPresent(Bool.self, forKey: .focused) ?? false
    floating = try values.decodeIfPresent(Bool.self, forKey: .floating) ?? false
    displayId = try values.decodeIfPresent(UInt32.self, forKey: .displayId)
    frame = try values.decodeIfPresent(Frame.self, forKey: .frame)
    visible = try values.decodeIfPresent(Bool.self, forKey: .visible) ?? true
  }

  init(
    windowId: Int32, bundleId: String = "", appName: String = "", title: String = "",
    focused: Bool = false, floating: Bool = false, displayId: UInt32? = nil, frame: Frame? = nil,
    visible: Bool = true
  ) {
    self.windowId = windowId
    self.bundleId = bundleId
    self.appName = appName
    self.title = title
    self.focused = focused
    self.floating = floating
    self.displayId = displayId
    self.frame = frame
    self.visible = visible
  }

  private enum CodingKeys: String, CodingKey {
    case windowId, bundleId, appName, title, focused, floating, displayId, frame, visible
  }
}
