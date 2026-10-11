import Observation
import StripCore

@Observable
final class TabBarContent {
  var tabs: [TabBarModel.Tab] = []
  @ObservationIgnored var onSelect: (WindowID) -> Void = { _ in }
}
