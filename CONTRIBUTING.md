# 贡献指南（ai-agent-hub-zh）

## 加一个项目

在 `data/tools.json` 末尾补一条，字段如下：

```json
{
  "category": "编码代理",          // 编码代理 / 破甲 Harness / Skills 库 / 免费额度网关 / 代理中转
  "name": "项目名",
  "platform": "Windows / macOS / Linux",
  "notes": "一句话说明它干嘛、为什么值得收",
  "url": "https://github.com/owner/repo",
  "cn_friendly": "direct",        // direct=墙内直连可达 / proxy=需代理 / 留空=未知
  "deploy": "安装或部署命令",
  "status": "ok",                  // ok / unknown / dead（首次提交填 ok）
  "last_checked": "2026-11-04",
  "checked_from": "seed"
}
```

## 字段约束

- `url` 必须是以 `http(s)://` 开头的官方地址，不要第三方镜像；
- `cn_friendly` 只填你**亲自验证过**的结果，不确定就留空；
- `status` 由每周体检脚本自动回写，不要手动改它来"掩盖"死链。

## 提交前

```powershell
pwsh scripts/check_links.ps1        # 本地预检，确认 JSON 能被正常读写
pwsh scripts/render.ps1             # 确认 docs/index.html 能重新生成
```

## 链接失效怎么办

跑一次 `pwsh scripts/check_links.ps1 -ProxyUrl 127.0.0.1:7897`，把对应 `status` 的变化一起提 PR。不要只改 README 不更新 `data/`。
