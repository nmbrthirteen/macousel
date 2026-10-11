enum AppRuleKind: CaseIterable {
  case float, width, slot

  static let defaultWidth = 0.5
  static let defaultSlot = 1

  init(_ behavior: AppRule.Behavior) {
    switch behavior {
    case .float: self = .float
    case .width: self = .width
    case .slot: self = .slot
    }
  }

  var title: String {
    switch self {
    case .float: "Float"
    case .width: "Open at width"
    case .slot: "Open in column"
    }
  }

  var defaultBehavior: AppRule.Behavior {
    switch self {
    case .float: .float
    case .width: .width(Self.defaultWidth)
    case .slot: .slot(Self.defaultSlot)
    }
  }
}
