import SwiftUI

struct ItemListView: View {
    @Environment(AppModel.self) private var model
    let kind: ToolKind
    @State private var query = ""

    private var items: [ToolItem] {
        let all = model.library?.items(of: kind) ?? []
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.description.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .searchable(text: $query, prompt: Text("Search", bundle: .agentHub))
        .overlay {
            if items.isEmpty {
                if query.isEmpty {
                    ContentUnavailableView(kind.title, systemImage: kind.symbol)
                } else {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
    }
}

struct ItemRow: View {
    let item: ToolItem

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            Spacer(minLength: 12)
            HStack(spacing: 6) {
                ForEach(Agent.allCases) { agent in
                    AgentBadge(agent: agent, support: item.support(for: agent), kind: item.kind)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct AgentBadge: View {
    let agent: Agent
    let support: Support
    let kind: ToolKind

    private var tint: Color {
        switch agent {
        case .claudeCode: Color(red: 0.85, green: 0.45, blue: 0.27)
        case .codex: Color(red: 0.13, green: 0.62, blue: 0.50)
        case .pi: Color(red: 0.47, green: 0.36, blue: 0.95)
        }
    }

    var body: some View {
        Text(agent.displayName)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .frame(minWidth: 70)
            .foregroundStyle(foreground)
            .background(Capsule().fill(support == .enabled ? tint : .clear))
            .overlay(
                Capsule().strokeBorder(
                    support == .enabled ? Color.clear : Color.secondary.opacity(support == .unsupported ? 0.35 : 0.55),
                    style: StrokeStyle(lineWidth: 1, dash: support == .unsupported ? [3, 2] : [])
                )
            )
            .opacity(support == .unsupported ? 0.6 : 1)
            .help(help)
            .accessibilityLabel("\(agent.displayName), \(stateText)")
    }

    private var foreground: Color {
        switch support {
        case .enabled: .white
        case .off: .secondary
        case .unsupported: .secondary.opacity(0.7)
        }
    }

    private var stateText: String {
        switch support {
        case .enabled: String(localized: "Enabled", bundle: .agentHub)
        case .off: String(localized: "Off", bundle: .agentHub)
        case .unsupported: String(localized: "Doesn't support", bundle: .agentHub)
        }
    }

    private var help: String {
        if support == .unsupported {
            return String(localized: "Pi doesn't support subagents", bundle: .agentHub)
        }
        return "\(agent.displayName): \(stateText)"
    }
}
