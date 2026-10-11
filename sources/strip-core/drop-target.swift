public enum DropTarget: Sendable, Equatable {
  case nowhere
  case stack(onto: WindowID, side: VerticalNeighbor)
  case column(position: Int)
}
