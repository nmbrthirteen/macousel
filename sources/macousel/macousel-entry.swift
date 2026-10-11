import Foundation

@main
enum MacouselEntry {
  static func main() {
    if let status = CommandLineClient.run(arguments: Array(CommandLine.arguments.dropFirst())) {
      exit(status)
    }
    MacouselApp.main()
  }
}
