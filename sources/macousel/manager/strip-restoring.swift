import StripCore

extension Strip {
  mutating func restore(_ saved: [SavedColumn], from windows: [any WindowHandle])
    -> [any WindowHandle]
  {
    var matcher = SessionMatcher(windows)
    for column in saved {
      let members = column.windows.compactMap { matcher.claim($0) }.map { WindowID($0) }
      restoreColumn(of: members, like: column)
    }
    return matcher.remaining
  }

  private mutating func restoreColumn(of members: [WindowID], like saved: SavedColumn) {
    guard let first = members.first else { return }
    append(first, width: saved.width)
    for member in members.dropFirst() {
      append(member, width: saved.width)
      focus(member)
      stackFocused(into: .left)
    }
    focus(first)
    if let weights = saved.heightWeights {
      setHeightWeights(weights, ofColumnContaining: first)
    }
    if saved.display == .tabbed && members.count > 1 {
      toggleTabbed()
    }
    if saved.isFullWidth == true {
      toggleFullWidth()
    }
  }
}
