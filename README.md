<div align="center">

# 🤖 AI Agent 工坊 · 中文资源导航

**编码代理 / 破甲 Harness / Skills 库 / 免费额度网关 / 代理中转 —— 一站式中文索引**

> 每个项目附：官方地址、国内直连友好度、一键部署命令、每周自动体检（链接存活 + 上游更新检测）。

**📖 在线读**：https://yanwaiyue-name.github.io/ai-agent-hub-zh/

[English](README.en.md) ｜ **中文**

![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/状态-维护中-blue)
[![validate-pr](https://github.com/yanwaiyue-name/ai-agent-hub-zh/actions/workflows/validate-pr.yml/badge.svg)](https://github.com/yanwaiyue-name/ai-agent-hub-zh/actions/workflows/validate-pr.yml)

</div>

---

## 目录

- [这个仓库解决什么](#这个仓库解决什么)
- [三种入口](#-三种入口)
- [分类速查](#-分类速查)
- [自动体检怎么跑](#-自动体检怎么跑)
- [数据字段说明](#-数据字段说明)
- [想加项目 / 报错](#-想加项目--报错)
- [同类项目](#同类项目)
- [免责](#️-免责)

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

## ⚡ 分类速查

| 分类 | 一句话 |
| --- | --- |
| 编码代理 | Claude Code / Codex / OpenCode 等本机编码智能体 |
| 破甲 Harness | DeepSeek Harness 生态与人格重塑配置 |
| Skills 库 | 即插即用的 Agent Skills 集合 |
| 免费额度网关 | 把免费模型/额度接进编码代理 |
| 代理 / 中转 | 国内直连友好的客户端与中转 |

> 网页版支持**关键词搜索、分类筛选、只看存活、按 star 排序**。完整字段见 [data/tools.json](data/tools.json)。

---

## 🩺 自动体检怎么跑

复用 `airport-nav` 的周巡检模式（两振出局 + 异地复核，避免网络抖动误杀活站）：

```powershell
# 本地预检（无响应不判死，只标 unknown）
pwsh scripts/check_links.ps1

# 只探测前 3 条，用于快速验证脚本（不会截断数据文件）
pwsh scripts/check_links.ps1 -MaxItems 3

# 指定本机代理做复核口径（Clash 等）
pwsh scripts/check_links.ps1 -ProxyUrl 127.0.0.1:7897

# 上游更新检测：拉取 star / 最近 push / 归档状态
pwsh scripts/sync-upstream.ps1

# 提交前校验（字段 / URL / 枚举 / 去重）
pwsh scripts/validate.ps1
```

每周六 03:00 UTC（北京周六 11:00）由 GitHub Actions 自动跑一轮，顺序为
**校验 → 上游同步 → 链接体检 → 重新渲染网页 → 提交 → 部署 Pages**。
每个改动 `data/` 的 PR 还会触发 `validate-pr.yml`，不合格直接挡下（对标 [public-apis](https://github.com/public-apis/public-apis) 的做法）。

---

## 🧾 数据字段说明

| 字段 | 含义 |
| --- | --- |
| `category` / `name` / `platform` / `notes` / `url` / `deploy` | 手写：分类、名称、平台、说明、官方地址、部署命令 |
| `cn_friendly` | `direct` 墙内直连 / `proxy` 需代理 / 留空 未验证 |
| `status` | 体检产出：`ok` / `unknown` / `dead` |
| `http_code` / `final_url` / `last_checked` / `checked_from` | 体检产出：HTTP 码、最终跳转、日期、运行位置 |
| `reachable_via` | 体检产出：`direct` / `proxy`，记录从哪条通道探到 |
| `stars` / `pushed_at` / `archived` / `synced_at` | 上游同步产出：star 数、最近 push、是否归档、同步日期 |

**手写字段与自动生成字段分得清清楚楚**：你只改前面几列，后面由脚本回写，别手改 `status` 来掩盖死链。

---

## 📥 想加项目 / 报错

- 加项目：照 `data/tools.json` 的字段补一条，提 PR；
- 链接失效：跑一次体检，把 `data/tools.json` 里对应 `status` 的变化一起提上来；
- 字段说明见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 同类项目

| 项目 | 规模 | 本仓库与它的差异 |
| --- | --- | --- |
| [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | 78k | 英文、按场景分；本仓库补中文语境 + 国内网络标记 + 自动体检 |
| [VoltAgent/awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills) | 53k | 只收 OpenClaw skills；本仓库跨编码代理 / 破甲 / 网关 |
| [public-apis](https://github.com/public-apis/public-apis) | 495k | 列表类校验的黄金标准，本仓库借鉴了它的 PR 触发 build 校验 |
| [free-for-dev](https://github.com/ripienaar/free-for-dev) | 141k | 免费额度资源，但无国内网络口径 |
| [1c7/chinese-independent-developer](https://github.com/1c7/chinese-independent-developer) | 62k | 中文独立开发者列表，无链接体检 |

---

## ⚠️ 免责

破甲类 / Harness 类项目仅供个人学习与研究。请遵守所在地区的法律法规与所用服务的服务条款，勿用于未授权用途。本仓库不托管任何绕过授权的内容，只做索引。
