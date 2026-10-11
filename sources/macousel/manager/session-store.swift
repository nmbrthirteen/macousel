import CoreGraphics
import Foundation
import StripCore

struct SessionStore {
  private static let key = "session"

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func load() -> [String: [SavedColumn]] {
    guard let data = defaults.data(forKey: Self.key),
      let session = try? JSONDecoder().decode([String: [SavedColumn]].self, from: data)
    else { return [:] }
    return session
  }

  func save(
    _ stripsByDisplay: [String: Strip], windows: [CGWindowID: any WindowHandle],
    titles: [CGWindowID: String]
  ) {
    let session = stripsByDisplay.mapValues { strip in
      strip.columns.map { SavedColumn($0, windows: windows, titles: titles) }
    }
    guard let data = try? JSONEncoder().encode(session) else { return }
    defaults.set(data, forKey: Self.key)
  }
}
