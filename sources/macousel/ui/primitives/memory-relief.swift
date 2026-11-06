import Darwin

enum MemoryRelief {
  // Closing a SwiftUI window frees its view tree, but malloc keeps the emptied pages dirty
  // and they still count toward the app's footprint until they are handed back.
  static func returnFreedPages() {
    malloc_zone_pressure_relief(nil, 0)
  }
}
