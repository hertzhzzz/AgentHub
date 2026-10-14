import Foundation

enum Agent: String, CaseIterable, Identifiable, Hashable {
    case claudeCode, codex, pi

    var id: String { rawValue }

    /// Key used in rulesync.jsonc and per-agent MCP blocks.
    var rulesyncKey: String {
        switch self {
        case .claudeCode: "claudecode"
        case .codex: "codexcli"
        case .pi: "pi"
        }
    }

    var displayName: String {
        switch self {
        case .claudeCode: "Claude Code"
        case .codex: "Codex"
        case .pi: "Pi"
        }
    }
}

enum ToolKind: String, CaseIterable, Identifiable, Hashable {
    case skills, subagents, commands, rules, mcp, hooks

    var id: String { rawValue }

    /// Feature name used in rulesync.jsonc.
    var featureKey: String { rawValue }

    var symbol: String {
        switch self {
        case .skills: "sparkles"
        case .subagents: "person.2"
        case .commands: "terminal"
        case .rules: "list.bullet.rectangle"
        case .mcp: "server.rack"
        case .hooks: "link"
        }
    }

    var title: String {
        switch self {
        case .skills: String(localized: "Skills", bundle: .agentHub)
        case .subagents: String(localized: "Subagents", bundle: .agentHub)
        case .commands: String(localized: "Commands", bundle: .agentHub)
        case .rules: String(localized: "Rules", bundle: .agentHub)
        case .mcp: String(localized: "MCP", bundle: .agentHub)
        case .hooks: String(localized: "Hooks", bundle: .agentHub)
        }
    }
}

enum Support: Equatable {
    case enabled
    case off
    case unsupported
}

struct ToolItem: Identifiable, Equatable {
    let kind: ToolKind
    let name: String
    let description: String
    let support: [Agent: Support]

    var id: String { "\(kind.rawValue)/\(name)" }

    func support(for agent: Agent) -> Support { support[agent] ?? .off }
}

struct Library: Equatable {
    var url: URL
    var items: [ToolItem]

    func items(of kind: ToolKind) -> [ToolItem] { items.filter { $0.kind == kind } }
    func count(of kind: ToolKind) -> Int { items(of: kind).count }
}

enum LibraryError: Error, Equatable {
    case missing(URL)
}
