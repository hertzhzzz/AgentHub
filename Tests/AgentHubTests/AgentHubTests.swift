import XCTest
@testable import AgentHub

final class FrontmatterTests: XCTestCase {
    func testFoldedDescriptionAndListTargets() {
        let fm = Frontmatter.parse("""
        ---
        targets:
          - claudecode
          - codexcli
        name: backend-dev
        description: >-
          first line
          second line
        claudecode:
          model: sonnet
        ---
        body text
        """)
        XCTAssertEqual(fm.list("targets"), ["claudecode", "codexcli"])
        XCTAssertEqual(fm.string("name"), "backend-dev")
        XCTAssertEqual(fm.string("description"), "first line second line")
        XCTAssertNil(fm.fields["model"])
        XCTAssertEqual(fm.body, "body text")
    }

    func testStarTarget() {
        let fm = Frontmatter.parse("---\ntargets:\n  - '*'\nname: x\n---\n")
        XCTAssertEqual(fm.list("targets"), ["*"])
    }
}

final class LibraryTests: XCTestCase {
    private func write(_ text: String, _ url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func fixture() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("agenthub-\(UUID().uuidString)")
        try write("""
        {
          // comment
          "targets": {
            "claudecode": ["rules", "commands", "subagents", "skills", "hooks"],
            "codexcli": ["rules", "subagents", "skills"],
            "pi": ["rules", "mcp"]
          }, /* block */ "global": true
        }
        """, root.appendingPathComponent("rulesync.jsonc"))
        try write(#"["hidden-skill"]"#, root.appendingPathComponent("pi-hidden-skills.json"))
        let rs = root.appendingPathComponent(".rulesync")
        try write("---\nname: both\ndescription: >-\n  A shared\n  skill\ntargets:\n  - '*'\n---\n", rs.appendingPathComponent("skills/both/SKILL.md"))
        try write("---\nname: hidden-skill\ndescription: h\ntargets:\n  - codexcli\n---\n", rs.appendingPathComponent("skills/hidden-skill/SKILL.md"))
        try write("---\nname: claude-only\ndescription: c\ntargets:\n  - claudecode\n---\n", rs.appendingPathComponent("skills/claude-only/SKILL.md"))
        try write("---\nname: rev\ndescription: r\ntargets:\n  - '*'\n---\n", rs.appendingPathComponent("subagents/rev.md"))
        try write("---\ntargets:\n  - claudecode\ndescription: cmd\n---\n", rs.appendingPathComponent("commands/ship.md"))
        try write(#"{"mcpServers": {"shared": {"command": "x"}}, "pi": {"mcpServers": {"only-pi": {"url": "https://e.com"}}}}"#, rs.appendingPathComponent("mcp.jsonc"))
        try write(#"{"version":1,"hooks":{"preToolUse":[{"command":"/a/b/run.sh"}]}}"#, rs.appendingPathComponent("hooks.jsonc"))
        return root
    }

    private func item(_ lib: Library, _ kind: ToolKind, _ name: String) -> ToolItem {
        lib.items(of: kind).first { $0.name == name }!
    }

    func testMissingLibraryThrows() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("nope-\(UUID().uuidString)")
        XCTAssertThrowsError(try Library.load(from: url))
    }

    func testSkillsRuleIncludingPiSpecialCase() throws {
        let lib = try Library.load(from: try fixture())
        let both = item(lib, .skills, "both")
        XCTAssertEqual(both.description, "A shared skill")
        XCTAssertEqual(both.support(for: .claudeCode), .enabled)
        XCTAssertEqual(both.support(for: .codex), .enabled)
        XCTAssertEqual(both.support(for: .pi), .enabled)

        let hidden = item(lib, .skills, "hidden-skill")
        XCTAssertEqual(hidden.support(for: .codex), .enabled)
        XCTAssertEqual(hidden.support(for: .pi), .off)
        XCTAssertEqual(hidden.support(for: .claudeCode), .off)

        let claudeOnly = item(lib, .skills, "claude-only")
        XCTAssertEqual(claudeOnly.support(for: .pi), .off)
        XCTAssertEqual(claudeOnly.support(for: .codex), .off)
    }

    func testPiSubagentsUnsupported() throws {
        let lib = try Library.load(from: try fixture())
        let rev = item(lib, .subagents, "rev")
        XCTAssertEqual(rev.support(for: .pi), .unsupported)
        XCTAssertEqual(rev.support(for: .claudeCode), .enabled)
        XCTAssertEqual(rev.support(for: .codex), .enabled)
    }

    func testCommandsMcpHooks() throws {
        let lib = try Library.load(from: try fixture())
        let ship = item(lib, .commands, "ship")
        XCTAssertEqual(ship.support(for: .claudeCode), .enabled)
        XCTAssertEqual(ship.support(for: .codex), .off)

        // Only Pi has the mcp feature; shared server applies to it.
        XCTAssertEqual(item(lib, .mcp, "shared").support(for: .pi), .enabled)
        XCTAssertEqual(item(lib, .mcp, "shared").support(for: .claudeCode), .off)
        XCTAssertEqual(item(lib, .mcp, "only-pi").support(for: .pi), .enabled)

        let hook = item(lib, .hooks, "preToolUse")
        XCTAssertEqual(hook.description, "run.sh")
        XCTAssertEqual(hook.support(for: .claudeCode), .enabled)
        XCTAssertEqual(hook.support(for: .pi), .off)
    }
}
