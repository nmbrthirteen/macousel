import Foundation

struct TemporaryDirectory {
  let url: URL

  init() throws {
    url = FileManager.default.temporaryDirectory
      .appendingPathComponent("macousel-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  }

  func remove() {
    try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    try? FileManager.default.removeItem(at: url)
  }

  func makeBundle(
    named name: String = "Macousel.app", in parent: URL? = nil,
    identifier: String = "dev.macousel.app", version: String = "0.2.0", marker: String = "bundle"
  ) throws -> URL {
    let bundle = (parent ?? url).appendingPathComponent(name, isDirectory: true)
    let contents = bundle.appendingPathComponent("Contents", isDirectory: true)
    try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
    let info: [String: String] = [
      "CFBundleIdentifier": identifier,
      "CFBundleShortVersionString": version,
      "CFBundleName": "Macousel",
    ]
    try (info as NSDictionary).write(to: contents.appendingPathComponent("Info.plist"))
    try marker.write(
      to: contents.appendingPathComponent("marker.txt"), atomically: true, encoding: .utf8)
    return bundle
  }

  func marker(of bundle: URL) -> String? {
    try? String(
      contentsOf: bundle.appendingPathComponent("Contents/marker.txt"), encoding: .utf8)
  }

  func entries(in directory: URL) throws -> [String] {
    try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
  }
}
