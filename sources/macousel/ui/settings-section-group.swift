enum SettingsSectionGroup: CaseIterable {
  case general, windows, input, system

  var title: String? {
    switch self {
    case .general: nil
    case .windows: "Windows"
    case .input: "Input"
    case .system: "System"
    }
  }

  func sections(matching query: String) -> [SettingsSection] {
    SettingsSection.matching(query).filter { $0.group == self }
  }
}
