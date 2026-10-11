import StripCore

enum OverviewKey: Equatable {
  case move(Direction)
  case jump(Int)
  case confirm
  case dismiss
}
