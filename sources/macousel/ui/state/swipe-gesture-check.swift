struct SwipeGestureCheck {
  private static let desktopSwitchingValue = 2

  let trackpads: [SystemDefaults]
  let isSwipeEnabled: Bool
  let fingers: Int

  var check: SetupCheck? {
    guard isSwipeEnabled else { return nil }
    return SetupCheck(
      id: "swipe-gesture",
      passingTitle: "The swipe gesture is free",
      attentionTitle: "macOS uses the same swipe",
      effect: "macOS switches desktops with the same swipe.",
      location:
        "System Settings > Trackpad > More Gestures. Turn off Swipe between full-screen applications or set it to the other finger count",
      isPassing: !macSwitchesDesktops,
      passingDetail: "macOS does not use this swipe to switch desktops."
    )
  }

  private var key: String {
    fingers == 3 ? "TrackpadThreeFingerHorizSwipeGesture" : "TrackpadFourFingerHorizSwipeGesture"
  }

  private var macSwitchesDesktops: Bool {
    trackpads.contains { $0.int(forKey: key) == Self.desktopSwitchingValue }
  }
}
