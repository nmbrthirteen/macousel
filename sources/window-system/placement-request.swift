import ApplicationServices
import CoreGraphics

nonisolated struct PlacementRequest: Sendable {
  let pid: pid_t
  let bundleIdentifier: String?
  let element: ThreadSafeAXElement
  let frame: CGRect
}
