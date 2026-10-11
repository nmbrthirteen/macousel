import CoreGraphics
import WindowSystem

protocol WindowProbing: AnyObject {
  func probe(
    _ windows: [CGWindowID], includingFocus: Bool,
    completion: @escaping (WindowProbeResult) -> Void)
}
