import CoreGraphics

protocol WindowSource: AnyObject {
  var windows: [CGWindowID: any WindowHandle] { get }
  var onEvent: ((WindowSourceEvent) -> Void)? { get set }
  func window(_ id: CGWindowID) -> (any WindowHandle)?
  func start()
  func stop()
  func focusedWindow() -> (any WindowHandle)?
}
