import CoreGraphics

public enum WindowEvent {
  case created(ManagedWindow)
  case destroyed(CGWindowID)
  case focused(CGWindowID)
  case moved(CGWindowID)
  case resized(CGWindowID)
  case minimized(CGWindowID)
  case restored(CGWindowID)
  case appHidden(pid_t)
  case appShown(pid_t)
}
