import Foundation

struct EngineLaunch: Equatable {
  let executable: URL
  let arguments: [String]
  let environment: [String: String]

  static func daemon(
    helper: URL, paths: EnginePaths, service: String, base: [String: String]
  ) -> EngineLaunch {
    let overrides = [
      "PANERU_CONFIG": paths.config.path,
      EngineService.variable: service,
      "XDG_STATE_HOME": paths.state.path,
      "XDG_CONFIG_HOME": paths.configHome.path,
      "NO_COLOR": "1",
      "RUST_LOG": "info",
    ]
    return EngineLaunch(
      executable: helper, arguments: [],
      environment: base.merging(overrides) { _, override in override })
  }
}
