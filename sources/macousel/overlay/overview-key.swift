import StripCore

enum OverviewKey: Equatable {
  case move(Direction)
  case jump(Int)
  case moveWindow(Direction)
  case moveWindowToPlace(Int)
  case widen
  case narrow
  case confirm
  case dismiss
}
