import CoreGraphics

protocol WindowHandle: AnyObject {
  var id: CGWindowID { get }
  var pid: pid_t { get }
  var bundleIdentifier: String? { get }
  var appName: String { get }
  var title: String { get }
  var frame: CGRect? { get }
  func setFrame(_ frame: CGRect)
  func focus()
}
