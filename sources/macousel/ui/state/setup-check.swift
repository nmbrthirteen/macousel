struct SetupCheck: Identifiable {
  let id: String
  let passingTitle: String
  let attentionTitle: String
  let effect: String
  let location: String
  let isPassing: Bool
  var passingDetail: String?
  var offenders: [String] = []
  var fix: StatusRow.ActionButton?

  var title: String {
    isPassing ? passingTitle : attentionTitle
  }

  var detail: String {
    guard !isPassing else { return passingDetail ?? effect }
    let found = offenders.isEmpty ? "" : "Found: \(offenders.joined(separator: ", ")). "
    return "\(found)\(effect) Change it in \(location)."
  }
}
