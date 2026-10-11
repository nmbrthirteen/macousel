import Foundation

nonisolated enum UpdateFeedError: UserFacingError, Equatable {
  case noConnection
  case rateLimited
  case unexpectedResponse

  private static let connectionCodes: Set<URLError.Code> = [
    .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost,
    .cannotFindHost, .dnsLookupFailed, .dataNotAllowed,
  ]

  init(mapping error: Error) {
    switch error {
    case let status as HTTPStatusError:
      self = status.code == 403 || status.code == 429 ? .rateLimited : .unexpectedResponse
    case let failure as URLError where Self.connectionCodes.contains(failure.code):
      self = .noConnection
    default:
      self = .unexpectedResponse
    }
  }

  var message: String {
    switch self {
    case .noConnection:
      "Macousel could not reach GitHub. Check your internet connection and try again."
    case .rateLimited:
      "GitHub is limiting requests from this network. Wait an hour, then check again."
    case .unexpectedResponse:
      "GitHub sent a response Macousel could not read. Try again later, or download the latest release from the releases page."
    }
  }
}
