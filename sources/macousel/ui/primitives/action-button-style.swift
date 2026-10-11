import SwiftUI

struct ActionButtonStyle: ViewModifier {
  let role: ActionButtonRole

  @ViewBuilder
  func body(content: Content) -> some View {
    switch role {
    case .primary: content.buttonStyle(.glassProminent)
    case .secondary: content.buttonStyle(.glass)
    }
  }
}

extension View {
  func actionButtonStyle(_ role: ActionButtonRole) -> some View {
    modifier(ActionButtonStyle(role: role))
  }
}
