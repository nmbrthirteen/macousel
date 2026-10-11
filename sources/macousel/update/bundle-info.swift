import Foundation

nonisolated struct BundleInfo {
  let identifier: String?
  let version: AppVersion?

  init(bundle: Bundle) {
    identifier = bundle.bundleIdentifier
    version = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
      .flatMap { AppVersion($0) }
  }
}
