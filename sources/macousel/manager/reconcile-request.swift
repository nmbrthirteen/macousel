struct ReconcileRequest {
  var adoptsFocus = true
  var refreshesTabTitles = true
  var completions: [() -> Void] = []

  func merged(with other: ReconcileRequest) -> ReconcileRequest {
    ReconcileRequest(
      adoptsFocus: adoptsFocus || other.adoptsFocus,
      refreshesTabTitles: refreshesTabTitles || other.refreshesTabTitles,
      completions: completions + other.completions)
  }
}
