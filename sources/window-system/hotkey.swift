public nonisolated struct Hotkey: Hashable, Sendable, Codable {
  public nonisolated struct Modifiers: OptionSet, Hashable, Sendable, Codable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }

    public static let control = Modifiers(rawValue: 1 << 0)
    public static let option = Modifiers(rawValue: 1 << 1)
    public static let shift = Modifiers(rawValue: 1 << 2)
    public static let command = Modifiers(rawValue: 1 << 3)
  }

  public var keyCode: UInt16
  public var modifiers: Modifiers

  public init(keyCode: UInt16, modifiers: Modifiers) {
    self.keyCode = keyCode
    self.modifiers = modifiers
  }
}
