struct SetupCheck: Identifiable {
  let id: String
  let passingTitle: String
  let attentionTitle: String
  let effect: String
  let location: String
  let isPassing: Bool
  var offenders: [String] = []
  var fix: StatusRow.ActionButton?

  var title: String {
    isPassing ? passingTitle : attentionTitle
  }

  var detail: String {
    guard !isPassing else { return effect }
    let found = offenders.isEmpty ? "" : "Found: \(offenders.joined(separator: ", ")). "
    return "\(found)\(effect) Change it in \(location)."
  }
}
