import Foundation

struct EngineHelperLocator {
  static let helperName = "paneru"
  static let bridgeName = "engine-bridge"
  static let helpersPath = "Contents/Helpers"
  static let bundledVersionPath = "Contents/Resources/engine-version"
  static let sourceVersionPath = "support/engine-version"

  let bundleURL: URL
  let executableURL: URL?
  let fileExists: (String) -> Bool
  let contents: (String) -> String?

  var helper: URL? { executable(named: Self.helperName) }

  var bridge: URL? { executable(named: Self.bridgeName) }

  private func executable(named name: String) -> URL? {
    let bundled = bundleURL.appendingPathComponent(Self.helpersPath).appendingPathComponent(name)
    if fileExists(bundled.path) { return bundled }
    guard let checkout = sourceCheckout, let version = sourceVersion(in: checkout) else {
      return nil
    }
    let built = checkout.appendingPathComponent("build/engine-\(version)/bin/\(name)")
    return fileExists(built.path) ? built : nil
  }

  var version: String {
    if let bundled = trimmed(bundleURL.appendingPathComponent(Self.bundledVersionPath).path) {
      return bundled
    }
    return sourceCheckout.flatMap(sourceVersion(in:)) ?? "unknown"
  }

  private var sourceCheckout: URL? {
    var directory = executableURL?.deletingLastPathComponent().standardizedFileURL
    while let current = directory {
      if fileExists(current.appendingPathComponent(Self.sourceVersionPath).path) { return current }
      directory = current.path == "/" ? nil : current.deletingLastPathComponent().standardizedFileURL
    }
    return nil
  }

  private func sourceVersion(in checkout: URL) -> String? {
    trimmed(checkout.appendingPathComponent(Self.sourceVersionPath).path)
  }

  private func trimmed(_ path: String) -> String? {
    contents(path)?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
  }

  static func system(bundle: Bundle = .main) -> EngineHelperLocator {
    EngineHelperLocator(
      bundleURL: bundle.bundleURL, executableURL: bundle.executableURL,
      fileExists: { FileManager.default.fileExists(atPath: $0) },
      contents: { try? String(contentsOfFile: $0, encoding: .utf8) })
  }
}

extension String {
  fileprivate var nilIfEmpty: String? { isEmpty ? nil : self }
}
