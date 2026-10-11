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
    case .never: "Never: the strip moves only as far as needed to show the focused window."
    case .onOverflow:
      "When it does not all fit: a strip that fits is centred as a whole. Otherwise the focused window sits in the middle."
    case .always: "Always: the focused window sits in the middle of the screen."
    }
  }
}
