<#
ai-agent-hub-zh 渲染：从 data/tools.json 生成单文件 docs/index.html（不联网可用）
#>
[CmdletBinding()]
param([string]$DataPath, [string]$OutPath)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
if (-not $DataPath) { $DataPath = Join-Path $root 'data/tools.json' }
if (-not $OutPath)  { $OutPath  = Join-Path $root 'docs/index.html' }

$tools = @(Get-Content -LiteralPath $DataPath -Raw -Encoding UTF8 | ConvertFrom-Json)

function Html-Escape($s) {
    ($s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;')
}

$rows = New-Object System.Collections.Generic.List[string]
$catRows = @{}
foreach ($t in $tools) {
    $status = [string]$t.status
    $badge = switch ($status) {
        'ok'     { '<span class="ok">✅ 存活</span>' }
        'dead'   { '<span class="dead">❌ 失效</span>' }
        default  { '<span class="unk">⚠️ 未验证</span>' }
    }
    $cn = [string]$t.cn_friendly
    $cnBadge = switch ($cn) {
        'direct' { '<span class="cn direct">墙内直连</span>' }
        'proxy'  { '<span class="cn proxy">需代理</span>' }
        default  { '<span class="cn">—</span>' }
    }
    $deploy = if ([string]$t.deploy) { '<code>' + (Html-Escape [string]$t.deploy) + '</code>' } else { '—' }
    $cat = [string]$t.category
    if (-not $catRows.ContainsKey($cat)) { $catRows[$cat] = New-Object System.Collections.Generic.List[string] }
    $catRows[$cat].Add(@"
    <tr>
      <td><a href="$([string]$t.url)" target="_blank" rel="noopener">$(Html-Escape [string]$t.name)</a></td>
      <td>$(Html-Escape $cat)</td>
      <td>$(Html-Escape [string]$t.platform)</td>
      <td>$(Html-Escape [string]$t.notes)</td>
      <td>$deploy</td>
      <td>$cnBadge</td>
      <td>$badge</td>
    </tr>
"@)
}

$sections = New-Object System.Collections.Generic.List[string]
foreach ($kv in $catRows.GetEnumerator()) {
    $sections.Add(@"
  <h2>$($kv.Key) <span class="count">$($kv.Value.Count)</span></h2>
  <table>
    <thead><tr><th>项目</th><th>分类</th><th>平台</th><th>说明</th><th>一键部署</th><th>国内网络</th><th>状态</th></tr></thead>
    <tbody>
$(($kv.Value -join "`n"))
    </tbody>
  </table>
"@)
}

$okCount = @($tools | Where-Object { [string]$_.status -eq 'ok' }).Count
$deadCount = @($tools | Where-Object { [string]$_.status -eq 'dead' }).Count
$today = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')

$html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AI Agent 工坊 · 中文资源导航</title>
<style>
  body { font-family: -apple-system, "Segoe UI", "PingFang SC", "Microsoft YaHei", sans-serif; max-width: 1100px; margin: 2rem auto; padding: 0 1rem; color: #1a1a1a; line-height: 1.6; }
  h1 { text-align: center; }
  .sub { text-align: center; color: #666; margin-bottom: 1.5rem; }
  .summary { display: flex; gap: 1rem; justify-content: center; margin-bottom: 2rem; flex-wrap: wrap; }
  .summary div { background: #f5f5f7; border-radius: 8px; padding: .6rem 1.2rem; }
  h2 { border-bottom: 2px solid #0078d4; padding-bottom: .3rem; margin-top: 2rem; }
  .count { color: #0078d4; font-size: .8em; }
  table { width: 100%; border-collapse: collapse; font-size: .9rem; }
  th, td { text-align: left; padding: .5rem .6rem; border-bottom: 1px solid #eee; vertical-align: top; }
  th { background: #fafafa; }
  code { background: #f0f0f0; padding: .1rem .4rem; border-radius: 4px; font-size: .85em; }
  a { color: #0078d4; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .ok { color: #1a7f37; } .dead { color: #cf222e; } .unk { color: #9a6700; }
  .cn { font-size: .8em; padding: .1rem .4rem; border-radius: 4px; }
  .cn.direct { background: #dafbe1; } .cn.proxy { background: #fff8c5; }
</style>
</head>
<body>
  <h1>🤖 AI Agent 工坊 · 中文资源导航</h1>
  <p class="sub">编码代理 / 破甲 Harness / Skills 库 / 免费额度网关 / 代理中转 — 每周自动体检</p>
  <div class="summary">
    <div>条目 <b>$($tools.Count)</b></div>
    <div>存活 <b>$okCount</b></div>
    <div>失效 <b>$deadCount</b></div>
    <div>更新 <b>$today</b></div>
  </div>
$(($sections -join "`n"))
  <footer style="margin-top:3rem; text-align:center; color:#999; font-size:.85rem;">
    本页由 scripts/render.ps1 从 data/tools.json 生成 · 仅供学习研究
  </footer>
</body>
</html>
"@

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutPath) | Out-Null
[System.IO.File]::WriteAllText($OutPath, $html, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("已生成：$OutPath （$($tools.Count) 条）")
