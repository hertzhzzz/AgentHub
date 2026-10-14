# 用一行 curl 脚本安装预编译 App，不走 Homebrew，也不做苹果签名

用户（包括作者本人）的安装方式是 `curl -fsSL …/install.sh | bash`。脚本从 GitHub Releases 下载预编译、通用架构（arm64 + x86_64）、只做了 ad-hoc 签名的 AgentHub.app，放进“应用程序”文件夹。App 内置 rulesync 的独立二进制，所以用户不需要装 Node。更新由 App 自己完成：去 GitHub 查新版并一键替换。

## 为什么

- **实测（2026-10-14，macOS 26.6.2）**：curl 下载的文件只带 `com.apple.provenance`，不带 `com.apple.quarantine`。所以 ad-hoc 签名的 App 尽管被 `spctl` 判为 rejected，依然能直接双击打开，不出现任何提示。
- **Homebrew 7 已经去掉了 `--no-quarantine`**，并宣布从 2026-09-01 起停止支持通不过 Gatekeeper 的 cask。没有签名的话，走 brew 安装反而会被拦下。
- 要拿到苹果签名需要每年 99 美元的开发者计划；作者选择暂时不付。
- 让用户从源码编译要装完整的 Xcode（约 15GB），会把大多数人挡在门外。

## 后果

- 安装说明里要写清楚脚本做了什么，好让看到 `curl | bash` 就有顾虑的用户先看一遍内容。
- App 自己下载更新包时，同样不能让下载结果带上 quarantine（App 不开沙盒，用 URLSession 下载）——这一点做更新功能时要实测。
- 以后如果加入苹果开发者计划，可以在不改安装命令的前提下补上签名和公证。
