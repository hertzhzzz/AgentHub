import Foundation

/// Reads a rulesync source tree and computes, per item, which agent it is enabled for.
enum LibraryLoader {
    static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".agenthub/library")
    }

    // MARK: Enable rule (pure)

    /// features: the feature names each agent has in rulesync.jsonc.
    static func support(
        kind: ToolKind, agent: Agent, name: String, targets: [String],
        features: [Agent: Set<String>], piHiddenSkills: Set<String>
    ) -> Support {
        if agent == .pi && kind == .subagents { return .unsupported }
        func hasFeature(_ a: Agent) -> Bool { features[a]?.contains(kind.featureKey) ?? false }
        func targeted(_ a: Agent) -> Bool { targets.contains("*") || targets.contains(a.rulesyncKey) }

        if kind == .skills && agent == .pi {
            // Pi reads ~/.agents/skills, which Codex's skills are written to.
            let viaCodex = hasFeature(.codex) && targeted(.codex)
            return viaCodex && !piHiddenSkills.contains(name) ? .enabled : .off
        }
        return hasFeature(agent) && targeted(agent) ? .enabled : .off
    }

    // MARK: Loading

    static func load(from url: URL) throws -> Library {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            throw LibraryError.missing(url)
        }
        let source = url.appendingPathComponent(".rulesync")
        let features = loadFeatures(url.appendingPathComponent("rulesync.jsonc"))
        let hidden = loadHiddenSkills(url.appendingPathComponent("pi-hidden-skills.json"))

        var items: [ToolItem] = []

        // Skills: <name>/SKILL.md
        for dir in subdirectories(source.appendingPathComponent("skills")) {
            let file = dir.appendingPathComponent("SKILL.md")
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let fm = Frontmatter.parse(text)
            let name = fm.string("name").flatMap { $0.isEmpty ? nil : $0 } ?? dir.lastPathComponent
            items.append(makeItem(.skills, name: name, fm: fm, features: features, hidden: hidden))
        }
        // Flat markdown kinds.
        for kind in [ToolKind.subagents, .commands, .rules] {
            for file in markdownFiles(source.appendingPathComponent(kind.rawValue)) {
                guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
                let fm = Frontmatter.parse(text)
                let fileName = file.deletingPathExtension().lastPathComponent
                let name = kind == .commands ? fileName
                    : (fm.string("name").flatMap { $0.isEmpty ? nil : $0 } ?? fileName)
                items.append(makeItem(kind, name: name, fm: fm, features: features, hidden: hidden))
            }
        }
        items += loadMCP(source.appendingPathComponent("mcp.jsonc"), features: features)
        items += loadHooks(source.appendingPathComponent("hooks.jsonc"), features: features)

        items.sort { ($0.kind.rawValue, $0.name.lowercased()) < ($1.kind.rawValue, $1.name.lowercased()) }
        return Library(url: url, items: items)
    }

    private static func makeItem(
        _ kind: ToolKind, name: String, fm: Frontmatter,
        features: [Agent: Set<String>], hidden: Set<String>
    ) -> ToolItem {
        let targets = fm.list("targets") ?? ["*"]
        var desc = fm.string("description") ?? ""
        if desc.isEmpty {
            desc = fm.body.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
                .first(where: { !$0.isEmpty })?.trimmingCharacters(in: CharacterSet(charactersIn: "# ")) ?? ""
        }
        var map: [Agent: Support] = [:]
        for a in Agent.allCases {
            map[a] = support(kind: kind, agent: a, name: name, targets: targets, features: features, piHiddenSkills: hidden)
        }
        return ToolItem(kind: kind, name: name, description: desc, support: map)
    }

    private static func loadFeatures(_ file: URL) -> [Agent: Set<String>] {
        guard let data = try? Data(contentsOf: file),
              let root = JSONC.parse(data) as? [String: Any],
              let targets = root["targets"] as? [String: Any] else { return [:] }
        var out: [Agent: Set<String>] = [:]
        for a in Agent.allCases {
            if let list = targets[a.rulesyncKey] as? [String] { out[a] = Set(list) }
        }
        return out
    }

    private static func loadHiddenSkills(_ file: URL) -> Set<String> {
        guard let data = try? Data(contentsOf: file),
              let list = (try? JSONSerialization.jsonObject(with: data)) as? [String] else { return [] }
        return Set(list)
    }

    private static func loadMCP(_ file: URL, features: [Agent: Set<String>]) -> [ToolItem] {
        guard let data = try? Data(contentsOf: file), let root = JSONC.parse(data) as? [String: Any] else { return [] }
        var servers: [String: (desc: String, agents: Set<Agent>)] = [:]
        func describe(_ cfg: [String: Any]) -> String {
            if let url = cfg["url"] as? String { return url }
            let cmd = cfg["command"] as? String ?? ""
            let args = (cfg["args"] as? [String]) ?? []
            return ([cmd] + args).joined(separator: " ")
        }
        func add(_ block: [String: Any]?, agents: [Agent]) {
            guard let list = block?["mcpServers"] as? [String: Any] else { return }
            for (name, raw) in list {
                var entry = servers[name] ?? ("", [])
                if entry.desc.isEmpty { entry.desc = describe(raw as? [String: Any] ?? [:]) }
                entry.agents.formUnion(agents)
                servers[name] = entry
            }
        }
        add(root, agents: Agent.allCases)
        for a in Agent.allCases { add(root[a.rulesyncKey] as? [String: Any], agents: [a]) }

        return servers.map { name, entry in
            var map: [Agent: Support] = [:]
            for a in Agent.allCases {
                let has = features[a]?.contains("mcp") ?? false
                map[a] = has && entry.agents.contains(a) ? .enabled : .off
            }
            return ToolItem(kind: .mcp, name: name, description: entry.desc, support: map)
        }
    }

    private static func loadHooks(_ file: URL, features: [Agent: Set<String>]) -> [ToolItem] {
        guard let data = try? Data(contentsOf: file),
              let root = JSONC.parse(data) as? [String: Any],
              let hooks = root["hooks"] as? [String: Any] else { return [] }
        var map: [Agent: Support] = [:]
        for a in Agent.allCases { map[a] = (features[a]?.contains("hooks") ?? false) ? .enabled : .off }
        return hooks.map { event, raw in
            let entries = raw as? [[String: Any]] ?? []
            let cmds = entries.compactMap { $0["command"] as? String }
            var desc = cmds.first.map { ($0 as NSString).lastPathComponent } ?? ""
            if cmds.count > 1 { desc += " +\(cmds.count - 1)" }
            return ToolItem(kind: .hooks, name: event, description: desc, support: map)
        }
    }

    private static func subdirectories(_ url: URL) -> [URL] {
        let items = (try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        return items.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
    }

    private static func markdownFiles(_ url: URL) -> [URL] {
        let items = (try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        return items.filter { $0.pathExtension == "md" }
    }
}

extension Library {
    static func load(from url: URL) throws -> Library { try LibraryLoader.load(from: url) }
}
