import StripCore

extension CenterMode {
  var title: String {
    switch self {
    case .never: "Never"
    case .onOverflow: "When it does not all fit"
    case .always: "Always"
    }
  }

  var summary: String {
    switch self {
    case .never: "The strip moves only as far as needed to show the focused column."
    case .onOverflow:
      "A strip that fits is centered as a whole. Otherwise the focused column sits in the middle."
    case .always: "The focused column always sits in the middle of the screen."
    }
  }
}
