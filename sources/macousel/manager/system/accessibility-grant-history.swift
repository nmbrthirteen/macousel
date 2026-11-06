import Foundation

// macOS ties the Accessibility grant to the code signature, so after an update the old entry
// still shows as on in System Settings while the new build is not trusted. That is the one case
// a tccutil reset helps, and it runs once per build so it never wipes a grant in a loop.
struct AccessibilityGrantHistory {
  private static let grantedBuildKey = "accessibility.grantedBuild"
  private static let resetBuildKey = "accessibility.resetBuild"

  let defaults: UserDefaults
  let build: String?

  func recordGranted() {
    guard let build, defaults.string(forKey: Self.grantedBuildKey) != build else { return }
    defaults.set(build, forKey: Self.grantedBuildKey)
  }

  // True when another build held the grant, so System Settings likely shows Macousel as on
  // while macOS does not trust this one.
  func wasGrantedToAnotherBuild(isGranted: Bool) -> Bool {
    guard !isGranted, let build, let granted = defaults.string(forKey: Self.grantedBuildKey)
    else { return false }
    return granted != build
  }

  func takeStaleGrantReset(isGranted: Bool) -> Bool {
    guard !isGranted, let build,
      let granted = defaults.string(forKey: Self.grantedBuildKey), granted != build,
      defaults.string(forKey: Self.resetBuildKey) != build
    else { return false }
    defaults.set(build, forKey: Self.resetBuildKey)
    return true
  }
}
