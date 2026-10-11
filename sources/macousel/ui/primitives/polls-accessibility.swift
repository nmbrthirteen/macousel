import SwiftUI

extension View {
  func pollsAccessibility(_ status: AccessibilityStatus) -> some View {
    onAppear(perform: status.startPolling)
      .onDisappear(perform: status.stopPolling)
  }
}
