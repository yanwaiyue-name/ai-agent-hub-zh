<div align="center">

# 🤖 AI Agent 工坊 · 中文资源导航

**编码代理 / 破甲 Harness / Skills 库 / 免费额度网关 / 代理中转 —— 一站式中文索引**

> 每个项目附：官方地址、国内直连友好度、一键部署命令、每周自动体检（链接存活 + 上游更新检测）。

**📖 在线读**：https://yanwaiyue-name.github.io/ai-agent-hub-zh/

[English](README.en.md) ｜ **中文**

![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/状态-维护中-blue)
![Entries](https://img.shields.io/badge/条目-30%2B-blue)

</div>

---

## 这个仓库解决什么

中文圈玩 AI 编码代理 / 破甲 / Skills，痛点就三个：

1. **找不到** —— 好项目散在 GitHub 各处，搜索被英文霸权淹没；
2. **装不上** —— 大部分教程默认你有干净网络，国内一步卡死；
3. **不知道死没死** —— 代理类、破甲类项目迭代极快，昨天能用的今天可能 404。

本仓库做四件事：**整理中文语境下真正在用的项目**、**标注该走哪条网络通道**、**给一键部署脚本**、**每周自动体检把死链标红**。

> 本仓库只包含「索引 + 脚本 + 数据」，不含任何安装包或敏感配置本体。所有内容指向官方上游。

---

## 🚪 三种入口

| 你是 | 点这里 | 说明 |
| --- | --- | --- |
| **只想看看有哪些项目** | [清单.html](docs/index.html) · [在线查看](https://yanwaiyue-name.github.io/ai-agent-hub-zh/) | 单文件网页，下载后双击即开 |
| **想看结构化数据** | [data/tools.json](data/tools.json) | 机器可读，可被你自己的脚本消费 |
| **想跑自动体检** | 双击 `scripts/check_links.ps1` 或见下方 Actions | 本地/CI 都能跑 |

---

## ⚡ 分类速查（30+ 项目）

| 分类 | 数量 | 一句话 |
| --- | --- | --- |
| 编码代理 | 8 | Claude Code / Codex / OpenCode 等本机编码智能体 |
| 破甲 Harness | 7 | DeepSeek Harness 生态与人格重塑配置 |
| Skills 库 | 7 | 即插即用的 Agent Skills 集合 |
| 免费额度网关 | 5 | 把免费模型/额度接进编码代理 |
| 代理 / 中转 | 3 | 国内直连友好的客户端与中转 |

> 完整条目、部署命令、国内网络标记见 [data/tools.json](data/tools.json) 与渲染后的 [docs/index.html](docs/index.html)。

---

## 🩺 自动体检怎么跑

复用 `airport-nav` 的周巡检模式（两振出局 + 异地复核，避免网络抖动误杀活站）：

```powershell
# 本地预检（无响应不判死，只标 unknown）
pwsh scripts/check_links.ps1

# 指定本机代理做复核口径（Clash 等）
pwsh scripts/check_links.ps1 -ProxyUrl 127.0.0.1:7897

# CI 环境（无响应判死，加异地复核）
pwsh scripts/check_links.ps1 -Runner github-actions -SecondOpinion
```

每周六 03:00 UTC（北京周六 11:00）由 GitHub Actions 自动跑一轮并回写结果。

---

## 📥 想加项目 / 报错

- 加项目：照 `data/tools.json` 的字段补一条，提 PR；
- 链接失效：跑一次体检，把 `data/tools.json` 里对应 `status` 的变化一起提上来；
- 字段说明见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## ⚠️ 免责

破甲类 / Harness 类项目仅供个人学习与研究。请遵守你所在地区的法律法规与所用服务的服务条款，不要用于 unauthorized 用途。本仓库不托管任何绕过授权的内容，只做索引。
