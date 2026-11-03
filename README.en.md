<div align="center">

# 🤖 AI Agent Workshop · Chinese Resource Hub

**A curated, Chinese-context index of coding agents / jailbreak harnesses / skills libraries / free-tier gateways / proxy tools — with one-click deploy and weekly auto-health-checks.**

**📖 Read online**: https://yanwaiyue-name.github.io/ai-agent-hub-zh/

[中文](README.md) ｜ **English**

</div>

---

## What this repo solves

Three pain points for Chinese users playing with AI coding agents / jailbreak harnesses / skills:

1. **Hard to find** — good projects are buried under English search dominance.
2. **Hard to install** — most tutorials assume a clean network; domestic users stall on step one.
3. **Hard to know if it's dead** — proxy / harness projects iterate fast; yesterday's link may 404 today.

This repo curates projects that actually work in a Chinese context, marks which network path each needs, ships one-click deploy scripts, and runs a weekly health-check that flags dead links.

> This repo contains **index + scripts + data only**. All content links to official upstreams.

## Categories

| Category | Count | What |
| --- | --- | --- |
| Coding Agents | 8 | Claude Code / Codex / OpenCode and friends |
| Jailbreak Harness | 7 | DeepSeek Harness ecosystem & persona configs |
| Skills Libraries | 7 | Plug-and-play Agent Skills collections |
| Free-tier Gateways | 5 | Wire free models / quotas into coding agents |
| Proxy / Relay | 3 | China-friendly clients & relays |

See [data/tools.json](data/tools.json) and the rendered [docs/index.html](docs/index.html).

## Health-check

```powershell
pwsh scripts/check_links.ps1                       # local pre-check
pwsh scripts/check_links.ps1 -ProxyUrl 127.0.0.1:7897  # with local proxy
pwsh scripts/check_links.ps1 -Runner github-actions -SecondOpinion  # CI
```

Runs automatically every Saturday 03:00 UTC (Beijing Saturday 11:00) via GitHub Actions.

## Disclaimer

Jailbreak / harness projects are for personal study and research only. Comply with your local laws and the ToS of the services you use. This repo hosts no circumvention content — index only.
