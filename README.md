# AgentHub

**One place to manage the skills, MCP servers, and rules your AI coding agents use.**

English · [简体中文](README.zh-CN.md)

## Why

You use Claude Code, Codex and Pi. Each one keeps its own copy of your skills, MCP servers and rules. Over time the copies drift apart, pile up duplicates, and nobody remembers which agent knows what.

AgentHub keeps one library. You choose what each agent gets, and each agent gets exactly that.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/hertzhzzz/AgentHub/main/scripts/install.sh | bash
```

It downloads the app for your Mac, puts it in Applications, and opens it.

<details>
<summary>What does the installer do?</summary>

1. Checks you are on macOS 14 or newer and picks the right build for your chip.
2. Downloads the app and a checksum file from this project's GitHub Releases.
3. Verifies the checksum. If it does not match, nothing is installed.
4. Quits AgentHub if it is running, then copies the app to `/Applications` (or `~/Applications` if that is not writable).
5. Opens the app.

It never asks for your password and never uses `sudo`. The app is not notarized by Apple. Because it is downloaded this way, macOS opens it directly without a warning.

</details>

To remove it:

```bash
curl -fsSL https://raw.githubusercontent.com/hertzhzzz/AgentHub/main/scripts/install.sh | bash -s -- --uninstall
```

Your tool library at `~/.agenthub` is kept.

## Status

v0.1 is a read-only preview: it shows what each agent can see today, and changes nothing.

Coming next:

- Turn tools on or off for each agent
- Per-project settings
- Keys stored in the Keychain
- Plugins
- Back up your library to GitHub
- More agents: Antigravity CLI, DeepSeek Harness, OpenCode, Cursor, Cline

## How it works

AgentHub is powered by [rulesync](https://github.com/dyoshikawa/rulesync) (MIT), which does the heavy lifting of writing each agent's files. Your library lives at `~/.agenthub/library`.

## Requirements

macOS 14 or newer, on Apple silicon or Intel.

## Build from source

```bash
swift build
swift test
scripts/build-app.sh arm64
```

## Built in public

Follow the progress in the [devlog](docs/devlog.md).

## License

[MIT](LICENSE)
