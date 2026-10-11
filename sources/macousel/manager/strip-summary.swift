import StripCore

extension Strip {
  var shapeSummary: String {
    columns.isEmpty ? "empty" : columns.map { String($0.windows.count) }.joined(separator: ",")
  }

  var focusSummary: String {
    focusedColumn.map { String($0) } ?? "none"
  }
}
