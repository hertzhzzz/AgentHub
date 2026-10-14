# 用 rulesync 做引擎，自己写原生 Mac App，不改 Skills Manager

AgentHub 由一个轻量原生 macOS App 和背后的 rulesync 组成。App 只负责界面、钥匙串和插件命令；工具库就是一份 rulesync 源文件，放在用户自己的私有 git 仓库里。App 的代码则放在公开的开源仓库里，两者永远分开。

## 考虑过的方案

- **改 Skills Manager**（MIT 协议，Tauri，6.2k 星）：界面是现成的。但它有自己的中央工具库（`~/.skills-manager`），和 rulesync 的源文件会变成两份需要同步的原件。代码量大（Rust 约 1.7MB），上游更新很频繁，长期合并成本高。而且它只管 skills。
- **只用 CC Switch**：管不了 hooks、子 agent、命令。它的“项目”只是整套配置的快照切换，不是项目里真正的文件。
- **从零写格式转换**：要重做 rulesync 已经覆盖 8 个 Agent、7 类工具的工作。

## 后果

- 每个 Agent 能做什么，以 rulesync 的支持表为准；rulesync 做不到的格子在 App 里显示为灰色，不另外自研绕路。
- 插件不经过 rulesync，App 直接调各 Agent 的官方插件命令。
- rulesync 以官方发布的 macOS 独立二进制（arm64 / x64）内置在 App 里，用户不需要装 Node.js（见 ADR 0002）。
