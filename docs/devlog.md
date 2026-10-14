# AgentHub devlog

Newest first.

## 2026-10-14 — Day 1, later: v0.1 ships

- AgentHub v0.1.1 is out. Install with one line: `curl -fsSL https://raw.githubusercontent.com/hertzhzzz/AgentHub/main/scripts/install.sh | bash`.
- What it does today: a read-only view of your tool library. Skills, subagents, commands, rules, MCP servers and hooks, each with a badge showing whether Claude Code, Codex and Pi get it. English and Chinese UI.
- GitHub Actions builds an Apple silicon and an Intel version on every tag and attaches them to the release with checksums.
- v0.1.0 crashed on launch. SwiftPM's `Bundle.module` looks for resources next to the `.app`, not inside it, and on the build machine it quietly fell back to the build folder, so local tests passed. Fix: look in `Contents/Resources` first. Lesson: test the packaged app with the build folder moved away.
- Next: in-app updates, then turning tools on and off per agent.

## 2026-10-14 — Day 1: research and the plan

- Surveyed the existing managers: CC Switch, Skills Manager, vercel skills and rulesync. Each solves part of the problem; none gives one library with per-agent control in a native app.
- Decision: use rulesync as the engine and build a native macOS app on top of it, instead of writing a sync engine from scratch.
- Tested rulesync against Claude Code, Codex and Pi in a sandbox. Skills, MCP servers and rules all generated correctly for each agent.
- Gotchas found: `--delete` removes skills it does not manage; the MCP and hooks sections are replaced wholesale rather than merged; Pi reads skills from two places and can see them twice; Codex does not expand `${VAR}` in MCP config.
- Consolidated the author's own setup: 80 live skills, duplicates removed, and every agent still sees the same set as before.
- Distribution: a one-line installer that downloads from GitHub Releases. Homebrew dropped support for apps that fail Gatekeeper, and files fetched with curl are not quarantined, so the app opens directly.
- Next: v0.1, a read-only preview that shows what each agent currently sees.
