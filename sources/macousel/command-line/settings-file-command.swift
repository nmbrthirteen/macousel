import AppKit

struct SettingsFileCommand {
  static let exportName = "export-settings"
  static let importName = "import-settings"

  let defaults: UserDefaults
  let isAppRunning: () -> Bool
  let openURL: (URL) -> Bool

  static var system: SettingsFileCommand {
    SettingsFileCommand(
      defaults: .standard,
      isAppRunning: {
        let own = ProcessInfo.processInfo.processIdentifier
        return Bundle.main.bundleIdentifier.map {
          NSRunningApplication.runningApplications(withBundleIdentifier: $0)
            .contains { $0.processIdentifier != own }
        } ?? false
      },
      openURL: { NSWorkspace.shared.open($0) })
  }

  func run(arguments: [String]) -> CommandLineResult? {
    guard let name = arguments.first, name == Self.exportName || name == Self.importName else {
      return nil
    }
    guard arguments.count == 2 else {
      return .usage("Usage: Macousel \(name) <path>\n")
    }
    let file = URL(fileURLWithPath: (arguments[1] as NSString).expandingTildeInPath)
    return name == Self.exportName ? export(to: file) : importSettings(from: file)
  }

  private func export(to file: URL) -> CommandLineResult {
    do {
      let data = try SettingsFile.encode(PreferencesStore(defaults: defaults).preferences)
      try data.write(to: file, options: .atomic)
      return .success("Wrote settings to \(file.path).\n")
    } catch {
      return .failure("Could not write to \(file.path): \(error.localizedDescription)\n")
    }
  }

  private func importSettings(from file: URL) -> CommandLineResult {
    let store = PreferencesStore(defaults: defaults)
    do {
      let data = try Data(contentsOf: file)
      store.preferences = try SettingsFile.decode(data, keepingOnboardingFrom: store.preferences)
    } catch {
      return .failure("Could not import \(file.path): \(error.localizedDescription)\n")
    }
    defaults.synchronize()
    guard isAppRunning() else {
      return .success(
        "Imported settings from \(file.path). They apply the next time Macousel starts.\n")
    }
    guard let url = CommandURL.reloadSettings, openURL(url) else {
      return .failure(
        "Imported settings from \(file.path), but could not reach the running Macousel. Quit and start it again to apply them.\n"
      )
    }
    return .success("Imported settings from \(file.path).\n")
  }
}
