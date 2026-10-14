# AgentHub

**一个地方，管好你所有 AI 编程助手的技能、MCP 和规则。**

[English](README.md) · 简体中文

## 为什么做它

你同时在用 Claude Code、Codex 和 Pi。每个助手都存着自己那一份技能、MCP 和规则。时间一长，几份内容各改各的，重复越堆越多，谁知道什么，没人说得清。

AgentHub 只保留一个库。你决定每个助手用什么，它们就拿到什么，不多不少。

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/hertzhzzz/AgentHub/main/scripts/install.sh | bash
```

它会下载适合你这台 Mac 的应用，放进“应用程序”，然后打开。

<details>
<summary>安装脚本到底做了什么？</summary>

1. 确认你的系统是 macOS 14 或更新，并按你的芯片选对版本。
2. 从本项目的 GitHub Releases 下载应用和校验文件。
3. 核对校验值。对不上就不安装。
4. 如果 AgentHub 正在运行，先退出，再把应用复制到 `/Applications`（不可写时放到 `~/Applications`）。
5. 打开应用。

全程不要密码，不用 `sudo`。应用没有经过 Apple 公证；以这种方式下载，macOS 会直接打开它，不弹警告。

</details>

卸载：

```bash
curl -fsSL https://raw.githubusercontent.com/hertzhzzz/AgentHub/main/scripts/install.sh | bash -s -- --uninstall
```

你的工具库 `~/.agenthub` 会保留。

## 现状

v0.1 是只读预览：显示每个助手现在能看到什么，不会改动任何东西。

接下来：

- 按助手开关每个工具
- 按项目单独设置
- 密钥存进钥匙串
- 插件
- 把工具库备份到 GitHub
- 支持更多助手：Antigravity CLI、DeepSeek Harness、OpenCode、Cursor、Cline

## 它怎么工作

AgentHub 由 [rulesync](https://github.com/dyoshikawa/rulesync)（MIT）驱动，由它负责把内容写进各个助手的文件。你的工具库在 `~/.agenthub/library`。

## 系统要求

macOS 14 或更新，Apple 芯片或 Intel 都行。

## 从源码构建

```bash
swift build
swift test
scripts/build-app.sh arm64
```

## 公开开发

进展记在 [开发日志](docs/devlog.md)（英文）。

## 许可证

[MIT](LICENSE)
