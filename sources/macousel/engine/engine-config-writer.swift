import Foundation

struct EngineConfigWriter {
  let opener: any ConfigFileOpening

  func write(_ text: String, to url: URL) throws {
    let data = Data(text.utf8)
    let handle = try opener.open(url)
    do {
      try handle.write(data)
      try handle.truncate(to: UInt64(data.count))
    } catch {
      try? handle.close()
      throw error
    }
    try handle.close()
  }
}
