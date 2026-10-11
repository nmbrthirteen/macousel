import CoreGraphics
import Foundation
import Testing

@testable import Macousel

@Suite(.fixtureScope) @MainActor
struct SlowAppMemoryTests {
  private func storedSlowApps(_ suite: IsolatedDefaults) -> Set<String> {
    SlowAppStore(defaults: suite.defaults).load()
  }

  @Test func anAppMarkedSlowStartsSlowInTheNextLaunch() throws {
    let suite = try IsolatedDefaults()
    let first = try ControllerFixture(suite: suite)
    let window = first.open(1, app: .browser, activating: true)
    first.launch()
    first.placer.setSlow(true, forAppOf: window)
    first.quit()

    let second = try ControllerFixture(suite: suite)
    let reopened = second.open(1, app: .browser, activating: true)
    let other = second.open(2, app: .editor)
    second.launch()

    #expect(second.placer.isSlowApp(of: reopened))
    #expect(!second.placer.isSlowApp(of: other))
    #expect(storedSlowApps(suite) == [FakeApp.browser.bundleIdentifier])
  }

  @Test func aSeededSlowAppThatRecoversIsRemovedFromTheStore() throws {
    let suite = try IsolatedDefaults()
    let first = try ControllerFixture(suite: suite)
    let window = first.open(1, app: .browser, activating: true)
    first.launch()
    first.placer.setSlow(true, forAppOf: window)
    first.quit()
    let second = try ControllerFixture(suite: suite)
    let reopened = second.open(1, app: .browser, activating: true)
    second.launch()

    second.placer.setSlow(false, forAppOf: reopened)

    #expect(!second.placer.isSlowApp(of: reopened))
    #expect(storedSlowApps(suite).isEmpty)
  }

  @Test func theStoreKeepsOnlyTheFiftyMostRecentApps() throws {
    let suite = try IsolatedDefaults()
    let store = SlowAppStore(defaults: suite.defaults)

    for index in 0..<(SlowAppStore.capacity + 10) {
      store.record("app.\(index)", isSlow: true)
    }

    let kept = store.load()
    #expect(kept.count == SlowAppStore.capacity)
    #expect(!kept.contains("app.0"))
    #expect(kept.contains("app.\(SlowAppStore.capacity + 9)"))
  }

  @Test func recordingAnAppTwiceKeepsOneEntryAndRecoveryRemovesIt() throws {
    let suite = try IsolatedDefaults()
    let store = SlowAppStore(defaults: suite.defaults)

    store.record("app.one", isSlow: true)
    store.record("app.one", isSlow: true)
    #expect(store.load() == ["app.one"])
    store.record("app.one", isSlow: false)

    #expect(store.load().isEmpty)
  }

  @Test func recoveringAnUnknownAppChangesNothing() throws {
    let suite = try IsolatedDefaults()
    let store = SlowAppStore(defaults: suite.defaults)
    store.record("app.one", isSlow: true)

    store.record("app.two", isSlow: false)

    #expect(store.load() == ["app.one"])
  }
}
