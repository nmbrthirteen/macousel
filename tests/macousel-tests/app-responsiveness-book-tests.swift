import Testing
import os

@testable import WindowSystem

struct AppResponsivenessBookTests {
  private final class Changes: Sendable {
    private let recorded = OSAllocatedUnfairLock(initialState: [String]())

    var all: [String] { recorded.withLock { $0 } }

    func append(_ change: String) {
      recorded.withLock { $0.append(change) }
    }
  }

  private func observed(by book: AppResponsivenessBook) -> Changes {
    let changes = Changes()
    book.observe { bundle, isSlow in changes.append("\(bundle) \(isSlow)") }
    return changes
  }

  @Test func aSeededBundleStartsSlowOnItsFirstProcess() {
    let book = AppResponsivenessBook()
    book.seed(["com.example.slow"])

    #expect(book.isSlow(10, bundleIdentifier: "com.example.slow"))
    #expect(!book.isSlow(11, bundleIdentifier: "com.example.fast"))
    #expect(!book.isSlow(12, bundleIdentifier: nil))
  }

  @Test func aSeededAppRecoversAfterFiveQuickSetsAndReportsIt() {
    let book = AppResponsivenessBook()
    book.seed(["com.example.slow"])
    let changes = observed(by: book)

    for _ in 0..<(AppResponsiveness.recoveryStreakLength - 1) {
      _ = book.record(10, bundleIdentifier: "com.example.slow", milliseconds: 2)
    }
    #expect(book.isSlow(10, bundleIdentifier: "com.example.slow"))
    let change = book.record(10, bundleIdentifier: "com.example.slow", milliseconds: 2)

    #expect(change == AppResponsivenessBook.Change(bundleIdentifier: "com.example.slow", isSlow: false))
    #expect(!book.isSlow(10, bundleIdentifier: "com.example.slow"))
    #expect(changes.all == ["com.example.slow false"])
  }

  @Test func aStalledSetReportsTheAppAsSlow() {
    let book = AppResponsivenessBook()
    let changes = observed(by: book)

    _ = book.record(10, bundleIdentifier: "com.example.app", milliseconds: 2)
    _ = book.record(
      10, bundleIdentifier: "com.example.app",
      milliseconds: AppResponsiveness.slowSingleSetMilliseconds)

    #expect(changes.all == ["com.example.app true"])
  }

  @Test func anAppWithoutABundleIdentifierIsClassifiedButNeverReported() {
    let book = AppResponsivenessBook()
    let changes = observed(by: book)

    let change = book.record(
      10, bundleIdentifier: nil, milliseconds: AppResponsiveness.slowSingleSetMilliseconds)

    #expect(change == AppResponsivenessBook.Change(bundleIdentifier: nil, isSlow: true))
    #expect(changes.all.isEmpty)
  }
}
