import WindowSystem

protocol ManagementEngine: AnyObject {
  var status: WindowManager.Status { get }
  var displays: [Display] { get }
  var position: StripPosition? { get }
  var notice: String? { get }
  func start()
  func perform(_ action: Action)
  func shutdown()
  func preferencesChanged()
}
