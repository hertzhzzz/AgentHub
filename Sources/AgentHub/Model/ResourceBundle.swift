import Foundation

extension Bundle {
    /// SwiftPM's `Bundle.module` looks beside the .app, but the packaged app keeps
    /// the resource bundle in Contents/Resources. Look there first; fall back to
    /// `.module` for `swift run` and tests.
    static let agentHub: Bundle = {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("AgentHub_AgentHub.bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return .module
    }()
}
