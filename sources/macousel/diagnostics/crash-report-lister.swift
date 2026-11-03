import Foundation

struct CrashReportLister {
  static let namePrefix = "Macousel"

  let directory: URL

  var names: [String] {
    let entries: [String]
    do {
      entries = try FileManager.default.contentsOfDirectory(atPath: directory.path)
    } catch CocoaError.fileReadNoSuchFile {
      return []
    } catch {
      return ["The crash reports could not be listed. \(error.localizedDescription)"]
    }
    return entries.filter { $0.hasPrefix(Self.namePrefix) }.sorted()
  }
}
