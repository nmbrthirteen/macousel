nonisolated enum TomlString {
  static func quoted(_ value: String) -> String {
    // Scalars, so a CRLF pair is never one Character that slips past the cases.
    let escaped = value.unicodeScalars.reduce(into: "") { result, scalar in
      switch scalar {
      case "\\": result += "\\\\"
      case "\"": result += "\\\""
      case "\n": result += "\\n"
      case "\r": result += "\\r"
      case "\t": result += "\\t"
      case "\u{00}"..."\u{1F}", "\u{7F}":
        let hex = String(scalar.value, radix: 16, uppercase: true)
        result += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
      default: result.unicodeScalars.append(scalar)
      }
    }
    return "\"" + escaped + "\""
  }

  static func key(from identifier: String) -> String {
    let mapped = identifier.lowercased().map { $0.isASCII && ($0.isLetter || $0.isNumber) ? $0 : "_" }
    return String(mapped)
  }
}
