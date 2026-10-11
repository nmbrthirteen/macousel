import Foundation

struct CrashReportLister {
  static let namePrefix = "Macousel"

  let directory: URL

  var names: [String] {
    let entries = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
    return entries.filter { $0.hasPrefix(Self.namePrefix) }.sorted()
  }
}
