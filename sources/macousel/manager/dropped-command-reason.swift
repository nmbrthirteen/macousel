enum DroppedCommandReason: String {
  case needsPermission = "needs Accessibility access"
  case paused = "tiling is paused"
  case noActiveWorkspace = "no active workspace"
}
