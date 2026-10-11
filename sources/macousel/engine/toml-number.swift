import Foundation

nonisolated enum TomlNumber {
  private static let places = 5

  static func decimal(_ value: Double) -> String {
    var text = String(format: "%.\(places)f", value)
    while text.hasSuffix("0") && !text.hasSuffix(".0") { text.removeLast() }
    return text
  }

  static func integer(_ value: Double) -> Int {
    Int(value.rounded())
  }

  static func array(_ values: [Double]) -> String {
    "[" + values.map { decimal($0) }.joined(separator: ", ") + "]"
  }
}
