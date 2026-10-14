# 术语表

## Agent
Claude Code、Codex、Pi、Antigravity CLI、DeepSeek Harness、OpenCode、Cursor、Cline 这类会读取工具来干活的 AI 编程助手。
不要叫它“工具”或“AI 工具”，这两个词留给 **工具**。英文资料里叫 Harness。

## 工具
装给 Agent 用的东西。类型有：skill、MCP、规则（CLAUDE.md / AGENTS.md 这类说明文件）、hook、命令、子 agent、权限。
插件（Claude 插件、Codex 插件、Pi package）是各家 Agent 自己的打包格式，不算工具，单独叫 **插件**。

## 工具库
所有工具唯一的一份原件。Agent 文件夹里出现的都是从工具库生成的，不能直接改。

## 外部管理
自带安装程序、会给每个 Agent 写不同版本的工具（如 impeccable）。不进工具库，由它自己安装和更新；AgentHub 只显示，不合并也不删除。

## 开给
把工具库里的一个工具交给某个 Agent 使用。反义词是“关掉”。工具留在工具库里，只是这个 Agent 不再看到它。

## 全局
对这台电脑上所有项目都生效的那一层。

## 项目
只对一个代码文件夹生效的那一层。项目在全局的基础上加工具，或者关掉全局的工具。
