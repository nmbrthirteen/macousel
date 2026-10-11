import CoreGraphics

enum WindowSourceEvent {
  case created(CGWindowID)
  case destroyed(CGWindowID)
  case focused(CGWindowID)
  case moved(CGWindowID)
  case resized(CGWindowID)
  case minimized(CGWindowID)
  case restored(CGWindowID)
  case appHidden(pid_t)
  case appShown(pid_t)
}
