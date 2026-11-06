import AppKit
import SwiftUI

// SwiftUI has no search field outside `searchable`, and the sidebar already owns that one.
struct SearchField: NSViewRepresentable {
  let label: String
  @Binding var text: String

  func makeNSView(context: Context) -> NSSearchField {
    let field = NSSearchField()
    field.placeholderString = label
    field.setAccessibilityLabel(label)
    field.sendsSearchStringImmediately = true
    field.target = context.coordinator
    field.action = #selector(Coordinator.searchChanged(_:))
    return field
  }

  func updateNSView(_ field: NSSearchField, context: Context) {
    context.coordinator.text = $text
    if field.stringValue != text { field.stringValue = text }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  final class Coordinator: NSObject {
    var text: Binding<String>

    init(text: Binding<String>) {
      self.text = text
    }

    @objc func searchChanged(_ field: NSSearchField) {
      text.wrappedValue = field.stringValue
    }
  }
}
