nonisolated enum TomlString {
  static func quoted(_ value: String) -> String {
    let escaped = value.reduce(into: "") { result, character in
      switch character {
      case "\\": result += "\\\\"
      case "\"": result += "\\\""
      case "\n": result += "\\n"
      default: result.append(character)
      }
    }
    return "\"" + escaped + "\""
  }

  static func key(from identifier: String) -> String {
    let mapped = identifier.lowercased().map { $0.isASCII && ($0.isLetter || $0.isNumber) ? $0 : "_" }
    return String(mapped)
  }
}
