extension Double {
  var wholePercent: Int {
    Int((self * 100).rounded())
  }
}
