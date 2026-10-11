struct CommandLineResult: Equatable {
  enum Stream {
    case standardOutput, standardError
  }

  let status: Int32
  let text: String
  let stream: Stream

  static let successStatus: Int32 = 0
  static let failureStatus: Int32 = 1
  static let usageStatus: Int32 = 64

  static func success(_ text: String) -> CommandLineResult {
    CommandLineResult(status: successStatus, text: text, stream: .standardOutput)
  }

  static func failure(_ text: String) -> CommandLineResult {
    CommandLineResult(status: failureStatus, text: text, stream: .standardError)
  }

  static func usage(_ text: String) -> CommandLineResult {
    CommandLineResult(status: usageStatus, text: text, stream: .standardError)
  }
}
