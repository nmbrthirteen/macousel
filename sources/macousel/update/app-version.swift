nonisolated struct AppVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
  static let zero = AppVersion(components: [0])

  let components: [Int]

  private init(components: [Int]) {
    self.components = components
  }

  init?(_ text: String) {
    var digits = Substring(text.trimmingCharacters(in: .whitespacesAndNewlines))
    if digits.first == "v" || digits.first == "V" {
      digits.removeFirst()
    }
    var numbers: [Int] = []
    for part in digits.split(separator: ".", omittingEmptySubsequences: false) {
      guard !part.isEmpty, part.allSatisfy({ $0.isASCII && $0.isNumber }), let number = Int(part)
      else { return nil }
      numbers.append(number)
    }
    components = numbers
  }

  var description: String {
    components.map { String($0) }.joined(separator: ".")
  }

  private var significant: [Int] {
    var trimmed = components
    while trimmed.last == 0 {
      trimmed.removeLast()
    }
    return trimmed
  }

  static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
    lhs.significant == rhs.significant
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(significant)
  }

  static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
    for index in 0..<max(lhs.components.count, rhs.components.count) {
      let left = index < lhs.components.count ? lhs.components[index] : 0
      let right = index < rhs.components.count ? rhs.components[index] : 0
      if left != right { return left < right }
    }
    return false
  }
}
