import ApplicationServices

nonisolated struct ThreadSafeAXElement: @unchecked Sendable {
  let element: AXUIElement
}
