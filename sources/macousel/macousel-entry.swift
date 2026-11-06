import SwiftUI

@main
enum MacouselEntry {
  static func main() {
    if let status = EngineWatchdog.run(arguments: Array(CommandLine.arguments.dropFirst())) {
      exit(status)
    }
    if let status = CommandLineClient.run(arguments: Array(CommandLine.arguments.dropFirst())) {
      exit(status)
    }
    MacouselApp.main()
  }
}
